import { readFile } from "fs/promises";
import path from "path";
import pool from "../src/db/index.js";
import { handleFatalError } from "./helpers.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");

async function runSeeder() {
  try {
    const sql = await readFile(seedSqlPath, "utf8");
    await pool.query(sql);
  } catch (err) {
    handleFatalError("Seeding failed:")(err);
  } finally {
    await pool
      .end()
      .catch(handleFatalError("Fatal error closing the database pool:"));
  }
}

runSeeder();
