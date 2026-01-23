-- Log inspection deletions

CREATE FUNCTION trg_inspection_delete() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO inspection_audit (
    inspection_id, trolleybus_number, inspection_date, inspector, results, action
  ) VALUES (OLD.id, OLD.trolleybus_number, OLD.inspection_date, OLD.inspector, OLD.results, 'DELETE');
  RETURN OLD;
END;
$$;

CREATE TRIGGER inspection_after_delete
AFTER DELETE ON inspection
FOR EACH ROW
EXECUTE FUNCTION trg_inspection_delete();
