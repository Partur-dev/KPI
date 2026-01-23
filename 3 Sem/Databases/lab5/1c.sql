-- Set the duration of a route and get the number of affected rows (should be 0 or 1)

CREATE FUNCTION fn_set_route_duration(p_route varchar, p_minutes int) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  updated_count int;
BEGIN
  IF p_minutes <= 0 THEN
    RAISE EXCEPTION 'duration_minutes must be > 0';
  END IF;

  UPDATE route SET duration_minutes = p_minutes WHERE number = p_route;
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$;
