SELECT round(avg(duration_minutes)) as avg_long_route_duration
FROM (
    SELECT * FROM route 
    WHERE duration_minutes > 60
) AS long_routes;
