SELECT name 
FROM driver 
WHERE id IN (
    SELECT driver_id 
    FROM shift 
    WHERE start_time > '07:00' 
      AND end_time < '12:00'
);
