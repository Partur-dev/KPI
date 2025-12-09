SELECT start_point_id FROM route
INTERSECT
SELECT end_point_id FROM route;
