CREATE ROLE employee;
GRANT SELECT ON `ems`.* TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_department_staff` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_employee_tasks` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_employee_projects` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_project_info` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_project_staff` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_project_tasks` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`get_task_data` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_status` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`check_employee` TO employee;
GRANT EXECUTE ON PROCEDURE `ems`.`set_role` TO employee;

FLUSH PRIVILEGES;

CREATE ROLE department_head;
GRANT employee to department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`add_task` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`remove_task` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`reassign_task` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`get_tasks_assigned_by` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_name` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_description` TO department_head;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_deadline` TO department_head;

FLUSH PRIVILEGES;

CREATE ROLE project_manager;
GRANT employee to project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`add_task` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`remove_task` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`reassign_task` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`get_tasks_assigned_by` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_name` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_description` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`change_task_deadline` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`get_employees` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`get_employee_data` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`add_employee_to_project` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`deassign_employee` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`change_employee_role` TO project_manager;
GRANT EXECUTE ON PROCEDURE `ems`.`get_my_project_id` TO project_manager;

FLUSH PRIVILEGES;

CREATE ROLE admin;
GRANT ALL PRIVILEGES ON `ems`.* TO admin WITH GRANT OPTION;

FLUSH PRIVILEGES;
