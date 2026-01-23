SELECT 
    s.id,
    a.street
FROM shelter s
JOIN address a ON s.address_id = a.id
WHERE NOT EXISTS (
    SELECT f.id FROM feature f
    EXCEPT
    SELECT sf.feature_id FROM shelter_feature sf WHERE sf.shelter_id = s.id
);
