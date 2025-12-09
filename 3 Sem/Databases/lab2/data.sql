\c trolley_depot;

-- Clear all (just in case)
TRUNCATE inspection, shift, route_stop, route, trolleybus, driver, stop, brand RESTART IDENTITY CASCADE;

-- === brand ===
INSERT INTO brand (name, seats) VALUES
('Bogdan', 35),
('LAZ', 40),
('Skoda', 32),
('Electron', 38),
('Trolza', 30),
('MAZ', 33),
('Yutong', 41),
('Volvo', 39),
('Solaris', 37),
('MAN', 42),
('Iveco', 31),
('Mercedes', 36),
('Isuzu', 34),
('Hyundai', 29),
('BYD', 28),
('VDL', 30);

-- === stop ===
INSERT INTO stop (name, location) VALUES
('Central Station', 'Main St 1'),
('University', 'Campus Rd 5'),
('City Hall', 'Liberty Sq 2'),
('Market', 'Market St 8'),
('Airport', 'Aeroport Ave 3'),
('Depot', 'Industrial Zone'),
('Park', 'Green Rd 10'),
('Hospital', 'Health Blvd 6'),
('Theatre', 'Art St 11'),
('Mall', 'Shopping Ave 12'),
('North Station', 'Railway Rd 15'),
('South Station', 'South Blvd 9'),
('Old Town', 'Heritage Ln 4'),
('Zoo', 'Animal Rd 7'),
('Stadium', 'Sport Ave 2'),
('Harbor', 'Dock St 14');

-- === driver ===
INSERT INTO driver (id, name) VALUES
(1,'Ivan Petrenko'),
(2,'Oleh Shevchenko'),
(3,'Nazar Bondar'),
(4,'Kateryna Melnyk'),
(5,'Dmytro Kravets'),
(6,'Iryna Sydorenko'),
(7,'Serhii Popov'),
(8,'Bohdan Yaremchuk'),
(9,'Olena Kozak'),
(10,'Vasyl Tkachenko'),
(11,'Taras Lytvyn'),
(12,'Andrii Pavlenko'),
(13,'Oleksii Rudenko'),
(14,'Yuliia Hrytsenko'),
(15,'Stepan Savchenko');

-- === trolleybus ===
INSERT INTO trolleybus (number, brand_name) VALUES
('TB-101','Bogdan'),
('TB-102','Bogdan'),
('TB-103','LAZ'),
('TB-104','Skoda'),
('TB-105','Skoda'),
('TB-106','Electron'),
('TB-107','Electron'),
('TB-108','MAZ'),
('TB-109','Yutong'),
('TB-110','Volvo'),
('TB-111','Solaris'),
('TB-112','MAN'),
('TB-113','Mercedes'),
('TB-114','BYD'),
('TB-115','Trolza');

-- === route ===
INSERT INTO route (number, start_time, end_time, start_point_id, end_point_id, duration_minutes)
VALUES
('R1','06:00','08:00',1,5,120),
('R2','07:00','09:00',2,10,120),
('R3','08:00','09:30',3,11,90),
('R4','09:00','10:40',6,8,100),
('R5','10:00','11:20',7,14,80),
('R6','11:00','12:45',1,15,105),
('R7','12:00','13:50',5,9,110),
('R8','13:00','14:30',8,16,90),
('R9','14:00','15:40',3,6,100),
('R10','15:00','16:20',11,13,80),
('R11','16:00','17:50',12,7,110),
('R12','17:00','18:45',9,2,105),
('R13','18:00','19:20',14,4,80),
('R14','19:00','20:50',10,1,110),
('R15','20:00','21:30',15,5,90);

-- === route_stop ===
INSERT INTO route_stop (route_number, stop_id, stop_order) VALUES
('R1',1,1),('R1',4,2),('R1',5,3),
('R2',2,1),('R2',9,2),('R2',10,3),
('R3',3,1),('R3',11,2),
('R4',6,1),('R4',8,2),
('R5',7,1),('R5',14,2),
('R6',1,1),('R6',15,2),
('R7',5,1),('R7',9,2),
('R8',8,1),('R8',16,2),
('R9',3,1),('R9',6,2),
('R10',11,1),('R10',13,2),
('R11',12,1),('R11',7,2),
('R12',9,1),('R12',2,2),
('R13',14,1),('R13',4,2),
('R14',10,1),('R14',1,2),
('R15',15,1),('R15',5,2);

-- === shift ===
INSERT INTO shift (driver_id, work_date, start_time, end_time, trolleybus_number, route_number) VALUES
(1,'2025-11-01','06:00','08:00','TB-101','R1'),
(2,'2025-11-01','08:00','10:00','TB-102','R2'),
(3,'2025-11-01','09:00','11:00','TB-103','R3'),
(4,'2025-11-01','10:00','12:00','TB-104','R4'),
(5,'2025-11-01','11:00','13:00','TB-105','R5'),
(6,'2025-11-01','12:00','14:00','TB-106','R6'),
(7,'2025-11-01','13:00','15:00','TB-107','R7'),
(8,'2025-11-01','14:00','16:00','TB-108','R8'),
(9,'2025-11-01','15:00','17:00','TB-109','R9'),
(10,'2025-11-01','16:00','18:00','TB-110','R10'),
(11,'2025-11-01','17:00','19:00','TB-111','R11'),
(12,'2025-11-01','18:00','20:00','TB-112','R12'),
(13,'2025-11-01','19:00','21:00','TB-113','R13'),
(14,'2025-11-01','20:00','22:00','TB-114','R14'),
(15,'2025-11-01','21:00','23:00','TB-115','R15');

-- === inspection ===
INSERT INTO inspection (trolleybus_number, inspection_date, results, inspector) VALUES
('TB-101','2025-10-01',NULL,'Andrii Kovalenko'),
('TB-102','2025-10-02','Brake pads replaced','Andrii Kovalenko'),
('TB-103','2025-10-03',NULL,'Andrii Kovalenko'),
('TB-104','2025-10-04','Minor oil leak fixed','Oksana Bilyk'),
('TB-105','2025-10-05',NULL,'Oksana Bilyk'),
('TB-106','2025-10-06','Replaced mirrors','Oksana Bilyk'),
('TB-107','2025-10-07',NULL,'Dmytro Hlushko'),
('TB-108','2025-10-08',NULL,'Dmytro Hlushko'),
('TB-109','2025-10-09','Electrical issue fixed','Dmytro Hlushko'),
('TB-110','2025-10-10',NULL,'Dmytro Hlushko'),
('TB-111','2025-10-11',NULL,'Ihor Maksymchuk'),
('TB-112','2025-10-12','Battery replaced','Ihor Maksymchuk'),
('TB-113','2025-10-13',NULL,'Ihor Maksymchuk'),
('TB-114','2025-10-14','Repainted front','Ihor Maksymchuk'),
('TB-115','2025-10-15',NULL,'Ihor Maksymchuk');
