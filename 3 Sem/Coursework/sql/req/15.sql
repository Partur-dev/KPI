SELECT 
    o.name, 
    o.contacts
FROM organization o
WHERE o.id NOT IN (
    SELECT DISTINCT s.organization_id 
    FROM shelter s 
    WHERE s.status = 'Not Ready'
);
