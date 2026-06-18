import { readFile } from "fs/promises";
import path from "path";
import pool from "../src/db/index.js";
import { handleFatalError } from "./helpers.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");

readFile(seedSqlPath, "utf8")
  .then((sql) => pool.query(sql))
  .finally(() =>
    pool
      .end()
      .catch(handleFatalError("Fatal error closing the database pool:")),
  )
  .catch(handleFatalError("Seeding failed:"));
