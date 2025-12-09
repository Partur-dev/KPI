import { Hono } from "hono";
import { serveStatic } from "@hono/node-server/serve-static";
import { serve } from "@hono/node-server";
import { db } from "./db.js";

const app = new Hono();

app.use("/*", serveStatic({ root: "./static" }));

app.get("/api/data", (c) => {
  return c.json(db.get());
});

app.post("/api/data", async (c) => {
  const newData = await c.req.json();
  await db.set(newData);
  return c.json({ status: "success" });
});

serve(app, (addr) => {
  console.log(`Server running at http://[${addr.address}]:${addr.port}/`);
});
