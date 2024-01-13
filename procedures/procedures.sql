--------------------------------------------------------------------------------------------------------------------------------
-- ALL APP PROCEDURES (Any stand-out queries that will be executed during when the web app is running)
--------------------------------------------------------------------------------------------------------------------------------
-- Check the employee credentials and return his data if he is present, otherwise return NULL
-- Procedure is called before logging in the user
DELIMITER ::
CREATE PROCEDURE `check_employee` (
    IN `empl_username` VARCHAR(100),
    IN `empl_password` VARCHAR(300)
)
BEGIN
    DECLARE empl_count INT;
    SELECT COUNT(*) INTO empl_count FROM `employees` WHERE `username` = empl_username AND `password` = empl_password;
    IF empl_count = 1 THEN
        SELECT `employees`.`id`, `employees`.`name`, `username`, `password`, `email`, `position`, `is_head`, `is_manager`, `is_admin`, `department_id`, `departments`.`name` FROM `employees`
        JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
        JOIN `departments` ON `departments_employees`.`department_id` = `departments`.`id`
        WHERE `username` = empl_username;
    END IF;
END ::
DELIMITER ;

-- Get employee statuses for a role assigning in a session
DELIMITER ::
CREATE PROCEDURE `set_role` (
    IN `empl_username` VARCHAR(100),
    IN `empl_password` VARCHAR(300)
)
BEGIN
    DECLARE s_head TINYINT(1);
    DECLARE s_manager TINYINT(1);
    DECLARE s_admin TINYINT(1);

    SELECT `is_head` INTO s_head FROM `employees`
    WHERE `username` = empl_username and `password` = empl_password;

    SELECT `is_manager` INTO s_manager FROM `employees`
    WHERE `username` = empl_username and `password` = empl_password;

    SELECT `is_admin` INTO s_admin FROM `employees`
    WHERE `username` = empl_username and `password` = empl_password;

    SELECT s_head, s_manager, s_admin;
END ::
DELIMITER ;