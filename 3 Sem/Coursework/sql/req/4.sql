SELECT 
    s.id,
    a.street,
    s.capacity,
    t.name AS threat_name
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN shelter_threat st ON s.id = st.shelter_id
JOIN threat t ON st.threat_id = t.id
WHERE t.name = 'Радіаційне забруднення' 
    AND s.status = 'Ready';
