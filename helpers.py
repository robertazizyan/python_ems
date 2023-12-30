import sys
import mariadb
from werkzeug.security import check_password_hash, generate_password_hash
from flask import redirect, render_template, session 
from functools import wraps
from datetime import datetime


class User:
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
    
    def get_project_tasks(self, project_id, cur):
        cur.execute('CALL `get_project_tasks`(?)', (project_id, )) 
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'employee')
        project_tasks = tuple(dict(zip(keys, result)) for result in results)
        return project_tasks
    
    # Update the task status
    def change_task_status(self, task_id, status, cur):
        cur.execute('CALL `change_task_status`(?, ?)', (task_id, status))
        
    
# A subclass of User that has the ability to change data in the database related to employees, departments and projects  
class Admin(User):
    def __init__(self, empl_data):
        super().__init__(empl_data)
    
    def add_department(self, dep_name, cur):
        if self.admin == 1 and dep_name:
            cur.execute('CALL `add_department`(?)', (dep_name, ))
        
    def add_employee(self, empl_name, empl_username, empl_password, empl_email, empl_position, dep_id, empl_is_head, empl_is_manager, empl_is_admin, cur):
        if self.admin == 1:
            cur.execute('CALL `add_employee`(?, ?, ?, ?, ?, ?, ?, ?, ?)', (empl_name, empl_username, empl_password, empl_email, empl_position, dep_id, empl_is_head, empl_is_manager, empl_is_admin))
    
    def add_project(self, pr_name, pr_description, pr_finish, cur):
        if self.admin == 1:
            cur.execute('CALL `add_project`(?, ?, ?)', (pr_name, pr_description, pr_finish))

    def remove_department(self, dep_id, cur):
        if self.admin == 1 and dep_id:
            cur.execute('CALL `remove_department`(?)', (dep_id, ))
    
    def remove_employee(self, empl_id, cur):
        if self.admin == 1 and empl_id:
            cur.execute('CALL `remove_employee`(?)', (empl_id, ))
    
    def remove_project(self, pr_id, cur):
        if self.admin == 1 and pr_id:
            cur.execute('CALL `remove_project`(?)', (pr_id, ))            

    def change_department_data(self, dep_id, new_dep_name, cur):
        if self.admin == 1 and new_dep_name:
            cur.execute('CALL `change_department_name`(?, ?)', (dep_id, new_dep_name))
    
    def change_employee_data(self, empl_id, new_name, new_username, new_password, new_email, new_position, new_is_head, new_is_manager, new_dep_id, cur):
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
                
            if new_is_head:
                cur.execute('CALL `change_is_head`(?, ?)', (empl_id, new_is_head))
            
            if new_is_manager:
                cur.execute('CALL `change_is_manager`(?, ?)', (empl_id, new_is_manager))
            
            if new_dep_id:
                cur.execute('CALL `change_employee_department`(?, ?)', (empl_id, new_dep_id))
    
    def change_project_data(self, pr_id, new_pr_name, new_pr_description, new_pr_finish, cur):
        if self.is_admin == 1:
            if new_pr_name:
                cur.execute('CALL `change_project_name`(?, ?)', (pr_id, new_pr_name))
            
            if new_pr_description:
                cur.execute('CALL `change_project_description`(?, ?)', (pr_id, new_pr_description))
                
            if new_pr_finish:
                cur.execute('CALL `change_project_finish`(?, ?)', (pr_id, new_pr_finish))            
        

# A subclass of User that has the ability to assign/reassign/deassign tasks to the employees of his department unrelated to projects            
class Head(User):
    def __init__(self, empl_data):
        super().__init__(empl_data)
    
    def add_task(self, task_name, task_description, task_deadline, employee_id, cur):
        cur.execute('CALL `add_task`(?, ?, ?, ?, ?, NULL)', (task_name, task_description, task_deadline, employee_id, self.id))

    def remove_task(self, task_id, cur):
        cur.execute('CALL `remove_task`(?)', (task_id, ))
    
    def reassign_task(self, task_id, new_empl_id, cur):
        cur.execute('CALL `reassign_task`(?, ?)', (task_id, new_empl_id))
    
    def get_tasks_assigned_by(self, cur):
        cur.execute('CALL `get_tasks_assigned_by`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('id', 'name', 'description', 'created', 'deadline', 'status', 'employee')
        tasks = tuple(dict(zip()))
    
    def change_task(self, cur, task_id = None, new_name = None, new_description = None, new_deadline = None):
        if self.is_head == 1:
            if new_name:
                cur.execute('CALL `change_task_name`(?, ?)', (task_id, new_name))
            
            if new_description:
                cur.execute('CALL `change_task_description`(?, ?)', (task_id, new_description))
                
            if new_deadline:
                cur.execute('CALL `change_task_deadline`(?, ?)', (task_id, new_deadline))
    
    
# A subclass of User that has the ability to assign/reassign/deassign tasks to the employees in his project 
class Manager(User):
    def __init__(self, empl_data, cur):
        super().__init__(empl_data)
        pr_id = self.get_my_project_id(cur)
        self.project_id = pr_id
        self.staff = self.get_project_staff(pr_id, cur)

    def get_my_project_id(self, cur):
        cur.execute('CALL `get_my_project_id`(?)', (self.id, ))
        pr_id = cur.fetchone()[0]
        return pr_id
    
    def add_task(self, task_name, task_description, task_deadline, employee_id, cur):
        cur.execute('CALL `add_task`(?, ?, ?, ?, ?, ?)', (task_name, task_description, task_deadline, employee_id, self.id, self.project_id))
    
    def remove_task(self, task_id, cur):
        cur.execute('CALL `remove_task`(?)', (task_id, ))
    
    def reassign_task(self, task_id, new_empl_id, cur):
        cur.execute('CALL `reassign_task`(?, ?)', (task_id, new_empl_id))
    
    def get_tasks_assigned_by(self, cur):
        cur.execute('CALL `get_tasks_assigned_by`(?)', (self.id, ))
        results = cur.fetchall()
        keys = ('task_id', 'name', 'description', 'created', 'deadline', 'status', 'employee')
        tasks = tuple(dict(zip(keys, result)) for result in results)
        return tasks
    
    def change_task(self, task_id, new_name, new_description, new_deadline, cur):
        if self.is_head == 1:
            if new_name:
                cur.execute('CALL `change_task_name`(?, ?)', (task_id, new_name))
            
            if new_description:
                cur.execute('CALL `change_task_description`(?, ?)', (task_id, new_description))
                
            if new_deadline:
                cur.execute('CALL `change_task_deadline`(?, ?)', (task_id, new_deadline))    

    def add_employee_to_project(self, pr_id, empl_id, role, cur):
        cur.execute('CALL `add_employee_to_project`(?, ?, ?)', (pr_id, empl_id, role))
        
    def deassign_employee(self, pr_id, empl_id, cur):
        cur.execute('CALL `deassign_employee`(?, ?)', (pr_id, empl_id))
        
    def change_employee_role(self, pr_id, empl_id, new_role, cur):
        cur.execute('CALL `change_employee_role`(?, ?)', (pr_id, empl_id, new_role))

    
def check_user(username, password):
    # Establish connection to MariaDB server
    try:
        conn = mariadb.connect(
            user = username,
            password = password,
            database = 'ems'
        )
        print('successfully connected to db')
    except mariadb.Error as e:
        print('Could not connect to db')
        return

    cur = conn.cursor()
    cur.execute('CALL `check_employee`(?, ?)', (username, password))
    result = cur.fetchone()
    
    print(result)
    if result:
        keys = ('id', 'name', 'username', 'password', 'email', 'position', 'is_head', 'is_manager', 'is_admin', 'department_id', 'department_name')
        empl_data = dict(zip(keys, result))
        conn.close()
        return empl_data   
    else:
        return


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user'):
            return redirect('/login')
        return f(*args, **kwargs)
    return decorated_function


def connect(username, password):
    conn = mariadb.connect(
        username = username,
        password = password,
        database = 'ems'
    )
    cur = conn.cursor()
    return conn, cur


def disconnect(conn, cur):
    cur.close()
    conn.close()
    

def convert_dl(date, time):
    return datetime.strptime(f'{date} {time}', '%Y-%m-%d %H:%M')