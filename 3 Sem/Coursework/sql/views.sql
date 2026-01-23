CREATE OR REPLACE VIEW v_public_shelters AS
SELECT 
    s.id AS shelter_id,
    d.name AS district,
    a.street || ' ' || a.building AS address,
    s.type AS shelter_type,
    s.capacity,
    s.status,
    ST_Y(a.location)::NUMERIC(10,6) AS lat,
    ST_X(a.location)::NUMERIC(10,6) AS lon
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN district d ON a.district_id = d.id
WHERE s.status IN ('Ready', 'Limited Ready');

CREATE OR REPLACE VIEW v_critical_inventory AS
SELECT 
    s.id AS shelter_id,
    a.street || ' ' || a.building AS address,
    rp.name AS responsible_person,
    rp.phone AS contact_phone,
    ii.name AS item_name,
    si.value AS quantity,
    ii.unit,
    si.expiration_date,
    CASE 
        WHEN si.expiration_date < CURRENT_DATE THEN 'Expired'
        ELSE 'Expiring Soon'
    END AS status
FROM shelter_inventory si
JOIN inventory_item ii ON si.item_id = ii.id
JOIN shelter s ON si.shelter_id = s.id
JOIN address a ON s.address_id = a.id
JOIN responsible_person rp ON s.responsible_id = rp.id
WHERE si.expiration_date <= (CURRENT_DATE + INTERVAL '30 days');

CREATE OR REPLACE VIEW v_district_statistics AS
SELECT 
    d.name AS district_name,
    COUNT(s.id) AS total_shelters,
    SUM(CASE WHEN s.status = 'Ready' THEN s.capacity ELSE 0 END) AS effective_capacity,
    ROUND(
        (COUNT(CASE WHEN s.status = 'Ready' THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(s.id), 0) * 100), 2
    ) AS readiness_percentage
FROM district d
LEFT JOIN address a ON d.id = a.district_id
LEFT JOIN shelter s ON a.id = s.address_id
GROUP BY d.id, d.name
ORDER BY effective_capacity ASC;
