SELECT * FROM trolleybus t 
WHERE EXISTS (
    SELECT 1 
    FROM inspection i 
    WHERE i.trolleybus_number = t.number 
      AND i.results IS NOT NULL
);
