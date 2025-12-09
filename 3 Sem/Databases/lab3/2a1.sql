SELECT 
    name, 
    (SELECT COUNT(*) FROM trolleybus WHERE brand_name = brand.name) AS total_trolleys
FROM brand;
