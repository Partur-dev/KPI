# CI & Migration Notes

This project includes hypothetical helpers and CI configuration for running migrations and seeding in CI.

Local usage

- Apply migrations: `npm run migrate:up`
- Revert migrations: `npm run migrate:down`
- Refresh (down+up): `npm run migrate:refresh`
- Run seed script: `npm run seed`

How it works (hypothetical)

- `scripts/migrate.js` scans the `migrations/` folder for `*.sql` files and prints the commands it would run. Adapt this script to call your DB client (`psql`, `mysql`, etc.) or use a migration tool.
- `scripts/seed.js` looks for `scripts/seed.sql` or can be replaced with a real Node seeder.

CI notes

- The workflow is defined in `.github/workflows/ci.yml` and runs `npm run migrate:up` and `npm run seed` before `npm test`.
- Configure your database connection in CI via the `DATABASE_URL` secret (used as `DB_URL` env var in the workflow).

Customization

- Replace the `(hypothetical)` commands inside `scripts/*.js` with real commands for your database client.
- If you use a specific migration library (eg. `knex`, `sequelize-cli`, `migrate`), wire the npm scripts to that tool instead.
