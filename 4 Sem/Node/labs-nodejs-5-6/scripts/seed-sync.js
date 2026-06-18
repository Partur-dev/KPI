import fs from "fs";
import path from "path";
import pool from "../src/db/index.js";
import { handleFatalError } from "./helpers.js";

const seedSqlPath = path.resolve("scripts", "seed.sql");
const sql = fs.readFileSync(seedSqlPath, "utf8");

pool
  .query(sql)
  .catch(handleFatalError("Failed to execute seed:"))
  .finally(() =>
    pool
      .end()
      .catch(handleFatalError("Fatal error closing the database pool:")),
  );
