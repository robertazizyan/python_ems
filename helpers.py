import sys
import mariadb
from werkzeug.security import check_password_hash, generate_password_hash
from flask import redirect, render_template, session 
from functools import wraps
from datetime import datetime, time


class User:
    # Init an object and assign primary parameters for further reference
    def __init__(self, empl_data):

        self.id = empl_data['id']
        self.name = empl_data['name']
        self.username = empl_data['username']
        self.password = empl_data['password']
        self.email = empl_data['email']
        self.position = empl_data['position']
        self.is_head = empl_data['is_head']
        self.is_manager = empl_data['is_manager']
        self.is_admin = empl_data['is_admin']
        self.department_id = empl_data['department_id']
        self.department_name = empl_data['department_name']
        
    # Get current employee tasks from the db as a tuple of dictionaries. 
    def get_current_projects(self, cur):
        cur.execute('CALL `get_employee_projects`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('id', 'name', 'description', 'role')
        projects = tuple(dict(zip(keys, result)) for result in results)
        return projects
    
    # Get current employee tasks from the db as a tuple of dictionaries. 
    def get_current_tasks(self, cur):
        cur.execute('CALL `get_employee_tasks`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'status', 'assigned_by', 'project')
        tasks = tuple(dict(zip(keys, result)) for result in results)
        return tasks
    
     # Get the department staff from the db as a tuple of dictionaries
    def get_department_staff(self, cur):
        cur.execute('CALL `get_department_staff`(?)', (self.department_id, ))
        results = cur.fetchall()
        keys = ('employee_id', 'name', 'email', 'position')
        staff = tuple(dict(zip(keys, result)) for result in results)
        return staff

    # Get the project info from the db as a tuple of dictionaries
    def get_project_info(self, project_id, cur):
        cur.execute('CALL `get_project_info`(?)', (project_id, ))
        results = cur.fetchone()
        keys = ('name', 'description', 'start', 'finish')
        project_info = dict(zip(keys, results))
        return project_info
    
    # Get the project staff from the db as a tuple of dictionaries
    def get_project_staff(self, project_id, cur):
        cur.execute('CALL `get_project_staff`(?)', (project_id, ))
        results = cur.fetchall()
        keys = ('employee_id', 'name', 'email', 'role')
        staff = tuple(dict(zip(keys, result)) for result in results)
        return staff
    
    # Get a tuple of tasks associated with a certain project from a db
    def get_project_tasks(self, project_id, cur):
        cur.execute('CALL `get_project_tasks`(?)', (project_id, )) 
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'employee', 'status')
        project_tasks = tuple(dict(zip(keys, result)) for result in results)
        return project_tasks
    
    # Return essential task data from the db as a tuple of dictionaries
    def get_task_data(self, task_id, cur):
        cur.execute('CALL `get_task_data`(?)', (task_id, ))
        result = list(cur.fetchone())
        result[2] = convert_dl_back(result[2])
        keys = ('name', 'description', 'deadline', 'given_to', 'given_by')
        task = dict(zip(keys, result))
        return task
    
    # Update the task status
    def change_task_status(self, task_id, status, cur):
        cur.execute('CALL `change_task_status`(?, ?)', (task_id, status))
        
    
# A subclass of User that has the ability to change data in the database related to employees, departments and projects  
class Admin(User):
    def __init__(self, empl_data):
        super().__init__(empl_data)
    
    # Self explanatory
    def add_department(self, dep_name, cur):
        if self.is_admin == 1 and dep_name:
            cur.execute('CALL `add_department`(?)', (dep_name, ))
    
    # Return a tuple of dictionaries representing all existing departments if no choice is provided, else only return info on one certain department (based on its id) from the db
    def admin_get_departments(self, cur, choice = None):
        if self.is_admin == 1:
            dep = None
            cur.execute('CALL `admin_get_departments`')
            results = cur.fetchall()
            keys = ('id', 'name')
            departments = tuple(dict(zip(keys, result)) for result in results)

            if choice:
                for department in departments:
                    if int(department['id']) == int(choice):
                        return department
            else:
                return departments
    
    # Same stuff as departments, except now do that with employees
    def admin_get_employees(self, cur, choice = None):
        if self.is_admin == 1:
            cur.execute('CALL `admin_get_employees`')
            results = cur.fetchall()
            keys = ('id', 'name', 'username', 'password', 'email', 'position', 'is_head', 'is_manager', 'is_admin', 'department_id', 'department_name')
            employees = tuple(dict(zip(keys, result)) for result in results)
            
            if choice:
                for employee in employees:
                    if int(employee['id']) == int(choice):
                        return employee
            else:
                return employees
        
    # Same, but with projects
    def admin_get_projects(self, cur, choice = None):
        if self.is_admin == 1:
            cur.execute('CALL `admin_get_projects`')
            results = cur.fetchall()
            keys = ('id', 'name', 'description', 'start', 'finish', 'pm_id', 'pm_name')
            projects = tuple(dict(zip(keys, result)) for result in results)

            if choice:
                for project in projects:
                    if int(project['id']) == int(choice):
                        return project
            else:
                return projects
        
    # Add a new employee to the db, give certain rights based on is_head, is_manager, is_admin statuses
    def add_employee(self, empl_name, empl_username, empl_password, empl_email, empl_position, dep_id, empl_is_head, empl_is_manager, empl_is_admin, cur):
        if self.is_admin == 1:
            cur.execute('CALL `add_employee`(?, ?, ?, ?, ?, ?, ?, ?, ?)', (empl_name, empl_username, empl_password, empl_email, empl_position, dep_id, empl_is_head, empl_is_manager, empl_is_admin))
    
    # Get a list of all project managers THAT DO NOT(!) CURRENTLY MANAGE ANY PROJECT
    def get_project_managers(self, cur):
        if self.is_admin == 1:
            cur.execute('CALL `get_project_managers`')
            results = cur.fetchall()
            keys = ('id', 'name')
            pms = tuple(dict(zip(keys, result)) for result in results)
            return pms
    
    # Add a new project to the db and assign a project manager to it (Also changes is_manager status for the assigned pm in db to 1, giving him the rights to create/modify tasks)
    def add_project(self, pr_name, pr_description, pr_start, pr_finish, pm, cur):
        if self.is_admin == 1:
            cur.execute('CALL `add_project`(?, ?, ?, ?, ?)', (pr_name, pr_description, pr_start, pr_finish, pm))

    # Remove a department from a db. THIS ALSO REMOVES ALL EMPLOYEES IN THE CURRENT DEPARTMENT
    def remove_department(self, dep_id, cur):
        if self.is_admin == 1 and dep_id:
            cur.execute('CALL `remove_department`(?)', (dep_id, ))
    
    # Remove an employee from a db. THIS ALSO REMOVES ALL TASKS ASSOCIATED WITH THIS EMPLOYEE.
    def remove_employee(self, empl_id, cur):
        if self.is_admin == 1 and empl_id:
            cur.execute('CALL `remove_employee`(?)', (empl_id, ))
    
    # Remove a project from the db. THIS DOES NOT AUTOMATICALLY DELETE AN EMPLOYEES DATA
    def remove_project(self, pr_id, cur):
        if self.is_admin == 1 and pr_id:
            cur.execute('CALL `remove_project`(?)', (pr_id, ))            

    # Change department name
    def change_department(self, dep_id, new_dep_name, cur):
        if self.is_admin == 1 and new_dep_name:
            cur.execute('CALL `change_department`(?, ?)', (dep_id, new_dep_name))
    
    # Change employee data
    def change_employee(
        self, 
        cur, 
        empl_id = None, 
        new_name = None, 
        new_username = None, 
        new_password = None, 
        new_email = None, 
        new_position = None,
        new_dep_id = None,
        new_is_head = None, 
        new_is_manager = None, 
        new_is_admin = None
    ):
        if self.is_admin == 1:
            if new_name:
                cur.execute('CALL `change_employee_name`(?, ?)', (empl_id, new_name))
            
            if new_username:
                cur.execute('CALL `change_employee_username`(?, ?)', (empl_id, new_username))
                
            if new_password:
                cur.execute('CALL `change_employee_password`(?, ?)', (empl_id, new_password))
            
            if new_email:
                cur.execute('CALL `change_employee_email`(?, ?)', (empl_id, new_email))
                
            if new_position:
                cur.execute('CALL `change_employee_position`(?, ?)', (empl_id, new_position))

            if new_dep_id:
                cur.execute('CALL `change_employee_department`(?, ?)', (empl_id, new_dep_id))
                
            if new_is_head:
                cur.execute('CALL `change_is_head`(?, ?)', (empl_id, new_is_head))
            
            if new_is_manager:
                cur.execute('CALL `change_is_manager`(?, ?)', (empl_id, new_is_manager))
                
            if new_is_admin:
                cur.execute('CALL `change_is_admin`(?, ?)', (empl_id, new_is_admin))
    
    # Change project data
    def change_project(
        self, 
        cur, 
        pr_id = None, 
        new_pr_name = None, 
        new_pr_description = None, 
        new_pr_start = None, 
        new_pr_finish = None, 
        new_pm = None
    ):
        if self.is_admin == 1:
            if new_pr_name:
                cur.execute('CALL `change_project_name`(?, ?)', (pr_id, new_pr_name))
            
            if new_pr_description:
                cur.execute('CALL `change_project_description`(?, ?)', (pr_id, new_pr_description))
            
            if new_pr_start:
                cur.execute('CALL `change_project_start`(?, ?)', (pr_id, new_pr_start))
                
            if new_pr_finish:
                cur.execute('CALL `change_project_finish`(?, ?)', (pr_id, new_pr_finish))
            
            if new_pm:
                cur.execute('CALL `change_project_manager`(?, ?)', (pr_id, new_pm))            
        

# A subclass of User that has the ability to assign/reassign/deassign tasks to the employees of his department unrelated to projects            
class Head(User):
    def __init__(self, empl_data):
        super().__init__(empl_data)
    
    # Add a new task into the database (ONLY TO EMPLOYEES ASSIGNED TO THE USER'S DEPARTMENT)
    def add_task(self, task_name, task_description, task_deadline, employee_id, cur):
        cur.execute('CALL `add_task`(?, ?, ?, ?, ?, NULL)', (task_name, task_description, task_deadline, employee_id, self.id))

    # Delete a task from the database
    def remove_task(self, task_id, cur):
        cur.execute('CALL `remove_task`(?)', (task_id, ))
    
    # Return a tuple of tasks assigned by the user himself
    def get_tasks_assigned_by(self, cur):
        cur.execute('CALL `get_tasks_assigned_by`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'status', 'employee')
        tasks = tuple(dict(zip(keys, result)) for result in results)
        return tasks
    
    # Change a given task data
    def change_task(self, cur, task_id = None, new_name = None, new_description = None, new_deadline = None, new_employee = None):
        if self.is_head == 1:
            if new_name:
                cur.execute('CALL `change_task_name`(?, ?)', (task_id, new_name))
            
            if new_description:
                cur.execute('CALL `change_task_description`(?, ?)', (task_id, new_description))
                
            if new_deadline:
                cur.execute('CALL `change_task_deadline`(?, ?)', (task_id, new_deadline))
            
            if new_employee:
                cur.execute('CALL `reassign_task`(?, ?)', (task_id, new_employee))
    
    
# A subclass of User that has the ability to assign/reassign/deassign tasks to the employees in his project 
class Manager(User):
    def __init__(self, empl_data, cur):
        super().__init__(empl_data)
        pr_id = self.get_my_project_id(cur)
        self.project_id = pr_id

    # Get an id of the project, that the user currently manages
    def get_my_project_id(self, cur):
        cur.execute('CALL `get_my_project_id`(?)', (self.id, ))
        pr_id = cur.fetchone()[0]
        return pr_id
    
    # Get a tuple of all employees enlisted on the user's project
    def get_employees(self, cur):
        cur.execute('CALL `get_employees`(?)', (self.project_id, ))
        results = cur.fetchall()
        keys = ('id', 'name', 'position', 'department')
        employees = tuple(dict(zip(keys, result)) for result in results)
        return employees
    
    # Get essential data about an employee in the project
    def get_employee_data(self, empl_id, cur):
        cur.execute('CALL `get_employee_data`(?)', (empl_id, ))
        result = cur.fetchone()
        keys = ('name', 'role')
        data = dict(zip(keys, result))
        return data
    
    # Add a new task and assign an employee to it (ONLY TO EMPLOYEES ASSIGNED TO THE PROJECT)
    def add_task(self, task_name, task_description, task_deadline, employee_id, cur):
        cur.execute('CALL `add_task`(?, ?, ?, ?, ?, ?)', (task_name, task_description, task_deadline, employee_id, self.id, self.project_id))
    
    # Delete a task
    def remove_task(self, task_id, cur):
        cur.execute('CALL `remove_task`(?)', (task_id, ))
    
    # Same as in Head class
    def get_tasks_assigned_by(self, cur):
        cur.execute('CALL `get_tasks_assigned_by`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'status', 'employee')
        tasks = tuple(dict(zip(keys, result)) for result in results)
        return tasks
    
    # Same as in Head class
    def change_task(self, cur, task_id = None, new_name = None, new_description = None, new_deadline = None, new_employee = None):
        if self.is_manager == 1:
            if new_name:
                cur.execute('CALL `change_task_name`(?, ?)', (task_id, new_name))
            
            if new_description:
                cur.execute('CALL `change_task_description`(?, ?)', (task_id, new_description))
                
            if new_deadline:
                cur.execute('CALL `change_task_deadline`(?, ?)', (task_id, new_deadline))
            
            if new_employee:
                cur.execute('CALL `reassign_task`(?, ?)', (task_id, new_employee))

    # Assign a new employee on a project
    def add_employee_to_project(self, empl_id, role, cur):
        cur.execute('CALL `add_employee_to_project`(?, ?, ?)', (self.project_id, empl_id, role))
    
    # Remove an employee from a project
    def deassign_employee(self, pr_id, empl_id, cur):
        cur.execute('CALL `deassign_employee`(?, ?)', (pr_id, empl_id))
    
    # Change employee's role in a project
    def change_employee_role(self, pr_id, empl_id, new_role, cur):
        cur.execute('CALL `change_employee_role`(?, ?, ?)', (pr_id, empl_id, new_role))

# Connect to the db, check if the user exists in it, assign a specific role in MariaDB and return user data to init an object of the classes above in Flask
def check_user(username, password):
    try:
        conn = mariadb.connect(
            user = username,
            password = password
        )
        print('successfully connected to db')
    except mariadb.Error as e:
        print('Could not connect to db')
        return

    cur = conn.cursor()
    cur.execute('SET ROLE employee')
    cur.execute('USE ems')
    cur.execute('CALL `check_employee`(?, ?)', (username, password))
    result = cur.fetchone()
    
    if result:
        keys = ('id', 'name', 'username', 'password', 'email', 'position', 'is_head', 'is_manager', 'is_admin', 'department_id', 'department_name')
        empl_data = dict(zip(keys, result))
        conn.close()
        return empl_data   
    else:
        return

# Protect a url from being accessed by not being logged in
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user'):
            return redirect('/login')
        return f(*args, **kwargs)
    return decorated_function

# Establish a connection to the db and return conn object and cur object for actions in Flask. Also sets a role for the current user based on the username and password
def connect(username, password):
    conn = mariadb.connect(
        username = username,
        password = password
    )
    cur = conn.cursor()
    cur.execute('SET ROLE employee')
    cur.execute('USE ems')
    cur.execute('CALL `set_role`(?, ?)', (username, password))
    statuses = cur.fetchone()
    if statuses[0] == 1:
        cur.execute('SET ROLE department_head')
    elif statuses[1] == 1:
        cur.execute('SET ROLE project_manager')
    elif statuses[2] == 1:
        cur.execute('SET ROLE admin')
    return conn, cur

# Close the db connection
def disconnect(conn, cur):
    cur.close()
    conn.close()
    
# Convert a string of date and a string of time into a datetime object for inserting into the database (particularly into the tasks table)
def convert_dl(date, time):
    return datetime.strptime(f'{date} {time}', '%Y-%m-%d %H:%M')

# Convert a datetime obkect iinto a string of date and a string of time for proper formatting and display in HTML forms on the web app
def convert_dl_back(dt):
    return dt.date(), dt.time().strftime('%H:%M')