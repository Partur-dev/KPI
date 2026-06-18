#!/usr/bin/env node
import fs from "fs";
import path from "path";
import pool from "../src/db/index.js";

const cmd = process.argv[2] || "up";
const migrationsDir = path.resolve("migrations");

function getMigrations(suffix) {
  if (!fs.existsSync(migrationsDir)) return [];
  return fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith(suffix))
    .sort();
}

async function runSqlFile(filePath) {
  const sql = fs.readFileSync(filePath, "utf-8");
  try {
    await pool.query(sql);
    console.log(`Executed: ${path.basename(filePath)}`);
  } catch (err) {
    console.error(`Error executing ${path.basename(filePath)}:`, err);
    throw err;
  }
}

(async () => {
  try {
    if (cmd === "up") {
      console.log("MIGRATE UP");
      const list = getMigrations(".up.sql");
      for (const f of list) await runSqlFile(path.join(migrationsDir, f));
    } else if (cmd === "down") {
      console.log("MIGRATE DOWN");
      const list = getMigrations(".down.sql").slice().reverse();
      for (const f of list) await runSqlFile(path.join(migrationsDir, f));
    } else if (cmd === "refresh") {
      console.log("MIGRATE REFRESH");
      const downList = getMigrations(".down.sql").slice().reverse();
      for (const f of downList) await runSqlFile(path.join(migrationsDir, f));
      const upList = getMigrations(".up.sql");
      for (const f of upList) await runSqlFile(path.join(migrationsDir, f));
    } else {
      console.error("Unknown command", cmd);
      process.exit(2);
    }
  } catch (e) {
    console.error(e);
    process.exit(1);
  } finally {
    await pool.end();
  }
})();
