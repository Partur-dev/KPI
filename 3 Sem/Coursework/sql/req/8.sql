SELECT 
    i.date,
    insp.name AS inspector_name,
    a.street || ' ' || a.building AS shelter_address,
    i.status,
    i.notes
FROM inspection i
JOIN inspector insp ON i.inspector_id = insp.id
JOIN shelter s ON i.shelter_id = s.id
JOIN address a ON s.address_id = a.id
ORDER BY i.date DESC;
