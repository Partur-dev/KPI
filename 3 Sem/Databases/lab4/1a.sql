-- Get the number of shifts assigned to each driver
select
    d.id,
    d.name,
    count(s.id) as shift_count
from driver d
left join shift s on s.driver_id = d.id
group by d.id;
