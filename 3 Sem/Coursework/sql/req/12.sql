SELECT 
    r.id AS route_id,
    s.type,
    s.capacity,
    a.street AS shelter_street
FROM route r
JOIN shelter s ON r.shelter_id = s.id
JOIN address a ON s.address_id = a.id
WHERE s.type = 'Bomb Shelter' 
    AND s.capacity > 100;