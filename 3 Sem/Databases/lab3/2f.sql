SELECT 
    t.number, 
    i.inspection_date, 
    i.results
FROM trolleybus t
LEFT JOIN inspection i ON t.number = i.trolleybus_number
WHERE i.results IS NOT NULL;
