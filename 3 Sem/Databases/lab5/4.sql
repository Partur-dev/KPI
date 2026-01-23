CREATE TABLE inspection_audit (
  id serial PRIMARY KEY,
  inspection_id int,
  trolleybus_number varchar(20),
  inspection_date date,
  inspector varchar,
  results text,
  action varchar(10),
  changed_at timestamptz DEFAULT now()
);

CREATE TABLE shift_audit (
  id serial PRIMARY KEY,
  shift_id int,
  driver_id int,
  work_date date,
  start_time time,
  end_time time,
  action varchar(10),
  changed_at timestamptz DEFAULT now()
);
