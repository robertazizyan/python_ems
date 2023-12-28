-- An employee can:
---- View his department staff
---- View his ACTIVE tasks AND change their status
---- View his ACTIVE projects
---- View his ACTIVE projects staff and current tasks


-- Show all employees belonging to a certain department
DELIMITER ::
CREATE PROCEDURE `get_department_staff` (IN `dep_id` INT)
BEGIN
    SELECT `id`, `name`, `email`, `position` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    WHERE `departments_employees`.`department_id` = dep_id
    ORDER BY `employees`.`name`;
END ::
DELIMITER ;

-- Show all ACTIVE tasks assigned to an employee with regard to their ACTIVE projects
DELIMITER ::
CREATE PROCEDURE `get_employee_tasks` (IN `empl_id` INT)
BEGIN
    SELECT 
        `tasks`.`id` AS `task_id`,
        `tasks`.`name` AS `task`, 
        `tasks`.`description` AS `description`, 
        `tasks`.`created` AS `created`, 
        `tasks`.`deadline` AS `deadline`,
        `tasks`.`status` AS `status`,
        `task_giver`.`name` AS `assigned_by`,
        `projects`.`name` AS `project`
    FROM `tasks`
    JOIN `employees_tasks` ON `tasks`.`id` = `employees_tasks`.`task_id`
    JOIN `employees` ON `employees_tasks`.`employee_id` = `employees`.`id`
    JOIN `employees` AS `task_giver` ON `employees_tasks`.`assigned_by` = `task_giver`.`id`
    JOIN `projects` ON `employees_tasks`.`project_related` = `projects`.`id`
    WHERE 
        `employees`.`id` = empl_id 
        AND `tasks`.`status` NOT IN ('Completed', 'Archived') 
        AND `projects`.`finish` > CURRENT_DATE
    ORDER BY `created`, `deadline`, `project`;
END ::
DELIMITER ;

-- Get all ACTIVE projects an employee is listed on
DELIMITER ::
CREATE PROCEDURE `get_employee_projects` (
    IN `empl_id` INT
)
BEGIN
    SELECT 
        `projects`.`id` AS `project_id`, 
        `projects`.`name` AS `project`, 
        `projects`.`description` AS `description`, 
        `projects_employees`.`role` AS `role` 
    FROM `projects`
    JOIN `projects_employees` ON `projects`.`id` = `projects_employees`.`project_id`
    JOIN `employees` ON `projects_employees`.`employee_id` = `employees`.`id`
    WHERE `employees`.`id` = empl_id AND `projects`.`finish` > CURRENT_DATE
    ORDER BY `projects`.`start`;
END ::
DELIMITER ;

-- Get project info
DELIMITER ::
CREATE PROCEDURE `get_project_info` (
    IN `pr_id` INT
)
BEGIN
    SELECT 
        `name`,
        `description`,
        `start`,
        `finish`
    FROM `projects`
    WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Show all employees assigned to a certain ACTIVE project
DELIMITER ::
CREATE PROCEDURE `get_project_staff` (IN `pr_id` INT)
BEGIN 
    SELECT 
        `employees`.`id` AS `employee_id`,
        `employees`.`name` AS `name`, 
        `employees`.`email` AS `email`, 
        `projects_employees`.`role` AS `role` 
    FROM `employees`
    JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    JOIN `projects` ON `projects_employees`.`project_id` = `projects`.`id`
    WHERE `projects_employees`.`project_id` = pr_id AND `projects`.`finish` > CURRENT_DATE
    ORDER BY `name`, `role`;
END ::
DELIMITER ;


-- Show all ACTIVE tasks related to a certain ACTIVE project
DELIMITER ::
CREATE PROCEDURE `get_project_tasks` (IN `pr_id` INT)
BEGIN
    SELECT 
        `tasks`.`id` AS `task_id`,
        `tasks`.`name` AS `name`, 
        `tasks`.`description` AS `description`, 
        `tasks`.`created` AS `created`, 
        `tasks`.`deadline` AS `deadline`,
        `employees`.`name` AS `employee`
    FROM `tasks`
    JOIN `employees_tasks` ON `tasks`.`id` = `employees_tasks`.`task_id`
    JOIN `employees` ON `employees_tasks`.`employee_id` = `employees`.`id`
    JOIN `projects` ON `employees_tasks`.`project_related` = `projects`.`id`
    WHERE 
        `employees_tasks`.`project_related` = pr_id 
        AND `tasks`.`status` NOT IN ('Completed', 'Archived') 
        AND `projects`.`finish` > CURRENT_DATE
    ORDER BY `created`, `deadline`, `name`;
END ::
DELIMITER ;

-- Change task status
DELIMITER ::
CREATE PROCEDURE `change_task_status` (
    IN `tsk_id` INT,
    IN `new_stat` VARCHAR(11)
)
BEGIN
    UPDATE `tasks` SET `status` = new_stat WHERE `id` = tsk_id;
END ::
DELIMITER ;



