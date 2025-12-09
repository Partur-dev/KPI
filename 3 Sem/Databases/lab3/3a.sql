SELECT DISTINCT t.number AS trolleybus_number
FROM trolleybus t
JOIN brand b ON t.brand_name = b.name
-- З'єднуємо зі змінами, щоб дізнатися, на якому маршруті їздить машина
JOIN shift s ON t.number = s.trolleybus_number
-- З'єднуємо з таблицею зупинок маршруту
JOIN route_stop rs ON s.route_number = rs.route_number
-- Отримуємо назву зупинки
JOIN stop st ON rs.stop_id = st.id
WHERE b.name = 'Bogdan'
  AND st.name = 'University';
