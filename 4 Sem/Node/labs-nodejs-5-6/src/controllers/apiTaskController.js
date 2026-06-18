export class ApiTaskController {
  #service;

  constructor(service) {
    this.#service = service;
  }

  getAllTasks = async (_req, res, next) => {
    try {
      const tasks = await this.#service.fetchAllTasks();
      res.json(tasks);
    } catch (error) {
      next(error);
    }
  };

  getTask = async (req, res, next) => {
    try {
      const task = await this.#service.getTaskById(req.params.id);
      res.json(task);
    } catch (error) {
      next(error);
    }
  };

  createTask = async (req, res, next) => {
    try {
      const newTask = await this.#service.createTask(req.body);
      res.status(201).json(newTask);
    } catch (error) {
      next(error);
    }
  };

  updateTask = async (req, res, next) => {
    try {
      const updatedTask = await this.#service.updateTaskData(
        req.params.id,
        req.body,
      );
      res.json(updatedTask);
    } catch (error) {
      next(error);
    }
  };

  patchTask = async (req, res, next) => {
    try {
      const existingTask = await this.#service.getTaskById(req.params.id);
      const mergedTask = {
        title:
          req.body.title !== undefined ? req.body.title : existingTask.title,
        date: req.body.date !== undefined ? req.body.date : existingTask.date,
        priority:
          req.body.priority !== undefined
            ? req.body.priority
            : existingTask.priority,
        completed:
          req.body.completed !== undefined
            ? req.body.completed
            : existingTask.completed,
      };
      const updatedTask = await this.#service.updateTaskData(
        req.params.id,
        mergedTask,
      );
      res.json(updatedTask);
    } catch (error) {
      next(error);
    }
  };

  deleteTask = async (req, res, next) => {
    try {
      await this.#service.removeTask(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  };
}
