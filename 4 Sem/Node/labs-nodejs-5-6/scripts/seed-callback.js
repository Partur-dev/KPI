import fs from "fs";
import path from "path";
import pool from "../src/db/index.js";
import { handleFatalError } from "./helpers.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");

fs.readFile(seedSqlPath, "utf8", (err, sql) => {
  if (err) handleFatalError("Failed to read file:")(err);

  pool.query(sql, (err) => {
    if (err) handleFatalError("Failed to execute seed:")(err);
    pool
      .end()
      .catch(handleFatalError("Fatal error closing the database pool:"));
  });
});
