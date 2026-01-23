SELECT 
    s.id AS shelter_id,
    a.street,
    i.date AS inspection_date,
    i.status
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN inspection i ON s.id = i.shelter_id
WHERE i.date = (
    SELECT MAX(date) 
    FROM inspection i2 
    WHERE i2.shelter_id = s.id
);
