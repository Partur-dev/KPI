export class TaskService {
  #repo;

  constructor(repo) {
    this.#repo = repo;
  }

  async fetchAllTasks() {
    return this.#repo.getAll();
  }

  async fetchTaskById(id) {
    const task = await this.#repo.getById(id);
    if (!task) {
      const err = new Error(`Task with id ${id} not found`);
      err.status = 404;
      throw err;
    }
    return task;
  }

  async createTask(dto) {
    this.#validateTaskData(dto);

    const tasks = await this.#repo.getAll();
    const maxId = Array.isArray(tasks)
      ? tasks.reduce((max, task) => {
          const n = Number(task.id);
          return Number.isFinite(n) ? Math.max(max, n) : max;
        }, 0)
      : 0;

    const newTask = {
      id: String(maxId + 1),
      title: dto.title.trim(),
      date: dto.date,
      priority: dto.priority,
      completed: false,
    };

    await this.#repo.add(newTask);
    return newTask;
  }

  async updateTask(id, dto) {
    const existingTask = await this.fetchTaskById(id);

    const updates = {};
    if (dto.title !== undefined) {
      if (typeof dto.title !== "string" || !dto.title.trim()) {
        const err = new Error("Title must be a non-empty string");
        err.status = 400;
        throw err;
      }
      updates.title = dto.title.trim();
    }

    if (dto.date !== undefined) {
      if (
        !/^\d{4}-\d{2}-\d{2}$/.test(dto.date) ||
        Number.isNaN(Date.parse(dto.date))
      ) {
        const err = new Error("Date must be in YYYY-MM-DD format");
        err.status = 400;
        throw err;
      }
      updates.date = dto.date;
    }

    if (dto.priority !== undefined) {
      if (!["low", "medium", "high"].includes(dto.priority)) {
        const err = new Error("Priority must be low, medium, or high");
        err.status = 400;
        throw err;
      }
      updates.priority = dto.priority;
    }

    if (dto.completed !== undefined) {
      if (typeof dto.completed !== "boolean") {
        const err = new Error("Completed must be a boolean");
        err.status = 400;
        throw err;
      }
      updates.completed = dto.completed;
    }

    return this.#repo.update(id, updates);
  }

  async deleteTask(id) {
    const deleted = await this.#repo.delete(id);
    if (!deleted) {
      const err = new Error(`Task with id ${id} not found`);
      err.status = 404;
      throw err;
    }
  }

  #validateTaskData(dto) {
    const title = typeof dto?.title === "string" ? dto.title.trim() : "";
    const date = typeof dto?.date === "string" ? dto.date : "";
    const priority = typeof dto?.priority === "string" ? dto.priority : "";

    if (!title) {
      const err = new Error("Title is required");
      err.status = 400;
      throw err;
    }

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date))) {
      const err = new Error("Date must be in YYYY-MM-DD format");
      err.status = 400;
      throw err;
    }

    if (!["low", "medium", "high"].includes(priority)) {
      const err = new Error("Priority must be low, medium, or high");
      err.status = 400;
      throw err;
    }
  }

  sortTasks(tasks, criteria, order = "asc") {
    const sortedTasks = [...tasks];
    const modifier = order === "desc" ? -1 : 1;

    switch (criteria) {
      case "title":
        return sortedTasks.sort(
          (a, b) => a.title.localeCompare(b.title) * modifier,
        );
      case "date":
        return sortedTasks.sort(
          (a, b) => (new Date(a.date) - new Date(b.date)) * modifier,
        );
      case "priority":
        const priorityOrder = { low: 1, medium: 2, high: 3 };
        return sortedTasks.sort(
          (a, b) =>
            (priorityOrder[a.priority] - priorityOrder[b.priority]) * modifier,
        );
      case "status":
        return sortedTasks.sort(
          (a, b) =>
            (a.completed === b.completed ? 0 : a.completed ? 1 : -1) * modifier,
        );
      default:
        return sortedTasks;
    }
  }
}
