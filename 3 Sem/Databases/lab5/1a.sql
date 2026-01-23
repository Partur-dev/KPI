-- List all stops for a given route

CREATE PROCEDURE proc_route_list_stops(p_route varchar)
LANGUAGE plpgsql
AS $$
DECLARE
  stops_count int;
  idx int := 1;
  stop_ids int[];
BEGIN
  SELECT count(*) INTO stops_count FROM route_stop WHERE route_number = p_route;
  IF stops_count = 0 THEN
    RAISE NOTICE 'Route % has no stops', p_route;
    RETURN;
  END IF;

  SELECT array_agg(stop_id ORDER BY stop_order) INTO stop_ids
    FROM route_stop WHERE route_number = p_route;

  WHILE idx <= array_length(stop_ids, 1) LOOP
    RAISE NOTICE 'stop % -> id=%', idx, stop_ids[idx];
    idx := idx + 1;
  END LOOP;
END;
$$;
