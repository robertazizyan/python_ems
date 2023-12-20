--------------------------------------------------------------------------------------------------------------------------------
-- ALL APP PROCEDURES (Any stand-out queries that will be executed during when the web app is running)
--------------------------------------------------------------------------------------------------------------------------------
-- Check the employee credentials and return his data if he is present, otherwise return NULL
-- Procedure is called before logging in the user
DELIMITER ::
CREATE PROCEDURE `check_employee` (
    IN `empl_username` VARCHAR(100),
    IN `empl_password` VARCHAR(100),
    OUT `res` TINYINT(1)
)
BEGIN
    DECLARE empl_count INT;
    SELECT COUNT(*) INTO empl_count FROM `employees` WHERE `username` = empl_username AND `password` = empl_password;
    IF empl_count = 1 THEN
        SELECT `id`, `employees`.`name`, `username`, `password`, `email`, `position`, `is_head`, `is_manager`, `is_admin`, `department_id`, `departments`.`name` INTO `res` FROM `employees`
        JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
        JOIN `departments` ON `departments_employees`.`department_id` = `departments`.`id`
        WHERE `username` = empl_username AND `password` = empl_password;
    ELSE
        SET res = NULL;
    END IF;
END ::
DELIMITER ;