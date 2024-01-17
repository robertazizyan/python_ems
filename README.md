# An Employee Management System (EMS), using MySQL, Python and Flask
## General overview
The following web application allows for management of the employees in a company, whose structure is defined in the schema. 
The management includes task assigning/modification and completion of those tasks by entities further described in this document.
The web application uses a MySQL database built with MariaDB and an API built with Python to facilitate launching the app in the web browser using Flask.
## Requirements
The EMS makes use of the following installable software:
1. MariaDB (I used Ver 9.1 Distrib 10.6.12-MariaDB)
2. Pip installable modules including Flask (For building a web app), mariadb (For connecting to the database)
## File overview
The EMS directory includes the following files:
1. app.py - The actual Flask web application
2. templates directory - a number of HTML templates with content
3. static directory - contains styles.css file
4. helpers.py - An API built in Python to facilitate running of the web app. Contains created classes for the user classes from the database and general helper functions. 
The user classes include the actual User who is able to do basic actions regarding viewing the database entries and completing tasks given to him, Head, Manager and Admin child classes, who bear a richer set of rights regarding the use of the database (the rights will be described in the database section of the document).
5. csv_files directory - Contains a number of CSV files used for filling up the database entities using a Python script.
6. fill_ems.py - A Python script used for filling up the database using sample data (Note: you have to create a database first if you've dropped it previously, more on that later).
7. delete.py - A Python script used for dropping the database, users and roles associated with it
8. schema.sql - a MySQL file used for creating the schema of the database and switching to it for further use
9. procedures directory - a number of stored procedures to be created associated with certain roles in the database (Note: some of the procedures are shared between Head and Manager users, so they're only listed in the head_procedures.sql but both type of users can access them). Also contains roles.sql file that determines grants for various types of users
10. schema.png - a visual representation of the database schema
## Database overview
### Entities
The database includes the following entities:
#### Departments
The `departments` table includes:
* `id`, INT PRIMARY KEY.
* `name`, Department name as VARCHAR(100).
#### Employees
The `employees` table includes:
* `id`, INT PRIMARY KEY.
* `name`, employee name VARCHAR(100).
* `username`, VARCHAR(100).
* `password`, VARCHAR(300).
* `email`, VARCHAR(100).
* `position`, a descriptive position of the employee in the department.
* `is_head`, a TINYINT(1) depicting whether the employee is head of the department (1) or not (0).
* `is_manager`, TINYINT(1) depicting whether the employee is manager of the project.
* `is_admin`, TINYINT(1) depicting whether the employee is the admin of the database.
#### Departments_employees
The `departments_employees` table includes:
* `department_id` an INT FOREIGN KEY from the departments table.
* `employee_id` an INT FOREIGN KEY from the employees table.
#### Projects
The `projects` table includes:
* `id`, INT PRIMARY KEY.
* `name`, VARCHAR(100) project name.
* `description`, TEXT project description.
* `start`, DATE of the start.
* `finish`, DATE of the finish.
#### Projects_employees
The `projects_employees` table includes:
* `project_id`, INT FOREIGN KEY that references projects table.
* `employee_id`, INT FOREIGN KEY that references employees table.
* `role`, VARCHAR(100), a description of the employee's role in a project
#### Tasks
The `tasks` table includes:
* `id`, INT PRIMARY KEY.
* `name`, VARCHAR(100).
* `description`, TEXT.
* `created`, DATETIME the timestamp of creating the task.
* `deadline`, DATETIME the timestamp of needing to finish the task.
* `status`, an ENUM of statuses such as 'Pending', 'In progress', 'Completed', 'Archived'.
#### Employees_tasks
The `employees_tasks` table includes:
* `employee_id`, INT FOREIGN KEY that references employees table.
* `task_id`, INT FOREIGN KEY that references tasks table.
* `assigned_by`, INT FOREIGN KEY that references employees table (id) yet again.
* `project_related`, INT FOREIGN KEY that references the projects table. Can be NULL, if the task is not referencing a project.
### Procedures
The procedures directory holds a number of stored MySQL procedures used for various purposes in the database:
1. Admin procedures - an Admin can add, remove and alter data related to the departments, employees and projects.
2. Head procedures - a Department Head can create, alter, re-assign and delete tasks for the members of his department with NO regards to the project, and alter the task status, view all active tasks assigned by him
3. Manager procedures - a Project Manager can also create, alter, re-assign and delete tasks but only for the members of his current project. He can also add new people to the project, change their roles in the project and remove those poeople from the project.
4. Employee procedures - an Employee can  view his department staff, view his ACTIVE tasks AND change their status, view his ACTIVE projects, view his ACTIVE projects staff and current tasks for the project
5. Procedures - a file with general procedures executed when running the web app. Used for getting the employee data from the database.
6. Roles - a file with roles and their grants
## Usage 
### Setting up the database
After having installed MariaDB, log in as the user the has ALL PRIVILEGES WITH GRANT OPTION. You can create such user yourself, or use the 'root' user that you've initially set up when installing the database.
After logging in, you'll need to run a number of MariaDB commands:

```sql
-- Create a database with a defined schema and switch to it
SOURCE schema.sql;
-- Create procedures for a database admin
SOURCE procedures/admin_procedures.sql;
-- Create procedures for a department head
SOURCE procedures/head_procedures.sql;
-- Create procedures for a project manager
SOURCE procedures/manager_procedures.sql;
-- Create procedures for a basic employee
SOURCE procedures/employee_procedures.sql;
-- Create general web app procedures
SOURCE procedures/procedures.sql;
-- Create roles with assigned rights
SOURCE procedures/roles.sql;
```
### Filling up the database
After you've created the database you'll need to fill it up by running a python script from the terminal:
```bash
python3 fill_ems.py
```
### Launching the web app
Now you're ready to use the web application, by running
```bash
flask run
```
in the terminal.
### Accessing different users
The csv_files/employees.csv file contains the usernames and passwords for all the employees that are currently in the database and are available for logging in as them. You can also add new users if you log in as a database admin, namely in this case: "emma_lewis emmaP@ss" for username and password.
### Running the web app
#### As an employee
The first page you'll access after logging in is you cabinet, where you'd be able to see the position and the department of your user, current tasks and current projects you're enlisted in.
You would also have the department page, where you can view your current department staff and the tasks page, where you'd be able to see your tasks again and change their status accordingly.
#### As a department head
You get the same rights as an employee, except now on the tasks page you'd also be able to create/modify/delete tasks for the members of your department on the tasks page.
#### As a project manager
Same rights as an employee and a department head, except you can only create tasks for the members of your project. You also get access to my project page, which would list most of the information about the project you're currently managing. On that page you can also work with tasks, assign/re-assign/de-assign employees for your project and change their roles in the project.
#### As a database admin
Same rights as an employee, except you also get access to an admin page, which let's you modify departments/employee and projects data accordingly. The full list of admin available actions will also be displayed on that page.
### Resetting the database
If you'd like to try out a new set of employees on the database, you can run
```bash
python3 delete.py
```
Note that this will completely drop the database and delete all the users associated with it EXCEPT the ones you may have added as an admin when running the web app. To remove such users you would also have to run
```sql
DROP USER <username>;
```
after dropping the database and accessing Mariadb through the terminal, and that would have to be done manually for each user you've created OR you could just delete those users in the actual web app beforehand manually as well.
## Limitations
There is a number of limitations when it comes to using this database for the web app to work properly:
1. A single employee can only have one role at a time, be it a regular employee, a department head, a project manager or a database admin
2. A project manager can currently be a PM of only one project at a time. Same logic applies to department heads
3. Only admin cann add new departments, employees and projects and when adding those, it's generally recommended to add them in the order above for a better user experience
4. When adding a new project as a database admin, you'd only be able to assign a PM from a pool of employees who have an actual 'manager' string in their position AND who do not have any current projects (where they have a PM role)
5. A task can only be assigned to one employee, not many
6. When deleting a department as a database admin, the employees in that departments would be deleted from the database as well
7. When deleting a project from the database, the employees in that project would not be deleted, but rather just de-assigned from the project.

