-- Work with cursors: open, fetch, log, close

CREATE PROCEDURE proc_cursor_demo()
LANGUAGE plpgsql
AS $$
DECLARE
  cur refcursor;
  rec record;
BEGIN
  OPEN cur FOR SELECT id, name, location FROM stop ORDER BY id;

  LOOP
    FETCH cur INTO rec;
    EXIT WHEN NOT FOUND;
    RAISE NOTICE 'Stop %: % (%)', rec.id, rec.name, rec.location;
  END LOOP;

  CLOSE cur;
END;
$$;
