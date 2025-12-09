SELECT 
    r.number AS route_number, 
    s.name AS start_stop_name
FROM route r
RIGHT JOIN stop s ON r.start_point_id = s.id;
