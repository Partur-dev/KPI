-- Виручка, кількість позицій та середня оцінка за категоріями.
SELECT
    c.category_name_english,
    COUNT(*) AS order_items,
    ROUND(SUM(f.total_item_value), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM fact_order_items f
JOIN dim_product p ON p.product_key = f.product_key
JOIN dim_category c ON c.category_key = p.category_key
LEFT JOIN fact_reviews r ON r.order_id = f.order_id
GROUP BY c.category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- Динаміка продажів за місяцями.
SELECT
    d.year,
    d.month,
    COUNT(*) AS order_items,
    ROUND(SUM(f.total_item_value), 2) AS total_revenue
FROM fact_order_items f
JOIN dim_date d ON d.date_key = f.purchase_date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Частка запізнілих доставок за штатами покупців.
SELECT
    l.state,
    COUNT(*) AS delivered_items,
    ROUND(100.0 * SUM(CASE WHEN f.was_delivered_late = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_delivery_pct
FROM fact_order_items f
JOIN dim_location l ON l.location_key = f.customer_location_key
WHERE f.was_delivered_late IS NOT NULL
GROUP BY l.state
ORDER BY late_delivery_pct DESC;

