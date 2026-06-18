#!/usr/bin/env node
import fs from "fs";
import path from "path";
import pool from "../src/db/index.js";
import { handleFatalError } from "./helpers.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");

(async () => {
  console.log("Running seed...");
  if (fs.existsSync(seedSqlPath)) {
    const sql = fs.readFileSync(seedSqlPath, "utf-8");
    try {
      await pool.query(sql);
      console.log("Seed executed successfully.");
    } catch (err) {
      handleFatalError("Error executing seed:")(err);
    } finally {
      await pool
        .end()
        .catch(handleFatalError("Fatal error closing the database pool:"));
    }
  } else {
    console.log(`No seed SQL found at ${seedSqlPath}`);
    process.exit(1);
  }
})();
