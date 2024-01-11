-- An admin can:
---- Add, remove and alter data related to the departments, employees and projects

-- Add a new department
DELIMITER ::
CREATE PROCEDURE `add_department` (IN `dep_name` VARCHAR(100))
BEGIN
    INSERT INTO `departments` (`name`) VALUES (dep_name);
END ::
DELIMITER ;

-- Get all departments names and ids
DELIMITER ::
CREATE PROCEDURE `admin_get_departments` ()
BEGIN
    SELECT * FROM `departments`
    ORDER BY `name`;
END ::
DELIMITER ;

-- Get all employees data for modification
DELIMITER ::
CREATE PROCEDURE `admin_get_employees` ()
BEGIN
    SELECT `employees`.`id`, 
        `employees`.`name`, 
        `username`, 
        `password`, 
        `email`, 
        `position`,
        `is_head`,
        `is_manager`,
        `is_admin`,
        `departments_employees`.`department_id` AS `department_id`,
        `departments`.`name` AS `department_name`
    FROM `employees`
    JOIN `departments_employees` ON `employees`.`id` = `departments_employees`.`employee_id`
    JOIN `departments` ON `departments_employees`.`department_id` = `departments`.`id`
    ORDER BY `employees`.`name`;
END ::
DELIMITER ;

-- Get project data for modification
DELIMITER ::
CREATE PROCEDURE `admin_get_projects` ()
BEGIN
    SELECT
        `projects`.`id`,
        `projects`.`name`,
        `projects`.`description`,
        `projects`.`start`,
        `projects`.`finish`,
        `employees`.`id` AS `project_manager_id`,
        `employees`.`name` AS `project_manager_name`
    FROM `projects`
    LEFT JOIN `projects_employees` ON `projects`.`id` = `projects_employees`.`project_id` AND `projects_employees`.`role` = 'Project Manager'
    LEFT JOIN `employees` ON `projects_employees`.`employee_id` = `employees`.`id`;
END ::
DELIMITER ;

-- Add a new employee an create a user with the specified role based on the is_head,is_manager,is_admin
DELIMITER ::
CREATE PROCEDURE `add_employee` (
    IN `empl_name` VARCHAR(100), 
    IN `empl_username` VARCHAR(100), 
    IN `empl_password` VARCHAR(300), 
    IN `empl_email` VARCHAR(100), 
    IN `empl_position` VARCHAR(100), 
    IN `dep_id` INT,
    IN `head` TINYINT(1),
    IN `manager` TINYINT(1),
    IN `s_admin` TINYINT(1)
)
BEGIN
    -- Add employee to the employees table
    INSERT INTO `employees` (
        `name`, 
        `username`, 
        `password`, 
        `email`, 
        `position`, 
        `is_head`, 
        `is_manager`, 
        `is_admin`
    ) 
    VALUES (
        empl_name, 
        empl_username, 
        empl_password, 
        empl_email, 
        empl_position, 
        head, 
        manager, 
        s_admin
    );
    
    -- Get the employee ID
    SET @empl_id := LAST_INSERT_ID();

    -- Associate employee with the specified department
    INSERT INTO `departments_employees` (`department_id`, `employee_id`) VALUES (dep_id, @empl_id);

    -- Create the user in the database
    SET @sql := CONCAT('CREATE USER ''', empl_username, '''@''%'' IDENTIFIED BY ''', empl_password, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    CALL `grant_options`(empl_username, head, manager, s_admin);

END ::
DELIMITER ;

-- Grant rights to an employee based on his type
DELIMITER ::
CREATE PROCEDURE `grant_options` (
    IN empl_username VARCHAR(100),
    IN is_head TINYINT(1),
    IN is_manager TINYINT(1),
    IN is_admin TINYINT(1)    
)
BEGIN
    SET @grant_sql = CONCAT('GRANT SELECT, EXECUTE ON `ems`.* TO ''', empl_username, '''@''%''');
    PREPARE stmt FROM @grant_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    FLUSH PRIVILEGES;

    IF is_head = 1 THEN
        SET @grant_sql = CONCAT('GRANT CREATE, UPDATE, DELETE ON `ems`.`tasks` TO ''', empl_username, '''@''%''');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @grant_sql = CONCAT('GRANT CREATE, UPDATE, DELETE ON `ems`.`employees_tasks` TO ''', empl_username, '''@''%''');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF is_manager = 1 THEN
        SET @grant_sql = CONCAT('GRANT CREATE, UPDATE, DELETE ON `ems`.`tasks` TO ''', empl_username, '''@''%''');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @grant_sql = CONCAT('GRANT CREATE, UPDATE, DELETE ON `ems`.`employees_tasks` TO ''', empl_username, '''@''%''');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        SET @grant_sql = CONCAT('GRANT CREATE, UPDATE, DELETE ON `ems`.`projects_employees` TO ''', empl_username, '''@''%''');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF is_admin = 1 THEN
        SET @grant_sql = CONCAT('GRANT ALL PRIVILEGES ON `ems`.* TO ''', empl_username, '''@''%'' WITH GRANT OPTION');
        PREPARE stmt FROM @grant_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    FLUSH PRIVILEGES;        
END ::
DELIMITER ;

-- Get a list of employees with ids and names who are eligible for a project manager role (and don't currently have any projects)
DELIMITER ::
CREATE PROCEDURE `get_project_managers` ()
BEGIN
    SELECT `id`, `name` FROM `employees`
    LEFT JOIN `projects_employees` ON `employees`.`id` = `projects_employees`.`employee_id`
    WHERE `position` LIKE '%manager' 
    AND NOT EXISTS (
        SELECT 1
        FROM `projects_employees`
        WHERE `employees`.`id` = `projects_employees`.`employee_id`
    )
    ORDER BY `name`;
END ::
DELIMITER ;

-- Add a new project and assign its project manager
DELIMITER ::
CREATE PROCEDURE `add_project` (
    IN `pr_name` VARCHAR(100),
    IN `pr_desc` TEXT,
    IN `pr_start` DATE,
    IN `pr_finish` DATE,
    IN `pm_id` INT
)
BEGIN
    DECLARE pm_username VARCHAR(100);

    INSERT INTO `projects` (`name`, `description`, `start`, `finish`) VALUES (pr_name, pr_desc, IFNULL(pr_start, NULL), IFNULL(pr_finish, NULL));

    IF pm_id IS NOT NULL THEN
        SET @pr_id := LAST_INSERT_ID();
        INSERT INTO `projects_employees` (`project_id`, `employee_id`, `role`) VALUES (@pr_id, pm_id, 'Project Manager');

        UPDATE `employees` SET `is_manager` = 1 WHERE `id` = pm_id;

        SELECT `username` INTO pm_username FROM `employees` WHERE `id` = pm_id;

        CALL `grant_options`(pm_username, 0, 1, 0);

    END IF;

END ::
DELIMITER ;

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
    DECLARE empl_username VARCHAR(100);

    SELECT `username` INTO empl_username FROM `employees` WHERE `id` = empl_id;

    DELETE FROM `employees` WHERE `id` = empl_id;

    SET @sql := CONCAT('DROP USER ''', empl_username, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END ::
DELIMITER ;

-- Remove a project
DELIMITER ::
CREATE PROCEDURE `remove_project` (IN `pr_id` INT)
BEGIN
    DELETE FROM `projects` WHERE `id` = pr_id;
END ::
DELIMITER ;

-- Change department data
DELIMITER ::
CREATE PROCEDURE `change_department` (IN `dep_id` INT, 
`new_dep_name` VARCHAR(100)
)
BEGIN
    UPDATE `departments` SET `name` = new_dep_name WHERE `id` = dep_id;
END ::
DELIMITER ;


-- Change employee name
DELIMITER ::
CREATE PROCEDURE `change_employee_name` (
    IN `empl_id` INT,
    IN `empl_name` VARCHAR(255)
)
BEGIN
    UPDATE `employees` SET `name` = empl_name WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee username
DELIMITER ::
CREATE PROCEDURE `change_employee_username` (
    IN `empl_id` INT,
    IN `empl_username` VARCHAR(100)
)
BEGIN
    UPDATE `employees` SET `username` = empl_username WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee password
DELIMITER ::
CREATE PROCEDURE `change_employee_password` (
    IN `empl_id` INT,
    IN `empl_password` VARCHAR(300)
)
BEGIN
    UPDATE `employees` SET `password` = empl_password WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change employee email
DELIMITER ::
CREATE PROCEDURE `change_employee_email` (
    IN `empl_id` INT,
    IN `empl_email` VARCHAR(100)
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

-- Change the is_head of the department state of the employee
DELIMITER ::
CREATE PROCEDURE `change_is_head` (
    IN `empl_id` INT,
    IN `head` TINYINT(1)
)
BEGIN
    DECLARE empl_username VARCHAR(100);
    DECLARE manager TINYINT(1);
    DECLARE s_admin TINYINT(1);
    
    UPDATE `employees` SET `is_head` = head WHERE `id` = empl_id;

    SELECT `username` INTO empl_username FROM `employees` WHERE `id` = empl_id;
    SELECT `is_manager` INTO manager FROM `employees` WHERE `id` = empl_id;
    SELECT `is_admin` INTO s_admin FROM `employees` WHERE `id` = empl_id;   
END ::
DELIMITER ;

-- Change the is_manager state of the employee
DELIMITER ::
CREATE PROCEDURE `change_is_manager` (
    IN `empl_id` INT,
    IN `manager` TINYINT(1)
)
BEGIN
    DECLARE empl_username VARCHAR(100);
    DECLARE head TINYINT(1);
    DECLARE s_admin TINYINT(1);
    
    UPDATE `employees` SET `is_manager` = manager WHERE `id` = empl_id;

    SELECT `username` INTO empl_username FROM `employees` WHERE `id` = empl_id;
    SELECT `is_head` INTO head FROM `employees` WHERE `id` = empl_id;
    SELECT `is_admin` INTO s_admin FROM `employees` WHERE `id` = empl_id;

    CALL `grant_options`(empl_username, head, manager, s_admin);
END ::
DELIMITER ;

-- Change the is_admin state of the employee
DELIMITER ::
CREATE PROCEDURE `change_is_admin` (
    IN `empl_id` INT,
    IN `s_admin` TINYINT(1)
)
BEGIN
    DECLARE empl_username VARCHAR(100);
    DECLARE head TINYINT(1);
    DECLARE manager TINYINT(1);
    
    UPDATE `employees` SET `is_admin` = s_admin WHERE `id` = empl_id;

    SELECT `username` INTO empl_username FROM `employees` WHERE `id` = empl_id;
    SELECT `is_head` INTO head FROM `employees` WHERE `id` = empl_id;
    SELECT `is_manager` INTO manager FROM `employees` WHERE `id` = empl_id;

    CALL `grant_options`(empl_username, head, manager, s_admin);
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

-- Change project start
DELIMITER ::
CREATE PROCEDURE `change_project_start` (
    IN `pr_id` INT,
    IN `pr_start` DATE
)
BEGIN
    UPDATE `projects` SET `start` = pr_start WHERE `id` = pr_id;
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

--  Change project manager
DELIMITER ::
CREATE PROCEDURE `change_project_manager` (
    IN `pr_id` INT,
    IN `empl_id` INT
)
BEGIN
    UPDATE `projects_employees` SET `employee_id` = empl_id WHERE `project_id` = pr_id;
END ::
DELIMITER ;