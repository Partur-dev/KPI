-- Get a list of stops for each route, ordered by stop order
select
    r.number as route_number,
    string_agg(s.name, ', ' order by rs.stop_order) as stops_list
from route r
join route_stop rs on rs.route_number = r.number
join stop s on s.id = rs.stop_id
group by r.number;
