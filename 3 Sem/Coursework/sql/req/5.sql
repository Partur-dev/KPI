SELECT 
    s.id,
    a.street,
    sf.value AS generator_power
FROM shelter s
JOIN shelter_feature sf ON s.id = sf.shelter_id
JOIN feature f ON sf.feature_id = f.id
JOIN address a ON s.address_id = a.id
JOIN district d ON a.district_id = d.id
WHERE f.name = 'Генератор' 
    AND d.name = 'Шевченківський';
