import express from "express";
import morgan from "morgan";
import path from "path";

import { TaskRepo } from "./src/repositories/taskRepo.js";
import { TaskService } from "./src/services/taskService.js";
import { TaskController } from "./src/controllers/taskController.js";

// Dependency injection composition root
const TASKS_PATH = path.join(import.meta.dirname, "data/tasks.json");

const taskRepo = new TaskRepo(TASKS_PATH);
const taskService = new TaskService(taskRepo);
const taskController = new TaskController(taskService);

const app = express();

app.use("/fonts/geist", express.static("node_modules/geist/dist/fonts"));
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static("public"));

app.set("view engine", "ejs");
app.set("views", path.join(import.meta.dirname, "src/views"));

app.get("/", taskController.getDashboard);

app.get("/tasks/new", taskController.renderCreateForm);
app.post("/tasks", taskController.submitNewTask);
app.get("/tasks/:id/edit", taskController.renderEditForm);
app.post("/tasks/:id/update", taskController.submitUpdate);
app.post("/tasks/:id/toggle", taskController.toggleTaskStatus);
app.post("/tasks/:id/delete", taskController.deleteTask);

app.use((_req, res) => {
  res.status(404).sendFile(path.join(import.meta.dirname, "public/404.html"));
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res
    .status(err.status || 500)
    .json({ error: err.message || "Internal server error" });
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

const shutdown = (signal) => {
  return (err) => {
    if (err) {
      console.error(`${signal} received with error:`, err);
    } else {
      console.log(`${signal} received, shutting down gracefully.`);
    }

    // Stop accepting new connections
    server.close((closeErr) => {
      if (closeErr) {
        console.error("Error during server close", closeErr);
        process.exit(1);
      }
      console.log("Closed remaining connections, exiting.");
      process.exit(0);
    });

    // Force exit if shutdown takes too long
    setTimeout(() => {
      console.warn("Forcing shutdown due to timeout.");
      process.exit(1);
    }, 10000).unref();
  };
};

process.on("SIGTERM", shutdown("SIGTERM"));
process.on("SIGINT", shutdown("SIGINT"));
process.on("uncaughtException", (err) => {
  console.error("Uncaught Exception:", err);
  shutdown("uncaughtException")(err);
});
process.on("unhandledRejection", (reason) => {
  console.error("Unhandled Rejection:", reason);
  shutdown("unhandledRejection")(reason);
});
