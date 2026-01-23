---------------------------------------------------------------------------------
-- 1. Знаходження найближчого укриття за координатами
-- Вхід: широта, довгота.
-- Вихід: таблиця з одним рядком (id, адреса, дистанція в метрах)
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION find_nearest_shelter(p_lon DECIMAL, p_lat DECIMAL)
RETURNS TABLE (
    shelter_id INT, 
    full_address TEXT, 
    distance_meters INT
) LANGUAGE plpgsql AS $$
DECLARE
    user_point GEOMETRY;
BEGIN
    user_point := ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326);

    RETURN QUERY
    SELECT 
        s.id,
        (d.name || ', ' || a.street || ', ' || a.building)::TEXT,
        ST_DistanceSphere(a.location, user_point)::INT
    FROM shelter s
    JOIN address a ON s.address_id = a.id
    JOIN district d ON a.district_id = d.id
    WHERE s.status = 'Ready'
    ORDER BY a.location <-> user_point
    LIMIT 1;
END;
$$;

---------------------------------------------------------------------------------
-- 2. Укриття в радіусі N метрів
-- Вхід: широта, довгота, радіус (метри)
-- Вихід: список укриттів
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_shelters_in_radius(p_lon DECIMAL, p_lat DECIMAL, p_radius_meters FLOAT)
RETURNS TABLE (
    shelter_id INT,
    type VARCHAR,
    capacity INT,
    distance_meters INT
) LANGUAGE plpgsql AS $$
DECLARE
    user_point GEOMETRY;
BEGIN
    user_point := ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326);

    RETURN QUERY
    SELECT 
        s.id,
        s.type,
        s.capacity,
        ST_DistanceSphere(a.location, user_point)::INT AS dist
    FROM shelter s
    JOIN address a ON s.address_id = a.id
    -- ST_DWithin працює з градусами для geometry, тому кастимо в geography для метрів
    WHERE ST_DWithin(a.location::geography, user_point::geography, p_radius_meters)
      AND s.status != 'Not Ready'
    ORDER BY dist ASC;
END;
$$;

---------------------------------------------------------------------------------
-- 9. Отримати повну адресу укриття (Допоміжна функція, потрібна для п.3)
-- Вхід: ID укриття
-- Вихід: Рядок з повною адресою та координатами
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_shelter_full_address(p_shelter_id INT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    res TEXT;
BEGIN
    SELECT 
        c.name || ', ' || d.name || ', ' || a.street || ', ' || a.building || 
        ' (' || ST_Y(a.location)::NUMERIC(9,6) || ', ' || ST_X(a.location)::NUMERIC(9,6) || ')'
    INTO res
    FROM shelter s
    JOIN address a ON s.address_id = a.id
    JOIN district d ON a.district_id = d.id
    JOIN city c ON d.city_id = c.id
    WHERE s.id = p_shelter_id;
    
    RETURN res;
END;
$$;

---------------------------------------------------------------------------------
-- 3. Всі маршрути до укриття
-- Вхід: ID укриття
-- Вихід: ID маршруту, рядок зупинок, довжина
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_routes_to_shelter(p_shelter_id INT)
RETURNS TABLE (
    route_id INT,
    stops_list TEXT,
    total_distance FLOAT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        STRING_AGG(a.street || ' ' || a.building, ' -> ' ORDER BY rs.stop_order),
        r.distance::FLOAT
    FROM route r
    JOIN route_stop rs ON r.id = rs.route_id
    JOIN address a ON rs.address_id = a.id
    WHERE r.shelter_id = p_shelter_id AND r.is_active = TRUE
    GROUP BY r.id;
END;
$$;

---------------------------------------------------------------------------------
-- 4. Перерахунок дистанції маршруту
-- Вхід: ID маршруту
-- Дія: Оновлює поле distance в таблиці route
---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE recalculate_route_distance(p_route_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_total_dist DECIMAL(10,2);
BEGIN
    WITH segments AS (
        SELECT 
            ST_DistanceSphere(
                a.location, 
                LEAD(a.location) OVER (ORDER BY rs.stop_order)
            ) AS segment_dist
        FROM route_stop rs
        JOIN address a ON rs.address_id = a.id
        WHERE rs.route_id = p_route_id
    )
    SELECT SUM(segment_dist) INTO v_total_dist FROM segments;

    UPDATE route 
    SET distance = COALESCE(v_total_dist, 0)
    WHERE id = p_route_id;
END;
$$;

---------------------------------------------------------------------------------
-- 5. Перевірка валідності маршруту
-- Вхід: ID маршруту
-- Вихід: Таблиця (is_valid boolean, reason text)
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_route(p_route_id INT)
RETURNS TABLE (
    is_valid BOOLEAN,
    reason TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_has_start BOOLEAN;
    v_finish_count INT;
    v_last_kind VARCHAR;
BEGIN
    SELECT EXISTS(SELECT 1 FROM route_stop WHERE route_id = p_route_id AND kind = 'Start') 
    INTO v_has_start;
    
    IF NOT v_has_start THEN 
        is_valid := FALSE;
        reason := 'Відсутня точка Start';
        RETURN NEXT;
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_finish_count 
    FROM route_stop 
    WHERE route_id = p_route_id AND kind = 'Finish';
    
    IF v_finish_count = 0 THEN 
        is_valid := FALSE;
        reason := 'Відсутня точка Finish';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_finish_count > 1 THEN 
        is_valid := FALSE;
        reason := 'Більше однієї точки Finish';
        RETURN NEXT;
        RETURN;
    END IF;

    SELECT kind INTO v_last_kind 
    FROM route_stop 
    WHERE route_id = p_route_id 
    ORDER BY stop_order DESC 
    LIMIT 1;
    
    IF v_last_kind != 'Finish' THEN
        is_valid := FALSE;
        reason := 'Остання точка не є Finish';
        RETURN NEXT;
        RETURN;
    END IF;

    is_valid := TRUE;
    reason := 'Маршрут валідний';
    RETURN NEXT;
END;
$$;

---------------------------------------------------------------------------------
-- 6. Зручне додавання маршруту “з адрес”
-- Вхід: Масив ID адрес, примітки
-- Дія: Створює маршрут, прив'язує до укриття (за останньою адресою), рахує дистанцію
---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE create_route_from_addresses(
    p_address_ids INT[], 
    p_notes TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_new_route_id INT;
    v_target_shelter_id INT;
    v_addr_id INT;
    v_order INT := 1;
    v_kind VARCHAR;
    v_len INT;
BEGIN
    v_len := array_length(p_address_ids, 1);
    
    IF v_len < 2 THEN
        RAISE EXCEPTION 'Маршрут повинен мати мінімум 2 точки';
    END IF;

    SELECT id INTO v_target_shelter_id 
    FROM shelter 
    WHERE address_id = p_address_ids[v_len] 
    LIMIT 1;

    IF v_target_shelter_id IS NULL THEN
        RAISE EXCEPTION 'За останньою адресою (ID %) не знайдено зареєстрованого укриття', p_address_ids[v_len];
    END IF;

    INSERT INTO route (shelter_id, is_active, notes, distance) 
    VALUES (v_target_shelter_id, TRUE, p_notes, 0)
    RETURNING id INTO v_new_route_id;

    FOREACH v_addr_id IN ARRAY p_address_ids
    LOOP
        IF v_order = 1 THEN v_kind := 'Start';
        ELSIF v_order = v_len THEN v_kind := 'Finish';
        ELSE v_kind := 'Intermediate';
        END IF;

        INSERT INTO route_stop (route_id, address_id, stop_order, kind)
        VALUES (v_new_route_id, v_addr_id, v_order, v_kind);
        
        v_order := v_order + 1;
    END LOOP;

    CALL recalculate_route_distance(v_new_route_id);
    
    RAISE NOTICE 'Маршрут % створено успішно до укриття %', v_new_route_id, v_target_shelter_id;
END;
$$;

---------------------------------------------------------------------------------
-- 7. Сумарна місткість всіх укриттів у місті
-- Вхід: ID міста
-- Вихід: Число місць (тільки готові або обмежено готові)
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_total_city_capacity(p_city_id INT)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_sum BIGINT;
BEGIN
    SELECT SUM(s.capacity) INTO v_sum
    FROM shelter s
    JOIN address a ON s.address_id = a.id
    JOIN district d ON a.district_id = d.id
    WHERE d.city_id = p_city_id 
      AND s.status IN ('Ready', 'Limited Ready');
    
    RETURN COALESCE(v_sum, 0);
END;
$$;

---------------------------------------------------------------------------------
-- 8. Зведення по укриттю (основна інфа “одним рядком”)
-- Вхід: ID укриття
-- Вихід: Текстовий рядок
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_shelter_summary(p_shelter_id INT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_res TEXT;
    v_last_insp TEXT;
    v_entrances INT;
BEGIN
    SELECT to_char(date, 'YYYY-MM-DD') || ' (' || status || ')' 
    INTO v_last_insp
    FROM inspection 
    WHERE shelter_id = p_shelter_id 
    ORDER BY date DESC LIMIT 1;

    SELECT COUNT(*) INTO v_entrances FROM shelter_entrance WHERE shelter_id = p_shelter_id;

    SELECT format(
        '[%s] %s, %s. Орг: %s. Відп: %s. Тип: %s. Статус: %s. Інспекція: %s. Входів: %s',
        c.name, d.name, a.street || ' ' || a.building,
        o.name, rp.name,
        s.type, s.status,
        COALESCE(v_last_insp, 'Не проводилась'),
        v_entrances
    ) INTO v_res
    FROM shelter s
    JOIN address a ON s.address_id = a.id
    JOIN district d ON a.district_id = d.id
    JOIN city c ON d.city_id = c.id
    JOIN organization o ON s.organization_id = o.id
    JOIN responsible_person rp ON s.responsible_id = rp.id
    WHERE s.id = p_shelter_id;

    RETURN v_res;
END;
$$;

---------------------------------------------------------------------------------
-- 10. Перевірка прострочених предметів в інвентарі укриття
-- Вхід: ID укриття
-- Вихід: Таблиця з простроченими товарами
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_expired_inventory(p_shelter_id INT)
RETURNS TABLE (
    item_name VARCHAR,
    quantity DECIMAL,
    expiration_date DATE,
    days_overdue INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ii.name,
        si.value,
        si.expiration_date,
        (CURRENT_DATE - si.expiration_date)::INT
    FROM shelter_inventory si
    JOIN inventory_item ii ON si.item_id = ii.id
    WHERE si.shelter_id = p_shelter_id 
      AND si.expiration_date < CURRENT_DATE;
END;
$$;
