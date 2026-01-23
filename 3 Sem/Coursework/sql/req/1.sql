SELECT 
    s.id AS shelter_id,
    c.name AS city,
    d.name AS district,
    a.street,
    a.building,
    s.type,
    s.status
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN district d ON a.district_id = d.id
JOIN city c ON d.city_id = c.id
ORDER BY c.name, d.name;
