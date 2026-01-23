-- Get trolleybuses that have more than 2 shifts assigned,
-- along with their brand names
select
    t.number,
    b.name as brand_name,
    count(s.id) as shift_count
from trolleybus t
join brand b on b.name = t.brand_name
join shift s on s.trolleybus_number = t.number
group by t.number, b.name
having count(s.id) > 2;
