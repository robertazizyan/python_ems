-- A head of the department can:
---- Create and re-assign tasks for the members of his department with NO regards to the project, remove those tasks and alter their status
---- View all active tasks assigned by him
---- Change the details of the task, such as name, description and deadline

-- Add a new task and assign it to an employee and a project(if present)
DELIMITER ::
CREATE PROCEDURE `add_task` (
    IN `task_name` VARCHAR(255),
    IN `task_desc` TEXT,
    IN `task_dl` DATETIME,
    IN `empl_id` INT,
    IN `assigned` INT,
    IN `pr_rel` INT
)
BEGIN
    DECLARE tsk_id INT;
    INSERT INTO `tasks` (`name`, `description`, `deadline`) VALUES (task_name, task_desc, task_dl);
    SET tsk_id := LAST_INSERT_ID();
    INSERT INTO `employees_tasks` (`employee_id`, `task_id`, `assigned_by`, `project_related`) VALUES (empl_id, tsk_id, assigned, IFNULL(pr_rel, NULL));
END ::
DELIMITER ;

-- Remove a task
DELIMITER ::
CREATE PROCEDURE `remove_task` (
    IN `task_id` INT
)
BEGIN
    DELETE FROM `tasks` WHERE `id` = task_id;
END ::
DELIMITER ;

-- Re-assign the task to a different employee
DELIMITER ::
CREATE PROCEDURE `reassign_task` (
    IN `tsk_id` INT,
    IN `new_empl_id` INT
)
BEGIN
    UPDATE `employees_tasks` SET `employee_id` = new_empl_id 
    WHERE `task_id` = tsk_id;
END ::
DELIMITER ;

-- Show all ACTIVE tasks assigned by the user
DELIMITER ::
CREATE PROCEDURE `get_tasks_assigned_by`(
    IN `empl_id` INT
)
BEGIN
    SELECT
        `tasks`.`id` AS `task_id`, 
        `tasks`.`name` AS `name`, 
        `tasks`.`description` AS `description`, 
        `tasks`.`created` AS `created`, 
        `tasks`.`deadline` AS `deadline`,
        `tasks`.`status` AS `status`,
        `employees`.`name` AS `employee`
    FROM `tasks`
    JOIN `employees_tasks` ON `tasks`.`id` = `employees_tasks`.`task_id`
    JOIN `employees` ON `employees_tasks`.`employee_id` = `employees`.`id`
    WHERE `tasks`.`status` NOT IN ('Completed', 'Archived') AND `employees_tasks`.`assigned_by` = empl_id
    ORDER BY `tasks`.`created`, `tasks`.`deadline`;
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