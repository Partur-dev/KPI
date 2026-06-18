import { readFile, writeFile } from "fs/promises";

export class TaskRepo {
  #tasksPath;

  constructor(tasksPath) {
    this.#tasksPath = tasksPath;
  }

  async getAll() {
    const data = await readFile(this.#tasksPath, "utf-8");
    return JSON.parse(data);
  }

  async getById(id) {
    const tasks = await this.getAll();
    return tasks.find((t) => t.id === id);
  }

  async add(task) {
    const tasks = await this.getAll();
    tasks.push(task);
    await writeFile(this.#tasksPath, JSON.stringify(tasks, null, 2) + "\n");
    return task;
  }

  async update(id, updates) {
    const tasks = await this.getAll();
    const index = tasks.findIndex((t) => t.id === id);
    if (index === -1) return null;

    tasks[index] = { ...tasks[index], ...updates };
    await writeFile(this.#tasksPath, JSON.stringify(tasks, null, 2) + "\n");
    return tasks[index];
  }

  async delete(id) {
    const tasks = await this.getAll();
    const filteredTasks = tasks.filter((t) => t.id !== id);
    if (tasks.length === filteredTasks.length) return false;

    await writeFile(
      this.#tasksPath,
      JSON.stringify(filteredTasks, null, 2) + "\n",
    );
    return true;
  }
}
