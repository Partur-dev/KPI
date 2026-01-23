-- Get the shift rank for each driver based on work date,
-- ordered from most recent to oldest
select
    d.name,
    s.work_date,
    s.route_number,
    row_number() over (
        partition by d.id
        order by s.work_date desc
    ) as shift_rank
from shift s
join driver d on s.driver_id = d.id;