export class TaskController {
  #service;

  constructor(service) {
    this.#service = service;
  }

  getDashboard = async (_req, res, next) => {
    try {
      const tasks = await this.#service.fetchAllTasks();

      const sortBy = _req.query.sort;
      const currentOrder = _req.query.order || "asc";

      const displayTasks = sortBy
        ? this.#service.sortTasks(tasks, sortBy, currentOrder)
        : tasks;
      res.render("index", {
        page: "home",
        tasks: displayTasks,
        currentSort: sortBy,
        currentOrder: currentOrder,
      });
    } catch (error) {
      next(error);
    }
  };

  renderCreateForm = (_req, res) => {
    res.render("create", { page: "create" });
  };

  submitNewTask = async (req, res, next) => {
    try {
      await this.#service.createTask({
        title: req.body.title,
        date: req.body.date,
        priority: req.body.priority,
      });

      res.redirect(303, "/");
    } catch (error) {
      next(error);
    }
  };

  renderEditForm = async (req, res, next) => {
    try {
      const task = await this.#service.getTaskById(req.params.id);
      res.render("edit", { page: "edit", task });
    } catch (error) {
      next(error);
    }
  };

  submitUpdate = async (req, res, next) => {
    try {
      await this.#service.updateTaskData(req.params.id, {
        title: req.body.title,
        date: req.body.date,
        priority: req.body.priority,
        completed: req.body.completed,
      });

      res.redirect(303, "/");
    } catch (error) {
      next(error);
    }
  };

  toggleTaskStatus = async (req, res, next) => {
    try {
      await this.#service.flipCompletionStatus(req.params.id);
      res.redirect(303, "/");
    } catch (error) {
      next(error);
    }
  };

  deleteTask = (req, res, next) => {
    try {
      this.#service.removeTask(req.params.id);
      res.redirect(303, "/");
    } catch (error) {
      next(error);
    }
  };
}
