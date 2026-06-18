# Seeding & Async Patterns Documentation

### Overview

This section of the project implements automated data seeding into the `tasks` table using four distinct asynchronous approaches in Node.js to demonstrate the evolution of the language's concurrency models.

### Local Usage (Commands)

To populate the database using a specific method, run the corresponding command:

- **Sync-style:** `node scripts/seed-sync.js`
- **Callback:** `node scripts/seed-callback.js`
- **Promise:** `node scripts/seed-promise.js`
- **Async/Await:** `node scripts/seed-async.js`

### How it Works

- **Data Source:** Records are read from `scripts/seed.sql` and executed as a single SQL statement.
- **Database Client:** All scripts import a shared `pool` instance from `src/db/index.js` and connect via the `DATABASE_URL` environment variable.
- **Consistency:** Regardless of the execution pattern, all scripts populate the database with the exact same dataset.

### Database Maintenance

- **Cleanup:** Before re-testing scripts, use the following command to wipe data and reset ID counters:
  `TRUNCATE tasks RESTART IDENTITY;`
- **Auto-increment:** The `id` field is omitted from the INSERT statements; PostgreSQL handles it automatically via the `SERIAL` primary key.

### Implementation Notes

Each script demonstrates a different way to handle asynchronous I/O in Node.js, from traditional callbacks and Promises to modern async/await syntax, ensuring the critirea for identical database population is met across all versions.
