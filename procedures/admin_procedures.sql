-- An admin can:
---- Add, remove and alter data related to the departments, employees and projects

-- Add a new department
DELIMITER ::
CREATE PROCEDURE `add_department` (IN `dep_name` VARCHAR(100))
BEGIN
    INSERT INTO `departments` (`name`) VALUES (dep_name);
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

-- Add a new project
DELIMITER ::
CREATE PROCEDURE `add_project` (
    IN `pr_name` VARCHAR(100),
    IN `pr_desc` TEXT,
    IN `pr_start` DATE,
    IN `pr_finish` DATE
)
BEGIN
    INSERT INTO `projects` (`name`, `description`, `start`, `finish`) VALUES (pr_name, pr_desc, IFNULL(pr_start, NULL), IFNULL(pr_finish, NULL));
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
    UPDATE `employees` SET `is_head` = head WHERE `id` = empl_id;
END ::
DELIMITER ;

-- Change the is_manager state of the employee
DELIMITER ::
CREATE PROCEDURE `change_is_manager` (
    IN `empl_id` INT,
    IN `manager` TINYINT(1)
)
BEGIN
    UPDATE `employees` SET `is_manager` = manager WHERE `id` = empl_id;
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