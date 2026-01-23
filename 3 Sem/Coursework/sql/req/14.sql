SELECT 
    s.id,
    a.street,
    s.capacity,
    d.name AS district
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN district d ON a.district_id = d.id
WHERE s.capacity > (
    SELECT AVG(capacity) FROM shelter
);
