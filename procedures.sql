-- ALL VIEWING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------

-- Show all employees belonging to a certain department
DELIMITER ::
CREATE PROCEDURE `get_department_staff` (IN `dep_id` INT)
BEGIN
    SELECT `name`, `position`, `email` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    WHERE `departments_employees`.`department_id` = `dep_id`
    ORDER BY `employees`.`name`;
END ::
DELIMITER ;

-- Show all employees assigned to a certain project
DELIMITER ::
CREATE PROCEDURE `get_project_staff` (IN `pr_id` INT)
BEGIN 
    SELECT `employees`.`name` AS `name`, `departments`.`name` AS `department`, 
    `employees`.`email` AS `email`, `projects_employees`.`role` AS `role` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    JOIN `departments` ON `departments_employees`.`department_id` = `departments`.`id`
    JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    WHERE `projects_employees`.`project_id` = `pr_id`
    ORDER BY `department`, `role`;
END ::
DELIMITER ;

-- Show all tasks assigned to an employee with regard to their projects
DELIMITER ::
CREATE PROCEDURE `get_employee_tasks` (IN `empl_id` INT)
BEGIN
    SELECT `projects`.`name` as `project`, `tasks`.`name` AS `task`, `tasks`.`description` AS `description`, 
    `tasks`.`created` AS `created`, `tasks`.`deadline` AS `deadline`, `tasks`.`status` AS `status` FROM `employees`
    JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    JOIN `projects` ON `projects_employees`.`project_id` = `projects`.`id`
    JOIN `employees_tasks` ON `employees`.`id` = `employees_tasks`.`employee_id`
    JOIN `tasks` ON `employees_tasks`.`task_id` = `tasks`.`id`
    WHERE `employees`.`id` = `empl_id`
    ORDER BY `created`, `deadline`;
END ::

DELIMITER ;
-- Show all tasks related to a certain projects with the assigned employee
DELIMITER ::

CREATE PROCEDURE `get_project_tasks` (IN `pr_id` INT)
BEGIN
    SELECT `tasks`.`name` AS `name`, `tasks`.`description` AS `description`, `tasks`.`created` AS `created`, 
    `tasks`.`deadline` AS `deadline`,`employees`.`name` AS `employee`, `tasks`.`status` AS `status` FROM `tasks`
    JOIN `projects_tasks` ON `tasks`.`id` = `projects_tasks`.`task_id`
    JOIN `employees_tasks` ON `tasks`.`id` = `employees_tasks`.`task_id`
    JOIN `employees` ON `employees_tasks`.`employee_id` = `employees`.`id`
    WHERE `projects_tasks`.`project_id` = `pr_id`
    ORDER BY `created`, `deadline`, `name`;
END ::
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------------
-- ALL INSERTING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------
-- Add a new department


-- Add a new employee
