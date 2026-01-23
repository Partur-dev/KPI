SELECT 
    rs.route_id,
    rs.stop_order,
    rs.kind,
    a.street,
    a.building
FROM route_stop rs
JOIN route r ON rs.route_id = r.id
JOIN address a ON rs.address_id = a.id
WHERE r.id = 4
ORDER BY rs.stop_order;