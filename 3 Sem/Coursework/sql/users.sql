CREATE ROLE admin_role;
CREATE ROLE inspector_role;
CREATE ROLE manager_role;
CREATE ROLE guest_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;

GRANT SELECT ON shelter, address, organization, responsible_person, shelter_entrance TO inspector_role;
GRANT INSERT ON inspection TO inspector_role;
GRANT USAGE, SELECT ON SEQUENCE inspection_id_seq TO inspector_role;

GRANT SELECT ON threat, feature, inventory_item TO manager_role;
GRANT SELECT, UPDATE ON shelter TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON shelter_inventory TO manager_role;
GRANT SELECT, INSERT, UPDATE ON responsible_person TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON shelter_feature TO manager_role;
GRANT USAGE, SELECT ON SEQUENCE responsible_person_id_seq TO manager_role;

GRANT SELECT ON city, district, address, shelter, shelter_entrance, route, route_stop TO guest_role;

CREATE USER sys_admin WITH PASSWORD 'secure_pass_admin';
GRANT admin_role TO sys_admin;

CREATE USER insp_petrenko WITH PASSWORD 'insp_pass_2024';
GRANT inspector_role TO insp_petrenko;

CREATE USER manager_osbb WITH PASSWORD 'manager_pass_123';
GRANT manager_role TO manager_osbb;

CREATE USER public_web_client WITH PASSWORD 'guest_access_only';
GRANT guest_role TO public_web_client;