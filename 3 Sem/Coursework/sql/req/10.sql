SELECT 
    r.id AS route_id,
    a.street || ' ' || a.building AS destination_shelter,
    r.distance,
    r.notes
FROM route r
JOIN shelter s ON r.shelter_id = s.id
JOIN address a ON s.address_id = a.id
WHERE r.is_active = TRUE;
