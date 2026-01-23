SELECT 
    s.id AS shelter_id,
    a.street || ' ' || a.building AS address,
    o.name AS organization,
    rp.name AS responsible_name,
    rp.phone AS responsible_phone,
    rp.role
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN organization o ON s.organization_id = o.id
JOIN responsible_person rp ON s.responsible_id = rp.id;
