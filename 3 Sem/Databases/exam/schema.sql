drop database if exists exam;
create database exam;
\c exam;

create table brand (
    id serial primary key,
    name varchar(255) not null unique
);

create table model (
    id serial primary key,
    name varchar(255) not null unique
);


create table brand_contact (
    brand_id integer references brand(id) on delete cascade primary key,
    name varchar(255) not null,
    surname varchar(255) not null,
    phone varchar(255) not null,
    email varchar(255) not null
);

create table client (
    id serial primary key,
    name varchar(255) not null,
    surname varchar(255) not null,
    phone varchar(255) not null,
    email varchar(255) not null
);

create table employee (
    id serial primary key,
    name varchar(255) not null,
    surname varchar(255) not null,
    position varchar(255) not null,
    phone varchar(255) not null,
    email varchar(255) not null
);

create table service_type (
    id serial primary key,
    name varchar(255) not null unique,
    description text,
    price numeric(10, 2) not null check (price >= 0)
);

create table device (
    id serial primary key,
    client_id integer references client(id) on delete cascade,
    brand_id integer references brand(id),
    model_id integer references model(id),
    serial_number varchar(255) not null
);

create table request (
    id serial primary key,
    device_id integer references device(id) on delete cascade,
    employee_id integer references employee(id),
    description text not null,
    status varchar(50) not null check (status in ('in_progress', 'completed', 'cancelled')),
    start_time timestamp not null default current_timestamp,
    end_time timestamp default null check (end_time >= start_time),
    is_warranty boolean not null,
    service_type_id integer references service_type(id)
);

create table diagnostics_request (
    id serial primary key,
    device_id integer references device(id) on delete cascade,
    employee_id integer references employee(id),
    description text not null,
    status varchar(50) not null check (status in ('in_progress', 'completed', 'cancelled')),
    start_time timestamp not null default current_timestamp,
    end_time timestamp default null check (end_time >= start_time),
);

create table warranty (
    id serial primary key,
    device_id integer references device(id) on delete cascade,
    warranty_start_date date not null,
    warranty_end_date date not null check (warranty_end_date >= warranty_start_date),
    compensation_limit integer not null check (compensation_limit >= 0),
    terms text not null
);

create table part (
    id serial primary key,
    name varchar(255) not null,
    description text,
    price numeric(10, 2) not null check (price >= 0),
    client_price numeric(10, 2) not null check (client_price >= 0)
);

create table request_part (
    request_id integer references request(id) on delete cascade,
    part_id integer references part(id) on delete cascade,
    quantity integer not null check (quantity >= 0),
    primary key (request_id, part_id)
);

-- triggers

create function trg_ensure_unique_serial_number() returns trigger
language plpgsql as
$$
begin
    perform 1 from device
        where brand_id = new.brand_id
        and serial_number = new.serial_number;

    if found then
        raise exception 'device with such serial number already exists for this brand!';
    end if;
    return new;
end;
$$;

create trigger ensure_unique_serial_number
before insert or update on device
for each row execute function trg_ensure_unique_serial_number();

create function trg_ensure_warranty() returns trigger
language plpgsql as
$$
begin
    if new.is_warranty then
        perform 1 from warranty
            where device_id = new.device_id
            and warranty_start_date <= new.start_time::date
            and warranty_end_date >= new.start_time::date;

        if not found then
            raise exception 'device is not covered with warranty!';
        end if;
    end if;
    return new;
end;
$$;

create trigger ensure_warranty
before insert or update on request
for each row execute function trg_ensure_warranty();

-- functions

create function get_avg_brand_repair_time(brand_name varchar) returns interval
language plpgsql as
$$
begin
    return (
        select avg(end_time - start_time)
        from request r
        join device d on r.device_id = d.id
        join brand b on d.brand_id = b.id
        where b.name = brand_name
        and r.end_time is not null
        and r.start_time >= now() - interval '6 months'
    );
end;
$$;

create function get_avg_employee_repair_time(emp_id integer) returns interval
language plpgsql as
$$
begin
    return (
        select avg(end_time - start_time)
        from request
        where employee_id = emp_id
        and end_time is not null
        and start_time >= now() - interval '6 months'
    );
end;
$$;

create function get_avg_warranty_percentage() returns numeric(5,2)
language plpgsql as
$$
declare
    total_requests integer;
    warranty_requests integer;
begin
    select count(*) into total_requests from request
        where start_time >= now() - interval '6 months';
    select count(*) into warranty_requests from request
        where is_warranty = true
        and start_time >= now() - interval '6 months';
    if total_requests = 0 then
        return 0;
    else
        return round((warranty_requests::numeric / total_requests::numeric) * 100, 2);
    end if;
end;
$$;

create function get_repeat_devices() returns table (
    device_id integer,
    client_name varchar,
    client_surname varchar,
    brand_name varchar,
    model_name varchar,
    repeat_count integer
)
language plpgsql as
$$
begin
    return query
    select
        d.id,
        c.name,
        c.surname,
        b.name,
        m.name,
        count(r.id)::integer as repeat_count
    from device d
    join client c on d.client_id = c.id
    join brand b on d.brand_id = b.id
    join model m on d.model_id = m.id
    join request r on r.device_id = d.id
    where r.start_time >= now() - interval '3 months'
    group by d.id, c.name, c.surname, b.name, m.name
    having count(r.id) > 1;
end;
$$;

create function calculate_request_price(req_id integer) returns numeric(10,2)
language plpgsql as
$$
declare
    service_price numeric(10,2);
    parts_cost numeric(10,2);
begin
    select st.price into service_price
    from request r
    join service_type st on r.service_type_id = st.id
    where r.id = req_id;
    select coalesce(sum(p.client_price * rp.quantity), 0) into parts_cost
    from request_part rp
    join part p on rp.part_id = p.id
    where rp.request_id = req_id;

    return service_price + parts_cost;
end;
$$;

create function calculate_request_client_price(req_id integer) returns numeric(10,2)
language plpgsql as
$$
declare
    service_price numeric(10,2);
    comp_limit numeric(10,2);
    parts_cost numeric(10,2);
    total numeric(10,2);
begin
    select st.price into service_price
    from request r
    join service_type st on r.service_type_id = st.id
    where r.id = req_id;
    select coalesce(sum(p.client_price * rp.quantity), 0) into parts_cost
    from request_part rp
    join part p on rp.part_id = p.id
    where rp.request_id = req_id;

    select compensation_limit into comp_limit
    from warranty w
    join device d on w.device_id = d.id
    join request r on r.device_id = d.id
    where r.id = req_id;

    if comp_limit is null then
        comp_limit := 0;
    end if;

    select service_price + parts_cost - comp_limit into total;

    if total < 0 then
        return 0;
    else
        return total;
    end if;
end;
$$;
