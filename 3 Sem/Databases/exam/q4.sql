\c exam;

select
    c.id, c.name, c.surname, c.phone, c.email,
    count(r.id) as total_requests,
    sum(calculate_request_price(r.id)) as total_price,
    (sum(calculate_request_price(r.id)) - sum(calculate_request_client_price(r.id))) as compensation
from client c
join device d on d.client_id = c.id
join request r on r.device_id = d.id
where r.start_time >= date_trunc('year', current_date) - interval '1 year'
group by c.id
having count(r.id) >= 3
    and sum(case when r.is_warranty then 0 else 1 end) = 0;