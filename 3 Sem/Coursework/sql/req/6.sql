SELECT 
    s.id,
    a.street,
    ii.name AS item,
    si.value AS quantity,
    ii.unit
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN shelter_inventory si ON s.id = si.shelter_id
JOIN inventory_item ii ON si.item_id = ii.id
WHERE ii.name LIKE '%Вода%' 
    AND si.value < 1000;
