# Database & SQL Documentation

This document provides instructions for database setup, migrations, and examples of SQL queries used in the project.

## Database Setup

The project uses **PostgreSQL 18** as the primary database. It is managed via Docker for consistent local development.

## Local Infrastructure (Docker)

To start the database container, run:

```bash
docker-compose up -d
```

## Environment Configuration

Copy the template from .env.example to a new file named .env and ensure the connection string is correct:
`DATABASE_URL=postgresql://ipishnyk:ipishnyky@localhost:5433/lab4-nodejs`

## Migrations and Schema

We use SQL scripts in the migrations/ folder to manage the database schema.

- Up: 001_create_tasks_table.up.sql - Creates the tasks table.
- Up: 002_create_priorities_table.up.sql - Creates the priorities table and links tasks to it.
- Down: 001_create_tasks_table.down.sql - Drops the tasks table.
- Down: 002_create_priorities_table.down.sql - Removes the priorities relation and drops the priorities table.

## Table Structure (DDL)

The core tables for this project are `tasks` and `priorities`:

```sql
CREATE TABLE IF NOT EXISTS priorities (
    id INT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    label VARCHAR(50) NOT NULL,
    weight INT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    due_date DATE,
    priority INT NOT NULL DEFAULT 1 REFERENCES priorities(id),
    is_done BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Relationship: one priority can be assigned to many tasks (`priorities` 1:N `tasks`).

## Data Management Scripts

Use the following npm scripts defined in package.json to manage your data:

- Initialize Schema: **npm run migrate:up** - Applies migrations.
- Insert Seed Data: **npm run seed** - Populates the DB using the scripts/seed.js tool (supports multiple Node.js patterns).
- Reset Database: **npm run migrate:refresh** - Re-runs all migrations from scratch.

## SQL Query Examples (CRUD)

The following raw SQL queries are implemented in **src/repositories/taskRepo.js** using the pg (node-postgres) library:

| Operation  | SQL Command                                                                                                        |
| :--------- | :----------------------------------------------------------------------------------------------------------------- |
| Create     | INSERT INTO tasks (title, due_date, priority, is_done) VALUES ($1, $2, $3, $4) RETURNING \*;                       |
| Read (All) | SELECT t.\*, p.code AS priority_code FROM tasks t JOIN priorities p ON p.id = t.priority ORDER BY created_at DESC; |
| Read (One) | SELECT t.\*, p.code AS priority_code FROM tasks t JOIN priorities p ON p.id = t.priority WHERE t.id = $1;          |
| Update     | UPDATE tasks SET title = $1, due_date = $2, priority = $3, is_done = $4 WHERE id = $5 RETURNING \*;                |
| Delete     | DELETE FROM tasks WHERE id = $1 RETURNING id;                                                                      |

## Transaction Demonstration

The project demonstrates advanced transaction management through the Reschedule Overdue Tasks feature.

### Scenario: Rescheduling Overdue Tasks

This operation moves all overdue tasks to the nearest available future dates while respecting a daily capacity limit (e.g., max 3 tasks per day).

- Atomic Success (Commit): If all overdue tasks find a slot within the planning window (e.g., 14 days), the database updates all rows and increments their priority.
- Business Logic Rollback: If the backlog exceeds the available capacity in the planning window, the system throws a 422 Unprocessable Entity error. The ROLLBACK command is issued, ensuring that no tasks are partially rescheduled, maintaining a consistent state.

## API Usage Examples

Interact with the system via the following endpoints:

1. View Dashboard

- Request: GET http://localhost:3000/
- Logic: Executes SELECT with ORDER BY created_at DESC.

2. Update Task

- Request: POST http://localhost:3000/tasks/:id?\_method=PUT
- Body: title=Update&date=2026-05-10&priority=medium&completed=on

3. Reschedule Overdue (Transaction Demo)

- Request: POST http://localhost:3000/tasks/reschedule-overdue
- Params: maxPerDay=3, windowDays=14
