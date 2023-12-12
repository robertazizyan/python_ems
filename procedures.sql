-- ALL VIEWING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------

-- Show all employees belonging to a certain department
DELIMITER ::
CREATE PROCEDURE `get_department_staff` (IN `dep_name` VARCHAR(100))
BEGIN
    DECLARE dep_id INT;
    SELECT `id` INTO dep_id FROM `departments` WHERE `name` = dep_name;

    SELECT `name`, `position`, `email` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    WHERE `departments_employees`.`department_id` = dep_id
    ORDER BY `employees`.`name`;
END ::
DELIMITER ;

-- Show all employees assigned to a certain project
DELIMITER ::
CREATE PROCEDURE `get_project_staff` (IN `pr_name` VARCHAR(100))
BEGIN 
    DECLARE pr_id INT;
    SELECT `id` INTO pr_id FROM `projects` WHERE `name` = pr_name;

    SELECT `employees`.`name` AS `name`, `departments`.`name` AS `department`, 
    `employees`.`email` AS `email`, `projects_employees`.`role` AS `role` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    JOIN `departments` ON `departments_employees`.`department_id` = `departments`.`id`
    JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    WHERE `projects_employees`.`project_id` = pr_id
    ORDER BY `department`, `role`;
END ::
DELIMITER ;

-- Show all ACTIVE tasks assigned to an employee with regard to their projects
DELIMITER ::
CREATE PROCEDURE `get_employee_tasks` (IN `empl_name` VARCHAR(100))
BEGIN
    DECLARE empl_id INT;
    SELECT `id` INTO empl_id FROM `employees` WHERE `name` = empl_name;

    SELECT `projects`.`name` as `project`, `tasks`.`name` AS `task`, `tasks`.`description` AS `description`, 
    `tasks`.`created` AS `created`, `tasks`.`deadline` AS `deadline`, `tasks`.`status` AS `status` FROM `employees`
    JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    JOIN `projects` ON `projects_employees`.`project_id` = `projects`.`id`
    JOIN `employees_tasks` ON `employees`.`id` = `employees_tasks`.`employee_id`
    JOIN `tasks` ON `employees_tasks`.`task_id` = `tasks`.`id`
    WHERE `employees`.`id` = empl_id AND `tasks`.`status` != 'Completed'
    ORDER BY `created`, `deadline`;
END ::
DELIMITER ;

-- Show all ACTIVE tasks related to a certain project with the assigned employee
DELIMITER ::
CREATE PROCEDURE `get_project_tasks` (IN `pr_name` VARCHAR(100))
BEGIN
    DECLARE pr_id INT;
    SELECT `id` INTO pr_id FROM `projects` WHERE `name` = pr_name;

    SELECT `tasks`.`name` AS `name`, `tasks`.`description` AS `description`, `tasks`.`created` AS `created`, 
    `tasks`.`deadline` AS `deadline`,`employees`.`name` AS `employee`, `tasks`.`status` AS `status` FROM `tasks`
    JOIN `projects_tasks` ON `tasks`.`id` = `projects_tasks`.`task_id`
    JOIN `employees_tasks` ON `tasks`.`id` = `employees_tasks`.`task_id`
    JOIN `employees` ON `employees_tasks`.`employee_id` = `employees`.`id`
    WHERE `projects_tasks`.`project_id` = pr_id AND `tasks`.`status` != 'Completed'
    ORDER BY `created`, `deadline`, `name`;
END ::
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------------
-- ALL INSERTING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------
-- Add a new department
DELIMITER ::
CREATE PROCEDURE `add_department` (IN `dep_name` VARCHAR(100))
BEGIN
    INSERT INTO `departments` (`name`) VALUES (dep_name);
END ::
DELIMITER ;

-- Add a new employee
DELIMITER ::
CREATE PROCEDURE `add_employee` (
    IN `empl_name` VARCHAR(100), 
    IN `empl_username` VARCHAR(100), 
    IN `empl_password` VARCHAR(100), 
    IN `empl_email` VARCHAR(100), 
    IN `empl_position` VARCHAR(100), 
    IN `dep_name` VARCHAR(100),
    IN `head` TINYINT(1)
)
BEGIN
    INSERT INTO `employees` (`name`, `username`, `password`, `email`, `position`) VALUES (empl_name, empl_username, empl_password, empl_email, empl_position);
    
    SET @empl_id := LAST_INSERT_ID();

    DECLARE dep_id INT;
    SELECT `id` INTO dep_id FROM `departments` WHERE `name` = dep_name;

    INSERT INTO `employees_departments` (`department_id`, `employee_id`, `is_head`) VALUES (dep_id, @empl_id, head);
END ::
DELIMITER ;

-- Add a new project
DELIMITER ::
CREATE PROCEDURE `add_project` (
    IN `pr_name` VARCHAR(100),
    IN `pr_desc` VARCHAR(100),
    IN `pr_start` DATE,
    IN `pr_finish` DATE
)
BEGIN
    INSERT INTO `projects` (`name`, `description`, `start`, `finish`) VALUES (pr_name, pr_description, IFNULL(pr_start, NULL), IFNULL(pr_finish, NULL));
END ::
DELIMITER ;

-- Assign an employee to the project
DELIMITER ::
CREATE PROCEDURE `add_employee_to_project` (
    IN `empl_name` VARCHAR(100),
    IN `pr_name` VARCHAR(100),
    IN `empl_role` VARCHAR(100),
)
BEGIN
    DECLARE pr_id INT;
    SELECT `id` INTO pr_id FROM `projects` WHERE `name` = `pr_name`;

    DECLARE empl_id INT;
    SELECT `id` INTO empl_id FROM `employees` WHERE `name` = `empl_name`;

    INSERT INTO `projects_employees` (`project_id`, `employee_id`, `role`) VALUES (pr_id, empl_id, empl_role);
END ::
DELIMITER ;

-- Add a new task to the project and assign it to an employee
DELIMITER ::
CREATE PROCEDURE `add_task` (
    IN `task_name` VARCHAR(100),
    IN `task_desc` VARCHAR(100),
    IN `task_dl` DATETIME,
    IN `pr_name` VARCHAR(100),
    IN `empl_name` VARCHAR(100),
)
BEGIN
    INSERT INTO `tasks` (`name`, `description`, `deadline`) VALUES (task_name, task_desc, task_dl);

    SET @tsk_id := LAST_INSERT_ID();

    DECLARE pr_id INT;
    SELECT `id` INTO pr_id FROM `projects` WHERE `name` = pr_name;

    INSERT INTO `projects_tasks` (`project_id`, `task_id`) VALUES (pr_id, tsk_id);

    DECLARE empl_id INT;
    SELECT `id` INTO empl_id FROM `employees` WHERE `name` = empl_name;

    INSERT INTO `employees_tasks` (`employee_id`, `task_id`) VALUES (empl_id, tsk_id);
END ::
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------------
-- ALL ALTERING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------
