-- Ensure correct shift times and log updates

CREATE FUNCTION trg_shift_before_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.end_time <= NEW.start_time THEN
    RAISE EXCEPTION 'end_time must be > start_time';
  END IF;

  INSERT INTO shift_audit (shift_id, driver_id, work_date, start_time, end_time, action)
  VALUES (OLD.id, OLD.driver_id, OLD.work_date, OLD.start_time, OLD.end_time, 'UPDATE');

  RETURN NEW;
END;
$$;

CREATE TRIGGER shift_before_update
BEFORE UPDATE ON shift
FOR EACH ROW
EXECUTE FUNCTION trg_shift_before_update();
