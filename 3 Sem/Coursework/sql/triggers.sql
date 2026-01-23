---------------------------------------------------------------------------------
-- 6. Автоматичне оновлення статусу укриття після інспекції
-- Логіка: Результат перевірки безпосередньо впливає на доступність укриття.
-- Passed -> Ready, Failed -> Not Ready, Needs Improvement -> Limited Ready
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_shelter_status_on_inspection() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Passed' THEN
        UPDATE shelter SET status = 'Ready' WHERE id = NEW.shelter_id;
    ELSIF NEW.status = 'Failed' THEN
        UPDATE shelter SET status = 'Not Ready' WHERE id = NEW.shelter_id;
    ELSIF NEW.status = 'Needs Improvement' THEN
        UPDATE shelter SET status = 'Limited Ready' WHERE id = NEW.shelter_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_shelter_status
AFTER INSERT ON inspection
FOR EACH ROW EXECUTE FUNCTION update_shelter_status_on_inspection();

---------------------------------------------------------------------------------
-- 7. Блокування редагування критичних даних, якщо укриття "Готове"
-- Логіка: Якщо укриття має статус 'Ready', не можна змінювати його місткість 
-- або тип без попереднього переведення в статус 'Not Ready' (захист від помилок).
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION lock_ready_shelter_updates() 
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'Ready' AND NEW.status = 'Ready' THEN
        IF NEW.capacity != OLD.capacity OR NEW.type != OLD.type OR NEW.address_id != OLD.address_id THEN
            RAISE EXCEPTION 'Редагування характеристик заборонено для укриттів зі статусом Ready. Спочатку змініть статус.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_lock_ready_shelter
BEFORE UPDATE ON shelter
FOR EACH ROW EXECUTE FUNCTION lock_ready_shelter_updates();

---------------------------------------------------------------------------------
-- 8. Валідація послідовності зупинок маршруту
-- Логіка: 
-- 1. Не можна додати 'Start', якщо він вже є.
-- 2. Не можна додати 'Finish', якщо він вже є.
-- 3. Не можна додати будь-яку точку, якщо для цього маршруту вже існує 'Finish'.
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_route_stops_logic() 
RETURNS TRIGGER AS $$
DECLARE
    v_finish_exists BOOLEAN;
BEGIN
    IF NEW.kind = 'Start' AND EXISTS(SELECT 1 FROM route_stop WHERE route_id = NEW.route_id AND kind = 'Start') THEN
        RAISE EXCEPTION 'Маршрут вже має точку початку (Start)';
    END IF;

    IF NEW.kind = 'Finish' AND EXISTS(SELECT 1 FROM route_stop WHERE route_id = NEW.route_id AND kind = 'Finish') THEN
        RAISE EXCEPTION 'Маршрут вже має точку кінця (Finish)';
    END IF;

    SELECT EXISTS(SELECT 1 FROM route_stop WHERE route_id = NEW.route_id AND kind = 'Finish') 
    INTO v_finish_exists;

    IF v_finish_exists AND NEW.kind != 'Finish' THEN
         IF NEW.stop_order > (SELECT stop_order FROM route_stop WHERE route_id = NEW.route_id AND kind = 'Finish') THEN
            RAISE EXCEPTION 'Не можна додавати зупинки після точки Finish';
         END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_stops
BEFORE INSERT ON route_stop
FOR EACH ROW EXECUTE FUNCTION validate_route_stops_logic();

---------------------------------------------------------------------------------
-- 9. Один головний вхід (Auto-demote)
-- Логіка: Якщо вхід позначається як головний (is_main = true), 
-- всі інші входи цього укриття автоматично стають не головними.
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ensure_single_main_entrance() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_main = TRUE THEN
        UPDATE shelter_entrance 
        SET is_main = FALSE 
        WHERE shelter_id = NEW.shelter_id AND id != NEW.id AND is_main = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_demote_entrances
AFTER INSERT OR UPDATE ON shelter_entrance
FOR EACH ROW EXECUTE FUNCTION ensure_single_main_entrance();

---------------------------------------------------------------------------------
-- 10. Автоматичний апдейт маршрутів при зміні статусу укриття
-- Логіка: 
-- Якщо укриття стає 'Not Ready', всі маршрути до нього деактивуються (is_active = FALSE).
-- Якщо укриття стає 'Ready', маршрути можна активувати (is_active = TRUE).
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_routes_with_shelter_status() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Not Ready' THEN
        UPDATE route SET is_active = FALSE WHERE shelter_id = NEW.id;
        RAISE NOTICE 'Укриття % не готове. Маршрути деактивовано.', NEW.id;
    ELSIF NEW.status = 'Ready' AND OLD.status != 'Ready' THEN
        UPDATE route SET is_active = TRUE WHERE shelter_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_route_active
AFTER UPDATE OF status ON shelter
FOR EACH ROW EXECUTE FUNCTION sync_routes_with_shelter_status();