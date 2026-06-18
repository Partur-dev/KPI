import {
  readFile as readFilePromise,
  writeFile as writeFilePromise,
} from "fs/promises";
import {
  readFile as readFileCallback,
  writeFile as writeFileCallback,
  readFileSync,
  writeFileSync,
} from "fs";

export class TaskRepo {
  #tasksPath;

  constructor(tasksPath) {
    this.#tasksPath = tasksPath;
  }

  async getAll() {
    const data = await readFilePromise(this.#tasksPath, "utf-8");
    return JSON.parse(data);
  }

  add(task) {
    return readFilePromise(this.#tasksPath, "utf-8")
      .then((data) => JSON.parse(data))
      .then((tasks) => {
        const nextTasks = Array.isArray(tasks) ? tasks : [];
        nextTasks.push(task);

        return writeFilePromise(
          this.#tasksPath,
          `${JSON.stringify(nextTasks, null, 2)}\n`,
        );
      })
      .then(() => task);
  }

  update(id, updates) {
    return new Promise((resolve, reject) => {
      readFileCallback(this.#tasksPath, "utf-8", (readError, rawData) => {
        if (readError) {
          reject(readError);
          return;
        }

        let tasks;
        try {
          tasks = JSON.parse(rawData);
        } catch (parseError) {
          reject(parseError);
          return;
        }

        if (!Array.isArray(tasks)) {
          tasks = [];
        }

        const index = tasks.findIndex((t) => t.id === id);
        if (index === -1) {
          resolve(null);
          return;
        }

        tasks[index] = { ...tasks[index], ...updates };

        writeFileCallback(
          this.#tasksPath,
          `${JSON.stringify(tasks, null, 2)}\n`,
          (writeError) => {
            if (writeError) {
              reject(writeError);
              return;
            }

            resolve(tasks[index]);
          },
        );
      });
    });
  }

  delete(id) {
    const raw = readFileSync(this.#tasksPath, "utf-8");
    const tasks = JSON.parse(raw);
    const filtered = tasks.filter((t) => t.id !== id);

    if (filtered.length === tasks.length) return null;

    writeFileSync(this.#tasksPath, `${JSON.stringify(filtered, null, 2)}\n`);
    return id;
  }
}
