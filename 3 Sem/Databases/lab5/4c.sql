-- Ensure no overlapping shifts for the same driver on the same day

CREATE FUNCTION trg_shift_before_insert() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  overlap_count int;
BEGIN
  SELECT count(*) INTO overlap_count
  FROM shift
  WHERE driver_id = NEW.driver_id
    AND work_date = NEW.work_date
    AND (NEW.start_time < end_time AND NEW.end_time > start_time);

  IF overlap_count > 0 THEN
    RAISE EXCEPTION 'Driver % has overlapping shift on %', NEW.driver_id, NEW.work_date;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER shift_before_insert
BEFORE INSERT ON shift
FOR EACH ROW
EXECUTE FUNCTION trg_shift_before_insert();
