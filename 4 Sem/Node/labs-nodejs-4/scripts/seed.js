#!/usr/bin/env node
import fs from "fs";
import path from "path";
import pool from "../src/db/index.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");

(async () => {
  console.log("Running seed...");
  if (fs.existsSync(seedSqlPath)) {
    const sql = fs.readFileSync(seedSqlPath, "utf-8");
    try {
      await pool.query(sql);
      console.log("Seed executed successfully.");
    } catch (err) {
      console.error("Error executing seed:", err);
      process.exit(1);
    } finally {
      await pool.end();
    }
  } else {
    console.log(`No seed SQL found at ${seedSqlPath}`);
    process.exit(1);
  }
})();
