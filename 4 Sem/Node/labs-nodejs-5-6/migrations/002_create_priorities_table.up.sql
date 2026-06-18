CREATE TABLE IF NOT EXISTS priorities (
    id INT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    label VARCHAR(50) NOT NULL,
    weight INT NOT NULL UNIQUE
);

INSERT INTO priorities (id, code, label, weight) VALUES
    (1, 'low', 'Low', 1),
    (2, 'medium', 'Medium', 2),
    (3, 'high', 'High', 3)
ON CONFLICT (id) DO UPDATE SET
    code = EXCLUDED.code,
    label = EXCLUDED.label,
    weight = EXCLUDED.weight;

UPDATE tasks
SET priority = 1
WHERE priority IS NULL
   OR priority NOT IN (SELECT id FROM priorities);

ALTER TABLE tasks
    ALTER COLUMN priority SET DEFAULT 1,
    ALTER COLUMN priority SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tasks_priority_fkey'
          AND conrelid = 'tasks'::regclass
    ) THEN
        ALTER TABLE tasks
            ADD CONSTRAINT tasks_priority_fkey
            FOREIGN KEY (priority)
            REFERENCES priorities(id);
    END IF;
END $$;
