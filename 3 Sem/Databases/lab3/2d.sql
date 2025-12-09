SELECT 
    t.number,
    b.name,
    b.seats 
FROM trolleybus t, brand b 
WHERE t.brand_name = b.name 
  AND b.seats > 40;
