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