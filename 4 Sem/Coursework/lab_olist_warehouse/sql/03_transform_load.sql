PRAGMA foreign_keys = ON;

INSERT OR IGNORE INTO dim_date (
    date_key, full_date, year, quarter, month, month_name, day, day_of_week, day_name, week_of_year
)
WITH raw_dates(full_date) AS (
    SELECT substr(order_purchase_timestamp, 1, 10) FROM stg_orders WHERE order_purchase_timestamp IS NOT NULL AND order_purchase_timestamp <> ''
    UNION
    SELECT substr(order_approved_at, 1, 10) FROM stg_orders WHERE order_approved_at IS NOT NULL AND order_approved_at <> ''
    UNION
    SELECT substr(order_delivered_carrier_date, 1, 10) FROM stg_orders WHERE order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date <> ''
    UNION
    SELECT substr(order_delivered_customer_date, 1, 10) FROM stg_orders WHERE order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date <> ''
    UNION
    SELECT substr(order_estimated_delivery_date, 1, 10) FROM stg_orders WHERE order_estimated_delivery_date IS NOT NULL AND order_estimated_delivery_date <> ''
    UNION
    SELECT substr(shipping_limit_date, 1, 10) FROM stg_order_items WHERE shipping_limit_date IS NOT NULL AND shipping_limit_date <> ''
    UNION
    SELECT substr(review_creation_date, 1, 10) FROM stg_order_reviews WHERE review_creation_date IS NOT NULL AND review_creation_date <> ''
    UNION
    SELECT substr(review_answer_timestamp, 1, 10) FROM stg_order_reviews WHERE review_answer_timestamp IS NOT NULL AND review_answer_timestamp <> ''
),
valid_dates AS (
    SELECT DISTINCT full_date
    FROM raw_dates
    WHERE full_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
)
SELECT
    CAST(strftime('%Y%m%d', full_date) AS INTEGER) AS date_key,
    full_date,
    CAST(strftime('%Y', full_date) AS INTEGER) AS year,
    ((CAST(strftime('%m', full_date) AS INTEGER) - 1) / 3) + 1 AS quarter,
    CAST(strftime('%m', full_date) AS INTEGER) AS month,
    CASE strftime('%m', full_date)
        WHEN '01' THEN 'January' WHEN '02' THEN 'February' WHEN '03' THEN 'March'
        WHEN '04' THEN 'April' WHEN '05' THEN 'May' WHEN '06' THEN 'June'
        WHEN '07' THEN 'July' WHEN '08' THEN 'August' WHEN '09' THEN 'September'
        WHEN '10' THEN 'October' WHEN '11' THEN 'November' ELSE 'December'
    END AS month_name,
    CAST(strftime('%d', full_date) AS INTEGER) AS day,
    CAST(strftime('%w', full_date) AS INTEGER) + 1 AS day_of_week,
    CASE strftime('%w', full_date)
        WHEN '0' THEN 'Sunday' WHEN '1' THEN 'Monday' WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday' WHEN '5' THEN 'Friday'
        ELSE 'Saturday'
    END AS day_name,
    CAST(strftime('%W', full_date) AS INTEGER) AS week_of_year
FROM valid_dates;

INSERT INTO dim_location (zip_code_prefix, city, state, avg_lat, avg_lng, source_count)
SELECT
    geolocation_zip_code_prefix,
    lower(trim(geolocation_city)),
    upper(trim(geolocation_state)),
    avg(geolocation_lat),
    avg(geolocation_lng),
    count(*)
FROM stg_geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
  AND geolocation_zip_code_prefix <> ''
  AND geolocation_city IS NOT NULL
  AND geolocation_state IS NOT NULL
GROUP BY geolocation_zip_code_prefix, lower(trim(geolocation_city)), upper(trim(geolocation_state))
ON CONFLICT (zip_code_prefix, city, state) DO UPDATE SET
    avg_lat = excluded.avg_lat,
    avg_lng = excluded.avg_lng,
    source_count = excluded.source_count;

INSERT INTO dim_location (zip_code_prefix, city, state, avg_lat, avg_lng, source_count)
SELECT DISTINCT
    customer_zip_code_prefix,
    lower(trim(customer_city)),
    upper(trim(customer_state)),
    NULL,
    NULL,
    0
FROM stg_customers
WHERE customer_zip_code_prefix IS NOT NULL
  AND customer_city IS NOT NULL
  AND customer_state IS NOT NULL
ON CONFLICT (zip_code_prefix, city, state) DO NOTHING;

INSERT INTO dim_location (zip_code_prefix, city, state, avg_lat, avg_lng, source_count)
SELECT DISTINCT
    seller_zip_code_prefix,
    lower(trim(seller_city)),
    upper(trim(seller_state)),
    NULL,
    NULL,
    0
FROM stg_sellers
WHERE seller_zip_code_prefix IS NOT NULL
  AND seller_city IS NOT NULL
  AND seller_state IS NOT NULL
ON CONFLICT (zip_code_prefix, city, state) DO NOTHING;

INSERT INTO dim_order_status (order_status)
SELECT DISTINCT lower(trim(order_status))
FROM stg_orders
WHERE order_status IS NOT NULL AND trim(order_status) <> ''
ON CONFLICT (order_status) DO NOTHING;

INSERT INTO dim_payment_type (payment_type)
SELECT DISTINCT lower(trim(payment_type))
FROM stg_order_payments
WHERE payment_type IS NOT NULL AND trim(payment_type) <> ''
ON CONFLICT (payment_type) DO NOTHING;

INSERT INTO dim_category (category_name, category_name_english)
SELECT
    category_name,
    COALESCE(NULLIF(trim(t.product_category_name_english), ''), category_name) AS category_name_english
FROM (
    SELECT DISTINCT COALESCE(NULLIF(trim(product_category_name), ''), 'unknown') AS category_name
    FROM stg_products
    UNION
    SELECT DISTINCT COALESCE(NULLIF(trim(product_category_name), ''), 'unknown') AS category_name
    FROM stg_product_category_translation
) c
LEFT JOIN stg_product_category_translation t
    ON t.product_category_name = c.category_name
ON CONFLICT (category_name) DO UPDATE SET
    category_name_english = excluded.category_name_english;

INSERT INTO dim_product (
    product_id, category_key, product_name_length, product_description_length,
    product_photos_qty, product_weight_g, product_length_cm, product_height_cm,
    product_width_cm, product_hash, updated_at
)
SELECT
    p.product_id,
    c.category_key,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_id || '|' ||
        COALESCE(p.product_category_name, 'unknown') || '|' ||
        COALESCE(CAST(p.product_name_lenght AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_description_lenght AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_photos_qty AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_weight_g AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_length_cm AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_height_cm AS TEXT), '') || '|' ||
        COALESCE(CAST(p.product_width_cm AS TEXT), '') AS product_hash,
    datetime('now')
FROM stg_products p
LEFT JOIN dim_category c
    ON c.category_name = COALESCE(NULLIF(trim(p.product_category_name), ''), 'unknown')
ON CONFLICT (product_id) DO UPDATE SET
    category_key = excluded.category_key,
    product_name_length = excluded.product_name_length,
    product_description_length = excluded.product_description_length,
    product_photos_qty = excluded.product_photos_qty,
    product_weight_g = excluded.product_weight_g,
    product_length_cm = excluded.product_length_cm,
    product_height_cm = excluded.product_height_cm,
    product_width_cm = excluded.product_width_cm,
    product_hash = excluded.product_hash,
    updated_at = excluded.updated_at
WHERE dim_product.product_hash <> excluded.product_hash;

INSERT INTO dim_customer (
    customer_id, customer_unique_id, location_key, zip_code_prefix, city, state, updated_at
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    l.location_key,
    c.customer_zip_code_prefix,
    lower(trim(c.customer_city)),
    upper(trim(c.customer_state)),
    datetime('now')
FROM stg_customers c
LEFT JOIN dim_location l
    ON l.zip_code_prefix = c.customer_zip_code_prefix
   AND l.city = lower(trim(c.customer_city))
   AND l.state = upper(trim(c.customer_state))
ON CONFLICT (customer_id) DO UPDATE SET
    customer_unique_id = excluded.customer_unique_id,
    location_key = excluded.location_key,
    zip_code_prefix = excluded.zip_code_prefix,
    city = excluded.city,
    state = excluded.state,
    updated_at = excluded.updated_at
WHERE dim_customer.customer_unique_id <> excluded.customer_unique_id
   OR dim_customer.location_key IS NOT excluded.location_key
   OR dim_customer.zip_code_prefix <> excluded.zip_code_prefix
   OR dim_customer.city <> excluded.city
   OR dim_customer.state <> excluded.state;

INSERT INTO dim_seller (
    seller_id, location_key, zip_code_prefix, city, state, updated_at
)
SELECT
    s.seller_id,
    l.location_key,
    s.seller_zip_code_prefix,
    lower(trim(s.seller_city)),
    upper(trim(s.seller_state)),
    datetime('now')
FROM stg_sellers s
LEFT JOIN dim_location l
    ON l.zip_code_prefix = s.seller_zip_code_prefix
   AND l.city = lower(trim(s.seller_city))
   AND l.state = upper(trim(s.seller_state))
ON CONFLICT (seller_id) DO UPDATE SET
    location_key = excluded.location_key,
    zip_code_prefix = excluded.zip_code_prefix,
    city = excluded.city,
    state = excluded.state,
    updated_at = excluded.updated_at
WHERE dim_seller.location_key IS NOT excluded.location_key
   OR dim_seller.zip_code_prefix <> excluded.zip_code_prefix
   OR dim_seller.city <> excluded.city
   OR dim_seller.state <> excluded.state;

INSERT INTO fact_order_items (
    order_id, order_item_id, purchase_date_key, shipping_limit_date_key,
    customer_key, seller_key, product_key, customer_location_key, seller_location_key,
    status_key, price, freight_value, total_item_value, days_to_delivery,
    delivery_delay_days, was_delivered_late, row_hash, updated_at
)
SELECT
    i.order_id,
    i.order_item_id,
    CAST(strftime('%Y%m%d', substr(o.order_purchase_timestamp, 1, 10)) AS INTEGER),
    CAST(strftime('%Y%m%d', substr(i.shipping_limit_date, 1, 10)) AS INTEGER),
    dc.customer_key,
    ds.seller_key,
    dp.product_key,
    dc.location_key,
    ds.location_key,
    dos.status_key,
    COALESCE(i.price, 0),
    COALESCE(i.freight_value, 0),
    COALESCE(i.price, 0) + COALESCE(i.freight_value, 0),
    CASE
        WHEN o.order_delivered_customer_date IS NULL OR o.order_delivered_customer_date = '' THEN NULL
        ELSE round(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp), 2)
    END,
    CASE
        WHEN o.order_delivered_customer_date IS NULL OR o.order_delivered_customer_date = '' THEN NULL
        ELSE round(julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date), 2)
    END,
    CASE
        WHEN o.order_delivered_customer_date IS NULL OR o.order_delivered_customer_date = '' THEN NULL
        WHEN julianday(o.order_delivered_customer_date) > julianday(o.order_estimated_delivery_date) THEN 1
        ELSE 0
    END,
    i.order_id || '|' || i.order_item_id || '|' || COALESCE(i.product_id, '') || '|' ||
        COALESCE(i.seller_id, '') || '|' || COALESCE(CAST(i.price AS TEXT), '') || '|' ||
        COALESCE(CAST(i.freight_value AS TEXT), '') || '|' || COALESCE(o.order_status, ''),
    datetime('now')
FROM stg_order_items i
JOIN stg_orders o ON o.order_id = i.order_id
LEFT JOIN dim_customer dc ON dc.customer_id = o.customer_id
LEFT JOIN dim_seller ds ON ds.seller_id = i.seller_id
LEFT JOIN dim_product dp ON dp.product_id = i.product_id
LEFT JOIN dim_order_status dos ON dos.order_status = lower(trim(o.order_status))
ON CONFLICT (order_id, order_item_id) DO UPDATE SET
    purchase_date_key = excluded.purchase_date_key,
    shipping_limit_date_key = excluded.shipping_limit_date_key,
    customer_key = excluded.customer_key,
    seller_key = excluded.seller_key,
    product_key = excluded.product_key,
    customer_location_key = excluded.customer_location_key,
    seller_location_key = excluded.seller_location_key,
    status_key = excluded.status_key,
    price = excluded.price,
    freight_value = excluded.freight_value,
    total_item_value = excluded.total_item_value,
    days_to_delivery = excluded.days_to_delivery,
    delivery_delay_days = excluded.delivery_delay_days,
    was_delivered_late = excluded.was_delivered_late,
    row_hash = excluded.row_hash,
    updated_at = excluded.updated_at
WHERE fact_order_items.row_hash <> excluded.row_hash;

INSERT INTO fact_payments (
    order_id, payment_sequential, purchase_date_key, customer_key,
    payment_type_key, status_key, payment_installments, payment_value,
    row_hash, updated_at
)
SELECT
    p.order_id,
    p.payment_sequential,
    CAST(strftime('%Y%m%d', substr(o.order_purchase_timestamp, 1, 10)) AS INTEGER),
    dc.customer_key,
    dpt.payment_type_key,
    dos.status_key,
    COALESCE(p.payment_installments, 0),
    COALESCE(p.payment_value, 0),
    p.order_id || '|' || p.payment_sequential || '|' || COALESCE(p.payment_type, '') || '|' ||
        COALESCE(CAST(p.payment_installments AS TEXT), '') || '|' || COALESCE(CAST(p.payment_value AS TEXT), ''),
    datetime('now')
FROM stg_order_payments p
JOIN stg_orders o ON o.order_id = p.order_id
LEFT JOIN dim_customer dc ON dc.customer_id = o.customer_id
LEFT JOIN dim_payment_type dpt ON dpt.payment_type = lower(trim(p.payment_type))
LEFT JOIN dim_order_status dos ON dos.order_status = lower(trim(o.order_status))
ON CONFLICT (order_id, payment_sequential) DO UPDATE SET
    purchase_date_key = excluded.purchase_date_key,
    customer_key = excluded.customer_key,
    payment_type_key = excluded.payment_type_key,
    status_key = excluded.status_key,
    payment_installments = excluded.payment_installments,
    payment_value = excluded.payment_value,
    row_hash = excluded.row_hash,
    updated_at = excluded.updated_at
WHERE fact_payments.row_hash <> excluded.row_hash;

INSERT INTO fact_reviews (
    review_id, order_id, review_date_key, customer_key, status_key,
    review_score, has_comment, answer_delay_hours, row_hash, updated_at
)
SELECT
    r.review_id,
    r.order_id,
    CAST(strftime('%Y%m%d', substr(r.review_creation_date, 1, 10)) AS INTEGER),
    dc.customer_key,
    dos.status_key,
    COALESCE(r.review_score, 0),
    CASE
        WHEN COALESCE(trim(r.review_comment_title), '') <> ''
          OR COALESCE(trim(r.review_comment_message), '') <> '' THEN 1
        ELSE 0
    END,
    CASE
        WHEN r.review_answer_timestamp IS NULL OR r.review_answer_timestamp = '' THEN NULL
        ELSE round((julianday(r.review_answer_timestamp) - julianday(r.review_creation_date)) * 24, 2)
    END,
    r.review_id || '|' || r.order_id || '|' || COALESCE(CAST(r.review_score AS TEXT), '') || '|' ||
        COALESCE(r.review_comment_title, '') || '|' || COALESCE(r.review_comment_message, ''),
    datetime('now')
FROM stg_order_reviews r
JOIN stg_orders o ON o.order_id = r.order_id
LEFT JOIN dim_customer dc ON dc.customer_id = o.customer_id
LEFT JOIN dim_order_status dos ON dos.order_status = lower(trim(o.order_status))
ON CONFLICT (review_id, order_id) DO UPDATE SET
    review_date_key = excluded.review_date_key,
    customer_key = excluded.customer_key,
    status_key = excluded.status_key,
    review_score = excluded.review_score,
    has_comment = excluded.has_comment,
    answer_delay_hours = excluded.answer_delay_hours,
    row_hash = excluded.row_hash,
    updated_at = excluded.updated_at
WHERE fact_reviews.row_hash <> excluded.row_hash;

