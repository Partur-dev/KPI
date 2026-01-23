BEGIN;

-- 1. Міста та Райони
INSERT INTO city (name, population) VALUES ('Київ', 2950000);

INSERT INTO district (name, city_id) VALUES 
('Шевченківський', 1),
('Печерський', 1),
('Подільський', 1),
('Голосіївський', 1),
('Дарницький', 1);

-- 2. Адреси (з геометрією PostGIS)
-- Функція ST_SetSRID(ST_MakePoint(lon, lat), 4326) створює точку з координатами
INSERT INTO address (district_id, street, building, location) VALUES
(1, 'вул. Хрещатик', '1', ST_SetSRID(ST_MakePoint(30.5234, 50.4501), 4326)),
(1, 'вул. Володимирська', '33', ST_SetSRID(ST_MakePoint(30.5150, 50.4470), 4326)),
(2, 'бул. Лесі Українки', '26', ST_SetSRID(ST_MakePoint(30.5380, 50.4265), 4326)),
(3, 'вул. Сагайдачного', '10', ST_SetSRID(ST_MakePoint(30.5250, 50.4610), 4326)),
(4, 'просп. Голосіївський', '42', ST_SetSRID(ST_MakePoint(30.5130, 50.3980), 4326)),
(5, 'вул. Харківське шосе', '121', ST_SetSRID(ST_MakePoint(30.6650, 50.4150), 4326));

-- Генеруємо ще 15 випадкових адрес для масовки
INSERT INTO address (district_id, street, building, location)
SELECT 
    (random() * 4 + 1)::INT, 
    'вул. Тестова ' || i, 
    (random() * 100 + 1)::INT::TEXT,
    ST_SetSRID(ST_MakePoint(30.5 + (random() * 0.2), 50.4 + (random() * 0.1)), 4326)
FROM generate_series(1, 15) AS i;

-- 3. Організації
INSERT INTO organization (name, type, contacts) VALUES
('КП "Київжитлоспецексплуатація"', 'Комунальна', '044-123-45-67'),
('ОСББ "Затишок"', 'Приватна', 'osbb_zatyshok@gmail.com'),
('ТОВ "Бізнес-Центр Поділ"', 'Приватна', 'admin@bcpodol.ua'),
('ЗОШ №55', 'Державна', 'school55@kyiv.edu');

-- 4. Відповідальні особи
INSERT INTO responsible_person (name, phone, organization_id, role) VALUES
('Петренко Іван Іванович', '+380501112233', 1, 'Головний інженер'),
('Сидоренко Олена Петрівна', '+380679998877', 2, 'Голова правління'),
('Коваленко Андрій Сергійович', '+380635554433', 3, 'Завгосп'),
('Мельник Тетяна Василівна', '+380971231231', 4, 'Директор школи');

-- 5. Укриття
INSERT INTO shelter (address_id, capacity, status, organization_id, responsible_id, type) VALUES
(1, 300, 'Ready', 1, 1, 'Bomb Shelter'),    -- Хрещатик
(2, 150, 'Limited Ready', 1, 1, 'Simple Shelter'), -- Володимирська
(3, 50, 'Ready', 2, 2, 'Simple Shelter'),   -- ОСББ
(4, 500, 'Ready', 3, 3, 'Dual Use'),        -- БЦ (паркінг)
(5, 200, 'Not Ready', 1, 1, 'Radiation Shelter'), -- Голосіїв
(6, 400, 'Ready', 4, 4, 'Bomb Shelter');    -- Школа

-- Генеруємо ще 5 укриттів
INSERT INTO shelter (address_id, capacity, status, organization_id, responsible_id, type)
SELECT 
    i + 6, -- використовуємо згенеровані адреси
    (random() * 500 + 50)::INT,
    CASE WHEN random() > 0.8 THEN 'Not Ready' ELSE 'Ready' END,
    (random() * 3 + 1)::INT,
    (random() * 3 + 1)::INT,
    'Simple Shelter'
FROM generate_series(1, 5) AS i;

-- 6. Загрози
INSERT INTO threat (name, description, severity) VALUES
('Артилерійський обстріл', 'Загроза ураження уламками та вибуховою хвилею', 8),
('Повітряна атака (ракети)', 'Загроза ракетного удару', 9),
('Радіаційне забруднення', 'Викид радіоактивних речовин', 10),
('Хімічна атака', 'Застосування отруйних речовин', 10);

-- Зв’язок укриттів та загроз
-- Школа (id=6) та Метро/Хрещатик (id=1) захищають від усього
INSERT INTO shelter_threat (shelter_id, threat_id) 
SELECT 1, id FROM threat UNION ALL
SELECT 6, id FROM threat;

-- Прості укриття (id 2, 3) тільки від артобстрілу
INSERT INTO shelter_threat (shelter_id, threat_id) VALUES (2, 1), (3, 1);

-- 7. Особливості (Features)
INSERT INTO feature (name, description) VALUES
('Wi-Fi', 'Доступ до інтернету'),
('Генератор', 'Автономне живлення'),
('Пандус', 'Доступність для маломобільних груп'),
('Запас води', 'Є баки з водою'),
('Вентиляція', 'Примусова система вентиляції');

-- Наповнення особливостями
INSERT INTO shelter_feature (shelter_id, feature_id, value) VALUES
(1, 1, 'Starlink'), (1, 2, '50 кВт'), (1, 5, 'HEPA'),
(3, 1, 'ОСББ-нет'),
(4, 2, 'Дизель'), (4, 3, NULL),
(6, 1, NULL), (6, 2, NULL), (6, 4, '1000 л');

-- 8. Інвентар
INSERT INTO inventory_item (name, unit, category) VALUES
('Вода питна (пляшки)', 'л', 'Продукти'),
('Сухпай', 'шт', 'Продукти'),
('Бензин А-95', 'л', 'Паливо'),
('Вогнегасник', 'шт', 'Безпека'),
('Ковдра', 'шт', 'Комфорт');

INSERT INTO shelter_inventory (shelter_id, item_id, value, expiration_date) VALUES
(1, 1, 500, '2026-01-01'), (1, 3, 200, '2025-06-01'),
(4, 3, 100, '2025-12-01'),
(6, 1, 1000, '2026-05-01'), (6, 5, 50, NULL);

-- 9. Інспектори та перевірки
INSERT INTO inspector (name, phone) VALUES 
('Дмитренко О.О.', '101'), 
('Ковальчук В.В.', '102');

INSERT INTO inspection (shelter_id, inspector_id, date, status, notes) VALUES
(1, 1, NOW() - INTERVAL '1 month', 'Passed', 'Все добре'),
(2, 2, NOW() - INTERVAL '2 days', 'Needs Improvement', 'Відсутній покажчик входу'),
(5, 1, NOW() - INTERVAL '5 days', 'Failed', 'Затоплено водою'),
(6, 1, NOW(), 'Passed', 'Готово до навчального року');

-- 10. Маршрути
-- Маршрут до укриття на Хрещатику (id 1)
INSERT INTO route (shelter_id, is_active, notes, distance) VALUES
(1, TRUE, 'Центральний маршрут', 500.0);

-- Зупинки маршруту
INSERT INTO route_stop (route_id, address_id, stop_order, kind) VALUES
(1, 2, 1, 'Start'), -- Володимирська
(1, 1, 2, 'Finish'); -- Хрещатик

COMMIT;

BEGIN;

-- =========================================================
-- 0) Ще адреси для Києва (щоб було з чого робити маршрути)
-- =========================================================
INSERT INTO address (district_id, street, building, location)
SELECT
  (floor(random()*5)+1)::int,
  (ARRAY[
    'вул. Велика Васильківська','вул. Антоновича','вул. Саксаганського','вул. Басейна',
    'вул. Прорізна','вул. Грушевського','вул. Липська','просп. Перемоги',
    'вул. Жилянська','вул. Богдана Хмельницького','вул. Мечникова','вул. Шота Руставелі'
  ])[ (floor(random()*12)+1)::int ] || ' (ген)',
  (floor(random()*220)+1)::int::text,
  ST_SetSRID(ST_MakePoint(30.45 + random()*0.35, 50.33 + random()*0.25), 4326)
FROM generate_series(1, 60);

-- =========================================================
-- 1) Ще укриття (щоб маршрути були не тільки на перші 6)
-- =========================================================
INSERT INTO shelter (address_id, capacity, status, organization_id, responsible_id, type)
SELECT
  a.id,
  (floor(random()*700)+50)::int,
  (ARRAY['Ready','Limited Ready','Not Ready'])[ (floor(random()*3)+1)::int ],
  (floor(random()*4)+1)::int,
  (floor(random()*4)+1)::int,
  (ARRAY['Bomb Shelter','Radiation Shelter','Dual Use','Simple Shelter'])[ (floor(random()*4)+1)::int ]
FROM address a
WHERE a.id NOT IN (SELECT address_id FROM shelter)
ORDER BY random()
LIMIT 10;

-- =========================================================
-- 2) Додаткові інспектори + ще перевірки (масовка)
-- =========================================================
INSERT INTO inspector (name, phone) VALUES
('Інспектор Нічний', '103'),
('Інспектор Денний', '104'),
('Інспектор Резерв', '105');

DO $$
DECLARE
  s RECORD;
  i INT;
  st TEXT;
  insp INT;
  days_back INT;
BEGIN
  FOR s IN SELECT id FROM shelter LOOP
    -- 2..5 інспекцій на укриття
    FOR i IN 1..(2 + floor(random()*4))::int LOOP
      st := (ARRAY['Passed','Failed','Needs Improvement'])[ (floor(random()*3)+1)::int ];
      insp := (SELECT id FROM inspector ORDER BY random() LIMIT 1);
      days_back := (floor(random()*120))::int;

      INSERT INTO inspection (shelter_id, inspector_id, date, status, notes)
      VALUES (
        s.id,
        insp,
        NOW() - (days_back || ' days')::interval,
        st,
        'Тестова інспекція #' || i || ', авто-ген'
      );
    END LOOP;
  END LOOP;
END $$;

-- =========================================================
-- 3) Входи укриттів (по 2-3 входи, один main)
-- =========================================================
DO $$
DECLARE
  s RECORD;
  sa RECORD;
  e_cnt INT;
  i INT;
  e_addr INT;
BEGIN
  FOR s IN SELECT id, address_id FROM shelter LOOP
    SELECT district_id INTO sa FROM address WHERE id = s.address_id;

    e_cnt := 2 + floor(random()*2); -- 2..3 входи

    -- перший вхід: головний, беремо адресу з того ж району (або будь-яку)
    SELECT a.id INTO e_addr
    FROM address a
    WHERE a.id <> s.address_id AND a.district_id = sa.district_id
    ORDER BY random()
    LIMIT 1;

    IF e_addr IS NULL THEN
      SELECT a.id INTO e_addr FROM address a WHERE a.id <> s.address_id ORDER BY random() LIMIT 1;
    END IF;

    INSERT INTO shelter_entrance (shelter_id, address_id, is_main, note)
    VALUES (s.id, e_addr, TRUE, 'Головний вхід (ген)');

    -- інші входи
    FOR i IN 2..e_cnt LOOP
      SELECT a.id INTO e_addr
      FROM address a
      WHERE a.id <> s.address_id
      ORDER BY random()
      LIMIT 1;

      INSERT INTO shelter_entrance (shelter_id, address_id, is_main, note)
      VALUES (s.id, e_addr, FALSE, 'Додатковий вхід #'||i||' (ген)');
    END LOOP;
  END LOOP;
END $$;

-- =========================================================
-- 4) Кілька “ручних” маршрутів (щоб були красиві приклади)
--    (працює з твоїми базовими address_id 1..6 та shelter_id 1..6)
-- =========================================================

-- До укриття #4 (Поділ/БЦ): 2 ручні маршрути
WITH r AS (
  INSERT INTO route (shelter_id, is_active, notes, distance)
  VALUES (4, TRUE, 'Поділ → БЦ (через центр)', NULL)
  RETURNING id
)
INSERT INTO route_stop (route_id, address_id, stop_order, kind)
SELECT r.id, v.address_id, v.stop_order, v.kind
FROM r
JOIN (VALUES
  (4, 1, 'Start'),        -- Сагайдачного
  (1, 2, 'Intermediate'), -- Хрещатик
  (2, 3, 'Finish')        -- Володимирська (як фінал-проксі) -> але краще фінал = адреса укриття, див. нижче
) AS v(address_id, stop_order, kind) ON true;

-- (правильний фінал = адреса укриття #4, вона сидить у shelter.address_id)
-- тому зробимо нормальний маршрут до укриття #4 так:
WITH r AS (
  INSERT INTO route (shelter_id, is_active, notes, distance)
  VALUES (4, TRUE, 'Поділ → укриття #4 (правильний фініш)', NULL)
  RETURNING id
), fin AS (
  SELECT address_id AS fin_addr FROM shelter WHERE id = 4
)
INSERT INTO route_stop (route_id, address_id, stop_order, kind)
SELECT r.id, x.address_id, x.stop_order, x.kind
FROM r, fin
JOIN (VALUES
  (4, 1, 'Start'),
  (1, 2, 'Intermediate')
) AS x(address_id, stop_order, kind) ON true
UNION ALL
SELECT r.id, fin.fin_addr, 3, 'Finish' FROM r, fin;

-- До укриття #6 (Школа): маршрут із 4 точками
WITH r AS (
  INSERT INTO route (shelter_id, is_active, notes, distance)
  VALUES (6, TRUE, 'До школи: короткий пішохідний', NULL)
  RETURNING id
), fin AS (
  SELECT address_id AS fin_addr FROM shelter WHERE id = 6
)
INSERT INTO route_stop (route_id, address_id, stop_order, kind)
SELECT r.id, x.address_id, x.stop_order, x.kind
FROM r, fin
JOIN (VALUES
  (5, 1, 'Start'),        -- Голосіївський просп.
  (2, 2, 'Intermediate'), -- Володимирська
  (1, 3, 'Intermediate')  -- Хрещатик
) AS x(address_id, stop_order, kind) ON true
UNION ALL
SELECT r.id, fin.fin_addr, 4, 'Finish' FROM r, fin;

-- =========================================================
-- 5) МАСОВА генерація маршрутів + зупинок (ОСНОВНЕ)
--    3..5 маршрутів на кожне укриття, 2..8 зупинок на маршрут
-- =========================================================
DO $$
DECLARE
  s RECORD;
  sa RECORD;
  r_id INT;
  n_routes INT;
  n_stops INT;
  i INT;
  j INT;
  start_addr INT;
  mid_addr INT;
  fin_addr INT;
  label TEXT;
  labels TEXT[] := ARRAY[
    'Пішки (короткий)','Пішки (альтернативний)','Обхід через двори',
    'Найбезпечніший (умовно)','Швидкий (умовно)','Через головні вулиці',
    'Тихий маршрут','Маршрут без підйомів (умовно)','Резервний'
  ];
BEGIN
  FOR s IN SELECT id, address_id FROM shelter LOOP
    SELECT district_id INTO sa FROM address WHERE id = s.address_id;
    fin_addr := s.address_id;

    n_routes := 3 + floor(random()*3); -- 3..5

    FOR i IN 1..n_routes LOOP
      label := labels[(floor(random()*array_length(labels,1))+1)::int];

      INSERT INTO route (shelter_id, is_active, notes, distance)
      VALUES (s.id, (random() > 0.25), label || ' → укриття #'||s.id, NULL)
      RETURNING id INTO r_id;

      n_stops := 2 + floor(random()*7); -- 2..8

      -- старт бажано з того ж району (якщо нема — будь-яка)
      SELECT a.id INTO start_addr
      FROM address a
      WHERE a.id <> fin_addr AND a.district_id = sa.district_id
      ORDER BY random()
      LIMIT 1;

      IF start_addr IS NULL THEN
        SELECT a.id INTO start_addr FROM address a WHERE a.id <> fin_addr ORDER BY random() LIMIT 1;
      END IF;

      INSERT INTO route_stop (route_id, address_id, stop_order, kind)
      VALUES (r_id, start_addr, 1, 'Start');

      IF n_stops > 2 THEN
        FOR j IN 2..(n_stops-1) LOOP
          SELECT a.id INTO mid_addr
          FROM address a
          WHERE a.id NOT IN (start_addr, fin_addr)
          ORDER BY random()
          LIMIT 1;

          INSERT INTO route_stop (route_id, address_id, stop_order, kind)
          VALUES (r_id, mid_addr, j, 'Intermediate');
        END LOOP;
      END IF;

      INSERT INTO route_stop (route_id, address_id, stop_order, kind)
      VALUES (r_id, fin_addr, n_stops, 'Finish');
    END LOOP;
  END LOOP;
END $$;

-- =========================================================
-- 6) Перерахунок distance для ВСІХ маршрутів (в метрах)
-- =========================================================
UPDATE route r
SET distance = d.total_m
FROM (
  SELECT
    rs.route_id,
    ROUND(SUM(ST_DistanceSphere(a_prev.location, a_cur.location))::numeric, 2) AS total_m
  FROM (
    SELECT
      route_id,
      stop_order,
      address_id,
      LAG(address_id) OVER (PARTITION BY route_id ORDER BY stop_order) AS prev_address_id
    FROM route_stop
  ) rs
  JOIN address a_cur  ON a_cur.id = rs.address_id
  JOIN address a_prev ON a_prev.id = rs.prev_address_id
  WHERE rs.prev_address_id IS NOT NULL
  GROUP BY rs.route_id
) d
WHERE r.id = d.route_id;

COMMIT;
