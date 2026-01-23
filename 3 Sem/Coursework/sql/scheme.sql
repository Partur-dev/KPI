CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE city (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    population INT CHECK (population > 0)
);

CREATE TABLE district (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city_id INT NOT NULL,
    FOREIGN KEY (city_id) REFERENCES city (id) ON DELETE CASCADE
);

CREATE TABLE address (
    id SERIAL PRIMARY KEY,
    district_id INT NOT NULL,
    street VARCHAR(100) NOT NULL,
    building VARCHAR(20) NOT NULL,
    location GEOMETRY(POINT, 4326),
    FOREIGN KEY (district_id) REFERENCES district (id) ON DELETE RESTRICT
);

CREATE INDEX idx_address_location ON address USING GIST (location);

CREATE TABLE organization (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL,
    contacts TEXT
);

CREATE TABLE responsible_person (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    organization_id INT NOT NULL,
    role VARCHAR(100),
    FOREIGN KEY (organization_id) REFERENCES organization (id) ON DELETE CASCADE
);

CREATE TABLE shelter (
    id SERIAL PRIMARY KEY,
    address_id INT NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    status VARCHAR(50) NOT NULL CHECK (status IN ('Ready', 'Limited Ready', 'Not Ready')),
    organization_id INT NOT NULL,
    responsible_id INT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('Bomb Shelter', 'Radiation Shelter', 'Dual Use', 'Simple Shelter')),
    FOREIGN KEY (address_id) REFERENCES address (id),
    FOREIGN KEY (organization_id) REFERENCES organization (id),
    FOREIGN KEY (responsible_id) REFERENCES responsible_person (id)
);

CREATE TABLE shelter_entrance (
    id SERIAL PRIMARY KEY,
    shelter_id INT NOT NULL,
    address_id INT NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    note TEXT,
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES address (id)
);

CREATE TABLE threat (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    severity INT CHECK (severity BETWEEN 1 AND 10)
);

CREATE TABLE shelter_threat (
    shelter_id INT NOT NULL,
    threat_id INT NOT NULL,
    PRIMARY KEY (shelter_id, threat_id),
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE,
    FOREIGN KEY (threat_id) REFERENCES threat (id) ON DELETE CASCADE
);

CREATE TABLE feature (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE shelter_feature (
    shelter_id INT NOT NULL,
    feature_id INT NOT NULL,
    value VARCHAR(100),
    notes TEXT,
    PRIMARY KEY (shelter_id, feature_id),
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE,
    FOREIGN KEY (feature_id) REFERENCES feature (id) ON DELETE CASCADE
);

CREATE TABLE inventory_item (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    category VARCHAR(50)
);

CREATE TABLE shelter_inventory (
    shelter_id INT NOT NULL,
    item_id INT NOT NULL,
    value DECIMAL(10,2) NOT NULL CHECK (value >= 0),
    notes TEXT,
    expiration_date DATE,
    PRIMARY KEY (shelter_id, item_id),
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES inventory_item (id) ON DELETE RESTRICT
);

CREATE TABLE inspector (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL
);

CREATE TABLE inspection (
    id SERIAL PRIMARY KEY,
    shelter_id INT NOT NULL,
    inspector_id INT NOT NULL,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Passed', 'Failed', 'Needs Improvement')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE,
    FOREIGN KEY (inspector_id) REFERENCES inspector (id)
);

CREATE TABLE route (
    id SERIAL PRIMARY KEY,
    shelter_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    distance DECIMAL(10,2) CHECK (distance >= 0),
    FOREIGN KEY (shelter_id) REFERENCES shelter (id) ON DELETE CASCADE
);

CREATE TABLE route_stop (
    route_id INT NOT NULL,
    address_id INT NOT NULL,
    stop_order INT NOT NULL CHECK (stop_order >= 1),
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('Start', 'Intermediate', 'Finish')),
    PRIMARY KEY (route_id, stop_order),
    FOREIGN KEY (route_id) REFERENCES route (id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES address (id)
);
