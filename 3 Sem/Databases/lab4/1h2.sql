-- Get the stop served by the highest number of routes

-- Get all routes that use trolleybuses with > 30 seats
with big_routes as (
    select distinct
        s.route_number
    from shift s
    join trolleybus t
        on t.number = s.trolleybus_number
    join brand b
        on b.name = t.brand_name
    where b.seats > 30
),
-- Count the number of such routes for each stop
stop_route_counts as (
    select
        st.id as stop_id,
        st.name as stop_name,
        count(distinct rs.route_number) as route_count
    from stop st
    join route_stop rs
        on rs.stop_id = st.id
    join big_routes br
        on br.route_number = rs.route_number
    group by st.id, st.name
),
-- Find the maximum route count
max_routes as (
    select max(route_count) as max_route_count
    from stop_route_counts
)

select
    stop_id,
    stop_name,
    route_count
from stop_route_counts src
join max_routes m
    on src.route_count = m.max_route_count;

-- alt solution

select
    st.id as stop_id,
    st.name as stop_name,
    count(distinct rs.route_number) as route_count
from stop st
join route_stop rs on st.id = rs.stop_id
join shift s on rs.route_number = s.route_number
join trolleybus t on s.trolleybus_number = t.number
join brand b on t.brand_name = b.name
where
    b.seats > 30
group by st.id
order by route_count desc
limit 1;
