export class ApiTaskController {
  #service;

  constructor(service) {
    this.#service = service;
  }

  getAll = async (_req, res, next) => {
    try {
      const tasks = await this.#service.fetchAllTasks();
      res.json(tasks);
    } catch (error) {
      next(error);
    }
  };

  getById = async (req, res, next) => {
    try {
      const task = await this.#service.fetchTaskById(req.params.id);
      res.json(task);
    } catch (error) {
      next(error);
    }
  };

  create = async (req, res, next) => {
    try {
      const newTask = await this.#service.createTask(req.body);
      res.status(201).json(newTask);
    } catch (error) {
      next(error);
    }
  };

  update = async (req, res, next) => {
    try {
      const updatedTask = await this.#service.updateTask(req.params.id, req.body);
      res.json(updatedTask);
    } catch (error) {
      next(error);
    }
  };

  delete = async (req, res, next) => {
    try {
      await this.#service.deleteTask(req.params.id);
      res.status(204).end();
    } catch (error) {
      next(error);
    }
  };
}
