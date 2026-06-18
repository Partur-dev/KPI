PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date TEXT NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name TEXT NOT NULL,
    week_of_year INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_location (
    location_key INTEGER PRIMARY KEY AUTOINCREMENT,
    zip_code_prefix TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    avg_lat REAL,
    avg_lng REAL,
    source_count INTEGER NOT NULL DEFAULT 0,
    UNIQUE (zip_code_prefix, city, state)
);

CREATE TABLE IF NOT EXISTS dim_order_status (
    status_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_status TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_payment_type (
    payment_type_key INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_type TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_category (
    category_key INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name TEXT NOT NULL UNIQUE,
    category_name_english TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_key INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id TEXT NOT NULL UNIQUE,
    category_key INTEGER,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    product_hash TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (category_key) REFERENCES dim_category(category_key)
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id TEXT NOT NULL UNIQUE,
    customer_unique_id TEXT NOT NULL,
    location_key INTEGER,
    zip_code_prefix TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
);

CREATE TABLE IF NOT EXISTS dim_seller (
    seller_key INTEGER PRIMARY KEY AUTOINCREMENT,
    seller_id TEXT NOT NULL UNIQUE,
    location_key INTEGER,
    zip_code_prefix TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
);

CREATE TABLE IF NOT EXISTS fact_order_items (
    order_item_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    purchase_date_key INTEGER,
    shipping_limit_date_key INTEGER,
    customer_key INTEGER,
    seller_key INTEGER,
    product_key INTEGER,
    customer_location_key INTEGER,
    seller_location_key INTEGER,
    status_key INTEGER,
    price REAL NOT NULL,
    freight_value REAL NOT NULL,
    total_item_value REAL NOT NULL,
    days_to_delivery REAL,
    delivery_delay_days REAL,
    was_delivered_late INTEGER,
    row_hash TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (order_id, order_item_id),
    FOREIGN KEY (purchase_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (shipping_limit_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (seller_key) REFERENCES dim_seller(seller_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (customer_location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (seller_location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (status_key) REFERENCES dim_order_status(status_key)
);

CREATE TABLE IF NOT EXISTS fact_payments (
    payment_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT NOT NULL,
    payment_sequential INTEGER NOT NULL,
    purchase_date_key INTEGER,
    customer_key INTEGER,
    payment_type_key INTEGER,
    status_key INTEGER,
    payment_installments INTEGER NOT NULL,
    payment_value REAL NOT NULL,
    row_hash TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (order_id, payment_sequential),
    FOREIGN KEY (purchase_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (payment_type_key) REFERENCES dim_payment_type(payment_type_key),
    FOREIGN KEY (status_key) REFERENCES dim_order_status(status_key)
);

CREATE TABLE IF NOT EXISTS fact_reviews (
    review_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    review_date_key INTEGER,
    customer_key INTEGER,
    status_key INTEGER,
    review_score INTEGER NOT NULL,
    has_comment INTEGER NOT NULL,
    answer_delay_hours REAL,
    row_hash TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (review_id, order_id),
    FOREIGN KEY (review_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (status_key) REFERENCES dim_order_status(status_key)
);

CREATE TABLE IF NOT EXISTS etl_run_log (
    run_id INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    finished_at TEXT,
    status TEXT NOT NULL,
    stage_rows INTEGER DEFAULT 0,
    warehouse_rows INTEGER DEFAULT 0,
    message TEXT
);

CREATE INDEX IF NOT EXISTS idx_dim_location_nk ON dim_location(zip_code_prefix, city, state);
CREATE INDEX IF NOT EXISTS idx_dim_customer_location ON dim_customer(location_key);
CREATE INDEX IF NOT EXISTS idx_dim_seller_location ON dim_seller(location_key);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_date ON fact_order_items(purchase_date_key);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_customer ON fact_order_items(customer_key);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_seller ON fact_order_items(seller_key);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_product ON fact_order_items(product_key);
CREATE INDEX IF NOT EXISTS idx_fact_payments_date ON fact_payments(purchase_date_key);
CREATE INDEX IF NOT EXISTS idx_fact_reviews_date ON fact_reviews(review_date_key);

