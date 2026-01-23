-- Retrieve stops for a given route

CREATE FUNCTION fn_route_stops(p_route varchar)
RETURNS TABLE(stop_order int, stop_id int, stop_name varchar)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
    SELECT rs.stop_order, rs.stop_id, s.name
    FROM route_stop rs
    JOIN stop s ON s.id = rs.stop_id
    WHERE rs.route_number = p_route
    ORDER BY rs.stop_order;
END;
$$;
