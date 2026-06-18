import pool from "../db/index.js";

export class TaskRepo {
  #mapRowToTask(row) {
    if (!row) return null;

    const priorityMap = {
      1: "low",
      2: "medium",
      3: "high",
    };

    return {
      id: String(row.id),
      title: row.title,
      date: row.due_date ? row.due_date.toISOString().split("T")[0] : null,
      priority: row.priority_code || priorityMap[row.priority] || "low",
      completed: row.is_done,
    };
  }

  #priorityToInt(priority) {
    const map = {
      low: 1,
      medium: 2,
      high: 3,
    };
    return map[priority] || 1;
  }

  async getAll() {
    const result = await pool.query(
      `SELECT t.id, t.title, t.due_date, t.priority, p.code AS priority_code, t.is_done, t.created_at
       FROM tasks t
       JOIN priorities p ON p.id = t.priority
       ORDER BY t.created_at DESC`,
    );

    return result.rows.map((row) => this.#mapRowToTask(row));
  }

  async getById(id) {
    const result = await pool.query(
      `SELECT t.id, t.title, t.due_date, t.priority, p.code AS priority_code, t.is_done, t.created_at
       FROM tasks t
       JOIN priorities p ON p.id = t.priority
       WHERE t.id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.#mapRowToTask(result.rows[0]) : null;
  }

  async add(task) {
    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      const priorityInt = this.#priorityToInt(task.priority);
      const result = await client.query(
        `INSERT INTO tasks (title, due_date, priority, is_done)
         VALUES ($1, $2, $3, $4)
         RETURNING id, title, due_date, priority, is_done, created_at,
           (SELECT code FROM priorities WHERE id = priority) AS priority_code`,
        [task.title, task.date || null, priorityInt, false],
      );

      await client.query("COMMIT");
      return this.#mapRowToTask(result.rows[0]);
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async update(id, updates) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (updates.title !== undefined) {
      fields.push(`title = $${paramCount++}`);
      values.push(updates.title);
    }

    if (updates.date !== undefined) {
      fields.push(`due_date = $${paramCount++}`);
      values.push(updates.date || null);
    }

    if (updates.priority !== undefined) {
      fields.push(`priority = $${paramCount++}`);
      values.push(this.#priorityToInt(updates.priority));
    }

    if (updates.completed !== undefined) {
      fields.push(`is_done = $${paramCount++}`);
      values.push(updates.completed);
    }
    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      if (fields.length === 0) {
        await client.query("ROLLBACK");
        const existing = await client.query(
          `SELECT t.id, t.title, t.due_date, t.priority, p.code AS priority_code, t.is_done, t.created_at
           FROM tasks t
           JOIN priorities p ON p.id = t.priority
           WHERE t.id = $1`,
          [id],
        );
        return existing.rows.length > 0
          ? this.#mapRowToTask(existing.rows[0])
          : null;
      }

      values.push(id);
      const query = `UPDATE tasks
        SET ${fields.join(", ")}
        WHERE id = $${paramCount}
        RETURNING id, title, due_date, priority, is_done, created_at,
          (SELECT code FROM priorities WHERE id = priority) AS priority_code`;

      const result = await client.query(query, values);

      await client.query("COMMIT");
      return result.rows.length > 0 ? this.#mapRowToTask(result.rows[0]) : null;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async rescheduleOverdue(maxPerDay = 3, windowDays = 14) {
    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      const overdue = await client.query(
        `SELECT t.id, t.title, t.due_date, t.priority, p.code AS priority_code, t.is_done, t.created_at
         FROM tasks t
         JOIN priorities p ON p.id = t.priority
         WHERE due_date < CURRENT_DATE AND is_done = false
         ORDER BY p.weight DESC, due_date ASC`,
      );

      if (overdue.rows.length === 0) {
        await client.query("COMMIT");
        return [];
      }

      // Snapshot of how many tasks are already filling each future day.
      const existing = await client.query(
        `SELECT due_date::date AS day, COUNT(*)::int AS count
         FROM tasks
         WHERE due_date >= CURRENT_DATE
           AND due_date < CURRENT_DATE + $1::int
           AND is_done = false
         GROUP BY due_date::date`,
        [windowDays],
      );

      const slotMap = new Map(
        existing.rows.map((r) => [r.day.toISOString().split("T")[0], r.count]),
      );

      const updated = [];
      for (const row of overdue.rows) {
        // Find the nearest future day within the window that still has capacity.
        // Each placement updates slotMap so subsequent tasks see accurate counts.
        let targetDate = null;
        for (let d = 1; d <= windowDays; d++) {
          const candidate = new Date();
          candidate.setDate(candidate.getDate() + d);
          const key = candidate.toISOString().split("T")[0];
          if ((slotMap.get(key) ?? 0) < maxPerDay) {
            targetDate = key;
            slotMap.set(key, (slotMap.get(key) ?? 0) + 1);
            break;
          }
        }

        // Business logic abort: backlog exceeds planning capacity.
        // The throw triggers ROLLBACK, undoing every placement made so far.
        if (!targetDate) {
          const err = new Error(
            `Capacity exceeded: cannot fit all ${overdue.rows.length} overdue tasks ` +
              `within ${windowDays} days at ${maxPerDay} tasks/day. No tasks were rescheduled.`,
          );
          err.status = 422;
          throw err;
        }

        const result = await client.query(
          `UPDATE tasks
           SET due_date = $1,
             priority = (
               SELECT next_priority.id
               FROM priorities current_priority
               JOIN priorities next_priority
                 ON next_priority.weight = LEAST(current_priority.weight + 1, 3)
               WHERE current_priority.id = tasks.priority
           )
           WHERE id = $2
           RETURNING id, title, due_date, priority, is_done, created_at,
             (SELECT code FROM priorities WHERE id = priority) AS priority_code`,
          [targetDate, row.id],
        );

        updated.push(this.#mapRowToTask(result.rows[0]));
      }

      await client.query("COMMIT");
      return updated;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async delete(id) {
    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      const result = await client.query(
        `DELETE FROM tasks WHERE id = $1 RETURNING id`,
        [id],
      );

      await client.query("COMMIT");
      return result.rows.length > 0 ? String(result.rows[0].id) : null;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }
}
