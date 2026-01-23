\c exam;

insert into brand (name) values
('brand 1'),
('brand 2'),
('brand 3');

insert into model (name) values
('model 1'),
('model 2'),
('model 3');

insert into client (name, surname, phone, email) values
('someone', 'someone', '+380...', 'smth@gmail.com'),
('someone 2', 'someone 2', '+380...', 'smth@gmail.com');

insert into employee (name, surname, position, phone, email) values
('emp1', 'emp1', 'technician', '+380...', 'smth@gmail.com'),
('emp2', 'emp2', 'technician', '+380...', 'smth@gmail.com');


insert into service_type (name, description, price) values
('fix screen', 'description 1', 100.00),
('replace battery', 'description 2', 200.00);

insert into device (client_id, brand_id, model_id, serial_number) values
(1, 1, 1, 'SN0001'),
(2, 1, 2, 'SN0002');

insert into warranty (device_id, warranty_start_date, warranty_end_date, compensation_limit, terms) values
(1, '2025-01-01', '2027-01-01', 200.0, 'terms 1');

insert into request (device_id, employee_id, description, status, is_warranty, service_type_id, start_time, end_time) values
(1, 1, 'fix screen 1', 'completed', true, 1, '2026-01-01 10:00:00', '2026-01-03 10:00:00'),
(1, 1, 'fix screen 2', 'completed', true, 1, '2026-01-01 10:00:00', '2026-01-03 10:00:00'),
(1, 1, 'fix screen 3', 'completed', true, 1, '2026-01-01 10:00:00', '2026-01-03 10:00:00'),
(2, 1, 'replace battery 1', 'completed', false, 2, '2026-01-02 10:00:00', '2026-01-03 10:00:00');

insert into part (name, description, price, client_price) values
('part 1', 'description part 1', 50.00, 100.00),
('part 2', 'description part 2', 75.00, 150.00);

insert into request_part (request_id, part_id, quantity) values
(1, 1, 2),
(1, 2, 1);
