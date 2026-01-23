-- Check if the total number of seats in all 'Bogdan' brand trolleybuses exceeds 100
-- If it does, return the total number of seats
-- If not, return an empty result set
select
    sum(b.seats) as total_seat
from trolleybus t
join brand b on t.brand_name = b.name
where b.name = 'Bogdan'
having sum(b.seats) > 50;
