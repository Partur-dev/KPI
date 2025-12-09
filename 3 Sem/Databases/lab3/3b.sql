WITH 
    -- Визначаємо ID початкової та кінцевої точок для зручності
    start_stop AS (SELECT id FROM stop WHERE name = 'Airport'),
    end_stop AS (SELECT id FROM stop WHERE name = 'University')

-- ЧАСТИНА 1: Прямі маршрути
SELECT 
    r.number AS route_1, 
    NULL AS transfer_stop, 
    NULL AS route_2,
    'Direct' AS type
FROM route r
JOIN route_stop rs_start ON r.number = rs_start.route_number
JOIN route_stop rs_end ON r.number = rs_end.route_number
WHERE rs_start.stop_id = (SELECT id FROM start_stop)
  AND rs_end.stop_id = (SELECT id FROM end_stop)
  AND rs_start.stop_order < rs_end.stop_order -- Перевірка напрямку руху

UNION ALL

-- ЧАСТИНА 2: Маршрути з однією пересадкою
SELECT 
    r1.number AS route_1, 
    transfer_st.name AS transfer_stop, 
    r2.number AS route_2,
    'Transfer' AS type
FROM route r1
JOIN route_stop rs1_start ON r1.number = rs1_start.route_number
JOIN route_stop rs1_trans ON r1.number = rs1_trans.route_number -- Кінець першого відрізка (пересадка)
JOIN stop transfer_st ON rs1_trans.stop_id = transfer_st.id     -- Отримуємо назву зупинки пересадки
JOIN route_stop rs2_trans ON transfer_st.id = rs2_trans.stop_id -- Початок другого відрізка (та ж зупинка)
JOIN route r2 ON rs2_trans.route_number = r2.number
JOIN route_stop rs2_end ON r2.number = rs2_end.route_number     -- Кінець шляху
WHERE rs1_start.stop_id = (SELECT id FROM start_stop)
  AND rs2_end.stop_id = (SELECT id FROM end_stop)
  -- Перевіряємо напрямок руху для обох маршрутів
  AND rs1_start.stop_order < rs1_trans.stop_order
  AND rs2_trans.stop_order < rs2_end.stop_order
  -- Виключаємо варіант пересадки на той самий маршрут
  AND r1.number <> r2.number;
