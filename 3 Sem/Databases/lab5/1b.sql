-- Insert missing inspections for trolleybuses for the current date

CREATE PROCEDURE proc_insert_missing_inspections()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO inspection (trolleybus_number, inspection_date, inspector, results)
  SELECT t.number, CURRENT_DATE, 'auto_system', NULL
  FROM trolleybus t
  WHERE NOT EXISTS (
    SELECT 1 FROM inspection i
    WHERE i.trolleybus_number = t.number AND i.inspection_date = CURRENT_DATE
  );
END;
$$;
