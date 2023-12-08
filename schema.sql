CREATE TABLE IF NOT EXISTS `companies` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `departments` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `company_id` INT,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `companies_departments` (
    `id` INT AUTO_INCREMENT,
    `company_id` INT,
    `department_id` INT,
    FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `employees` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `username` VARCHAR(255) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `position` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`), 
);

CREATE TABLE IF NOT EXISTS `departments_employees` (
    `id` INT AUTO_INCREMENT,
    `department_id` INT,
    `employee_id` INT,
    FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `projects` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `start` DATE NOT NULL DEFAULT CURRENT_DATE,
    `finish` DATE DEFAULT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `companies_projects` (
    `id` INT AUTO_INCREMENT,
    `company_id` INT,
    `project_id` INT,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `projects_employees` (
    `id` INT AUTO_INCREMENT,
    `project_id` INT,
    `employee_id` INT,
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `tasks` (
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status` ENUM(`Pending`, `In progress`, `On review`, `Completed`) NOT NULL DEFAULT 'Pending',
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