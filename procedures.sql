-- ALL VIEWING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------

-- Show all employees belonging to a certain department
DELIMITER ::
CREATE PROCEDURE `get_department_staff` (IN `dep_id` INT)
BEGIN
    SELECT `name`, `position`, `email` FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    WHERE `departments_employees`.`department_id` = dep_id
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
    WHERE `projects_employees`.`project_id` = pr_id
    ORDER BY `department`, `role`;
END ::
DELIMITER ;

-- Show all ACTIVE tasks assigned to an employee with regard to their projects
DELIMITER ::
CREATE PROCEDURE `get_employee_tasks` (IN `empl_id` INT)
BEGIN
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
CREATE PROCEDURE `get_project_tasks` (IN `pr_id` INT)
BEGIN
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
    IN `pr_desc` TEXT,
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
    IN `task_name` VARCHAR(255),
    IN `task_desc` TEXT,
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
-- ALL DELETING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------
-- Remove a department
DELIMITER ::
CREATE PROCEDURE `remove_department` (IN `dep_id` INT)
BEGIN
    DELETE FROM `departments` WHERE `id` = dep_id;
END ::
DELIMITER ;

-- Remove an employee
DELIMITER ::
CREATE PROCEDURE `remove_employee` (IN `empl_id` INT)
BEGIN
    DELETE FROM `employees` WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Remove a project
DELIMITER ::
CREATE PROCEDURE `remove_project` (IN `pr_id` INT)
BEGIN
    DELETE FROM `projects` WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Remove a task
DELIMITER ::
CREATE PROCEDURE `remove_task` (IN `task_id` INT)
BEGIN
    DELETE FROM `tasks` WHERE `id` = task_id;
END ::
DELIMITER ;

-- De-assign an employee from a project
DELIMITER ::
CREATE PROCEDURE `deassign_employee` (
    IN `pr_id` INT,
    IN `empl_id` INT
)
BEGIN
    DELETE FROM `projects_employees` 
    WHERE `project_id` = pr_id AND `employee_id` = empl_id;
END ::
DELIMITER ;

-- De-assign a task from an employee
DELIMITER ::
CREATE PROCEDURE `deassign_task` (
    IN `tsk_id` INT,
    IN `empl_id` INT
)
BEGIN
    DELETE FROM `employees_tasks` 
    WHERE `employee_id` = empl_id AND `task_id` = tsk_id;
END ::
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------------
-- ALL UPDATING PROCEDURES
--------------------------------------------------------------------------------------------------------------------------------
-- Change department data
DELIMITER ::
CREATE PROCEDURE `change_department` (IN `dep_id` INT, `new_dep_name` VARCHAR(100))
BEGIN
    UPDATE `departments` UPDATE `name` = new_dep_name WHERE `id` = dep_id;
END ::
DELIMITER ;


-- Change employee name
DELIMITER ::
CREATE PROCEDURE `change_employee_name` (
    IN `empl_id` INT,
    IN `empl_name` VARCHAR(255),
)
BEGIN
    UPDATE `employees` SET `name` = empl_name WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee username
DELIMITER ::
CREATE PROCEDURE `change_employee_username` (
    IN `empl_id` INT,
    IN `empl_username` VARCHAR(100),
)
BEGIN
    UPDATE `employees` SET `username` = empl_username WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee password
DELIMITER ::
CREATE PROCEDURE `change_employee_password` (
    IN `empl_id` INT,
    IN `empl_password` VARCHAR(100)
)
BEGIN
    UPDATE `employees` SET `password` = empl_password WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee email
DELIMITER ::
CREATE PROCEDURE `change_employee_email` (
    IN `empl_id` INT,
    IN `empl_email` VARCHAR(100),
)
BEGIN
    UPDATE `employees` SET `email` = empl_email WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee position
DELIMITER ::
CREATE PROCEDURE `change_employee_position` (
    IN `empl_id` INT,
    IN `empl_pos` VARCHAR(100)
)
BEGIN
    UPDATE `employees` SET `position` = empl_pos WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee department
DELIMITER ::
CREATE PROCEDURE `change_employee_department` (
    IN `empl_id` INT,
    IN `dep_id` INT
)
BEGIN
    UPDATE `departments_employees` SET `department_id` = dep_id WHERE `employee_id` = empl_id;
END ::
DELIMITER ;

-- Change project name
DELIMITER ::
CREATE PROCEDURE `change_project_name` (
    IN `pr_id` INT, 
    IN `pr_name` VARCHAR(100)
)
BEGIN
    UPDATE `projects` SET `name` = pr_name WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Change project description
DELIMITER ::
CREATE PROCEDURE `change_project_description` (
    IN `pr_id` INT, 
    IN `pr_desc` TEXT
)
BEGIN
    UPDATE `projects` SET `description` = pr_desc WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Change project finish
DELIMITER ::
CREATE PROCEDURE `change_project_finish` (
    IN `pr_id` INT,
    IN `pr_finish` DATE
)
BEGIN
    UPDATE `projects` SET `finish` = pr_finish WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Change an employee role in a project
DELIMITER ::
CREATE PROCEDURE `change_employee_role` (
    IN `empl_id` INT, 
    IN `pr_id` INT,
    IN `new_role` VARCHAR(100)
)
BEGIN
    UPDATE `projects_employees` SET `role` = new_role 
    WHERE `project_id` = pr_id AND `employee_id` = empl_id;
END ::
DELIMITER ;

-- Change task name
DELIMITER ::
CREATE PROCEDURE `change_task_name` (
    IN `tsk_id` INT,
    IN `new_task_name` VARCHAR(255)
)
BEGIN
    UPDATE `tasks` SET `name` = new_task_name WHERE `id` = tsk_id;
END ::
DELIMITER ;

-- Change task description
DELIMITER ::
CREATE PROCEDURE `change_task_description` (
    IN `tsk_id` INT,
    IN `tsk_desc` TEXT
)
BEGIN
    UPDATE `tasks` SET `description` = tsk_desc WHERE `id` = tsk_id;
END ::
DELIMITER ;

-- Change task deadline
DELIMITER ::
CREATE PROCEDURE `change_task_deadline` (
    IN `tsk_id` INT,
    IN `tsk_dl` DATETIME
)
BEGIN
    UPDATE `tasks` SET `deadline` = tsk_dl WHERE `id` = tsk_id;
END ::
DELIMITER ;

-- Change task status
CREATE PROCEDURE `change_task_status` (
    IN `tsk_id` INT,
    IN `new_stat` VARCHAR(11)
)
BEGIN
    UPDATE `tasks` SET `status` = new_stat WHERE `id` = tsk_id;
END ::
DELIMITER ;

-- Re-assign the task to an employee
DELIMITER ::
CREATE PROCEDURE `reassign_task` (
    IN `old_empl_id` INT,
    IN `tsk_id` INT,
    IN `new_empl_id` INT
)
BEGIN
    UPDATE `employees_tasks` SET `employee_id` = new_empl_id 
    WHERE `employee_id` = old_employee_id AND `task_id` = tsk_id;
END ::
DELIMITER ;