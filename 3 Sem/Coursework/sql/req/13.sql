SELECT 
    r.id AS route_id,
    a.street,
    a.building
FROM route r
JOIN route_stop rs ON r.id = rs.route_id
JOIN address a ON rs.address_id = a.id
WHERE r.is_active = TRUE 
    AND rs.kind = 'Start';
