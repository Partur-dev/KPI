/**
 * @typedef {Object} Task
 * @property {string} id
 * @property {string} title
 * @property {string} date
 * @property {'low'|'medium'|'high'} priority
 * @property {boolean} completed
 */

/**
 * @typedef {Object} CreateTaskDto
 * @property {string} title
 * @property {string} date
 * @property {'low'|'medium'|'high'} priority
 */

/**
 * @typedef {Object} UpdateTaskDto
 * @property {string} [title]
 * @property {string} [date]
 * @property {'low'|'medium'|'high'} [priority]
 */

/**
 * @typedef {Object} FilterTasksDto
 * @property {string} [date]
 * @property {'low'|'medium'|'high'} [priority]
 * @property {boolean} [completed]
 */

/**
 * @typedef {Object} DeleteTaskDto
 * @property {string} id
 */

export {};
