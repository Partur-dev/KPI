SELECT 
    d.name AS district_name,
    COUNT(s.id) AS total_shelters,
    SUM(s.capacity) AS total_capacity
FROM district d
JOIN address a ON d.id = a.district_id
JOIN shelter s ON a.id = s.address_id
WHERE s.status IN ('Ready', 'Limited Ready')
GROUP BY d.name
ORDER BY total_capacity DESC;
