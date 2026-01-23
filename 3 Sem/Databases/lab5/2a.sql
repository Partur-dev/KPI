-- Get the date of the last inspection for a given trolleybus

CREATE FUNCTION fn_last_inspection_date(p_trolley varchar) RETURNS date
LANGUAGE sql
AS $$
  SELECT max(inspection_date) FROM inspection WHERE trolleybus_number = p_trolley;
$$;
