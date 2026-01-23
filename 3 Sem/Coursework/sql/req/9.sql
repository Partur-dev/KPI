SELECT DISTINCT 
    insp.name, 
    insp.phone
FROM inspector insp
JOIN inspection i ON insp.id = i.inspector_id
JOIN shelter s ON i.shelter_id = s.id
JOIN organization o ON s.organization_id = o.id
WHERE i.status = 'Failed' 
    AND o.type = 'Комунальна';
