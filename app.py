import mariadb
import sys
from flask import Flask, redirect, render_template, request, session
from flask_session import Session
from helpers import User, Admin, Head, Manager, check_user, login_required, connect, disconnect

app = Flask(__name__)

app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)


@app.route('/')
@login_required
def index():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    tasks = user.get_current_tasks(cur)
    projects = user.get_current_projects(cur)
    disconnect(conn, cur)

    return render_template('cabinet.html', user = user, tasks = tasks, projects = projects)


@app.route('/project_<id>')
@login_required
def project(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    project_info = user.get_project_info(id, cur)
    staff = user.get_project_staff(id, cur)
    tasks = user.get_project_tasks(id, cur)
    disconnect(conn, cur)
    
    return render_template('project.html', project_info = project_info, staff = staff, tasks = tasks)


@app.route('/department', methods = ['GET', 'POST'])
@login_required
def department():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    staff = user.get_department_staff(cur)
    disconnect(conn, cur)
    
    return render_template('department.html', staff=staff, department = user.department_name)

@app.route('/tasks', methods = ['GET', 'POST'])
@login_required
def tasks():
    if request.method == 'POST':
        ...
    else:
        user = session.get('user')
        conn, cur = connect(user.username, user.password)
        tasks = user.get_current_tasks(cur)
        if user.is_head == 1 or user.is_manager == 1:
            assigned_tasks = user.get_tasks_assigned_by(cur)
        else:
            assigned_tasks = None
        
        return render_template('tasks.html', tasks = tasks, assigned_tasks = assigned_tasks)    

@app.route('/login', methods = ['GET', 'POST'])
def login():
    session.clear()
    
    if request.method == 'POST':
        empl_data = check_user(request.form.get('username'), request.form.get('password'))
        if empl_data:
            if empl_data['is_admin'] == 1:
                user = Admin(empl_data)
                session ['is_admin'] = True 
            elif empl_data['is_head'] == 1:
                user = Head(empl_data)
                session ['is_head'] = True
            elif empl_data['is_manager'] == 1:
                user = Manager(empl_data)
                session['is_manager'] = True
            else:
                user = User(empl_data)
            
            session ['user'] = user  
        
            return redirect('/')
        else:
            return render_template('login.html')        
    else:
        return render_template('login.html')

   
@app.route('/logout')
@login_required 
def logout():
    if session['user']:
        session.clear()
        return redirect('/')
    