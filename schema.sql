CREATE TABLE IF NOT EXISTS `employees` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `username` VARCHAR(100) NOT NULL,
    `password` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `position` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`), 
);

CREATE TABLE IF NOT EXISTS `departments` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`head_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `departments_employees` (
    `id` INT AUTO_INCREMENT,
    `department_id` INT,
    `employee_id` INT,
    `is_head` TINYINT(1) NOT NULL,
    FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `projects` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `start` DATE NOT NULL DEFAULT CURRENT_DATE,
    `finish` DATE DEFAULT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `projects_employees` (
    `id` INT AUTO_INCREMENT,
    `project_id` INT,
    `employee_id` INT,
    `role` VARCHAR(100) NOT NULL,
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `tasks` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deadline` DATETIME DEFAULT NULL,
    `status` ENUM(`Pending`, `In progress`, `Completed`) NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (`id`),
);

CREATE TABLE IF NOT EXISTS `projects_tasks` (
    `id` INT AUTO_INCREMENT,
    `project_id` INT,
    `task_id` INT,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `employees_tasks` (
    `id` INT AUTO_INCREMENT,
    `employee_id` INT,
    `task_id` INT,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE
);