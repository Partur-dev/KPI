SELECT 
    s.id,
    a.street,
    si.value AS water_amount
FROM shelter s
JOIN address a ON s.address_id = a.id
JOIN shelter_inventory si ON s.id = si.shelter_id
WHERE si.item_id = (SELECT id FROM inventory_item WHERE name = 'Вода питна (пляшки)')
    AND si.value < (
        SELECT AVG(value) 
        FROM shelter_inventory 
        WHERE item_id = (SELECT id FROM inventory_item WHERE name = 'Вода питна (пляшки)')
    );
