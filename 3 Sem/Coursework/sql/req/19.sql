SELECT 
    d.name,
    c.name AS city
FROM district d
JOIN city c ON d.city_id = c.id
WHERE d.id IN (
    SELECT a.district_id
    FROM address a
    JOIN shelter s ON a.id = s.address_id
    WHERE s.status = 'Ready'
    GROUP BY a.district_id
    HAVING COUNT(s.id) < 3
);
