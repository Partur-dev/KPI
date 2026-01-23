SELECT 
    s.id,
    a.street,
    rp.name AS responsible_person
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN responsible_person rp ON s.responsible_id = rp.id
WHERE s.id NOT IN (
    SELECT DISTINCT shelter_id FROM inspection
);
