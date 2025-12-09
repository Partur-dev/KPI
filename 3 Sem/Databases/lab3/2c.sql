SELECT 
    d.name AS driver_name, 
    r.number AS route_number 
FROM driver d
CROSS JOIN route r;
