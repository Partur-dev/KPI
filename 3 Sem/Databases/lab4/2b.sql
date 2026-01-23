drop view if exists v_shift_route_info;

create view v_shift_route_info as
select
    v.shift_id,
    v.work_date,
    v.start_time,
    v.end_time,
    v.driver_id,
    v.driver_name,
    v.trolleybus_number,
    v.brand_name,
    v.route_number,
    r.duration_minutes,
    sp_start.name as start_stop,
    sp_end.name as end_stop
from v_shift_info v
join route r on r.number = v.route_number
join stop sp_start on sp_start.id = r.start_point_id
join stop sp_end on sp_end.id = r.end_point_id;
