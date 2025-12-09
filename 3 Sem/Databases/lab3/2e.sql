SELECT 
    s.work_date, 
    d.name AS driver_name, 
    s.route_number
FROM shift s
INNER JOIN driver d ON s.driver_id = d.id;
