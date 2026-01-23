-- Get the number of shifts assigned to each driver for each route
select
    d.id,
    d.name,
    s.route_number,
    count(*) as shifts_count
from driver d
join shift s on s.driver_id = d.id
group by d.id, d.name, s.route_number
order by d.id, s.route_number;
