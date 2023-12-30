-- A manager of the project can:
---- Assign and de-assign an employee to the project AND change their role in the project
---- Work with tasks the same way as the department head, except can only give tasks related to his project


-- Assign an employee to the project
DELIMITER ::
CREATE PROCEDURE `add_employee_to_project` (
    IN `pr_id` INT,    
    IN `empl_id` INT,
    IN `empl_role` VARCHAR(100)
)
BEGIN
    INSERT INTO `projects_employees` (`project_id`, `employee_id`, `role`) VALUES (pr_id, empl_id, empl_role);
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

-- Get a project where you are the current project manager
DELIMITER ::
CREATE PROCEDURE `get_my_project_id` (
    IN `empl_id` INT
)
BEGIN
    SELECT `project_id` FROM `projects_employees`
    JOIN `projects` ON `projects`.`id` = `projects_employees`.`project_id`
    WHERE `employee_id` = empl_id 
    AND `projects`.`start` < CURRENT_DATE 
    AND `projects`.`finish` > CURRENT_DATE;
END ::
DELIMITER ;