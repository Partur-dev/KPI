SELECT 
    s.id,
    rp.name AS responsible,
    rp.phone,
    ii.name AS item,
    si.expiration_date
FROM shelter s
JOIN responsible_person rp ON s.responsible_id = rp.id
JOIN shelter_inventory si ON s.id = si.shelter_id
JOIN inventory_item ii ON si.item_id = ii.id
WHERE si.expiration_date < CURRENT_DATE;
