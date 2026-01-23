-- Get the route(s) served by the highest number of different trolleybuses
-- in the last month, where those trolleybuses have passed inspection this year

-- Get distinct trolleybuses per route in the last month with inspections this year
with last_month_shifts as (
    select distinct
        s.route_number,
        s.trolleybus_number
    from shift s
    join inspection i
        on i.trolleybus_number = s.trolleybus_number
    where
        s.work_date >= date_trunc('month', date '2025-12-30' - interval '1 month')
        and s.work_date < date_trunc('month', date '2025-12-30')
        and date_part('year', i.inspection_date) = date_part('year', date '2025-12-30')
),
-- Count distinct trolleybuses per route
route_counts as (
    select
        route_number,
        count(distinct trolleybus_number) as bus_count
    from last_month_shifts
    group by route_number
),
-- -- Find the maximum bus count
max_count as (
    select max(bus_count) as max_bus_count
    from route_counts
)
select
    r.number,
    r.start_time,
    r.end_time,
    rc.bus_count
from route r
join route_counts rc
    on rc.route_number = r.number
join max_count m
    on rc.bus_count = m.max_bus_count;
