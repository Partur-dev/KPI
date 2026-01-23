drop view if exists v_shift_info cascade;

create view v_shift_info as
select
    s.id as shift_id,
    s.work_date,
    s.start_time,
    s.end_time,
    d.id as driver_id,
    d.name as driver_name,
    s.trolleybus_number,
    b.name as brand_name,
    s.route_number
from shift s
join driver d on d.id = s.driver_id
join trolleybus t on t.number = s.trolleybus_number
join brand b on b.name = t.brand_name;
