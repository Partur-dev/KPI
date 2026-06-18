import express from "express";
import morgan from "morgan";
import path from "path";

import { TaskRepo } from "./src/repositories/taskRepo.js";
import { TaskService } from "./src/services/taskService.js";
import { TaskController } from "./src/controllers/taskController.js";
import { ApiTaskController } from "./src/controllers/apiTaskController.js";

// Dependency injection composition root
const TASKS_PATH = path.join(import.meta.dirname, "data/tasks.json");

const taskRepo = new TaskRepo(TASKS_PATH);
const taskService = new TaskService(taskRepo);
const taskController = new TaskController(taskService);
const apiTaskController = new ApiTaskController(taskService);

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

// API Routes
app.get("/api/tasks", apiTaskController.getAll);
app.get("/api/tasks/:id", apiTaskController.getById);
app.post("/api/tasks", apiTaskController.create);
app.put("/api/tasks/:id", apiTaskController.update);
app.patch("/api/tasks/:id", apiTaskController.update);
app.delete("/api/tasks/:id", apiTaskController.delete);

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
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
