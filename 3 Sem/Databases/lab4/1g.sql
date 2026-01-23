-- Get all shifts with driver names,
-- ordered by work date desc and driver name asc
select
    s.work_date,
    d.name as driver_name,
    s.start_time,
    s.end_time,
    s.route_number
from shift s
join driver d on d.id = s.driver_id
order by
    s.work_date desc,
    d.name asc;
