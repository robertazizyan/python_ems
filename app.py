import mariadb
import sys
from flask import Flask, redirect, render_template, request, session, url_for
from flask_session import Session
from helpers import User, Admin, Head, Manager, check_user, login_required, connect, disconnect, convert_dl

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


@app.route('/change_task_status_<id>', methods = ['POST'])
@login_required
def change_task_status(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    referrer = request.form.get('referrer', '/')
    
    task_data = user.get_task_data(id, cur)
    if task_data and task_data['given_to'] == user.name or task_data['given_by'] == user.name:
        user.change_task_status(id, request.form.get('status'), cur)
        conn.commit()
        disconnect(conn, cur)
        return redirect(referrer)
    else:
        disconnect(conn, cur)
        return redirect(referrer)


@app.route('/project_<id>')
@login_required
def project(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    pm = False
    
    if user.is_manager == 1:
        pm = True
    
    project_info = user.get_project_info(id, cur)
    staff = user.get_project_staff(id, cur)
    tasks = user.get_project_tasks(id, cur)
    disconnect(conn, cur)
    
    return render_template('project.html', project_info = project_info, staff = staff, tasks = tasks, pm = pm, project_id = id)


@app.route('/project_<id>/add_employee_to_project', methods = ['GET', 'POST'])
@login_required
def add_employee_to_project(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_manager == 1 and user.project_id == int(id):
        if request.method == 'POST':
            user.add_employee_to_project(request.form.get('employee'), request.form.get('role'), cur)
            conn.commit()
            
            disconnect(conn, cur)
            return redirect(url_for('project', id = id))
        else:
            employees = user.get_employees(cur)
            
            disconnect(conn, cur)
            return render_template('add_employee_to_project.html', id = id, employees = employees)
    else:
        disconnect(conn, cur)
        return redirect(url_for('project', id = id))


@app.route('/project_<id>/change_employee_in_project_<empl_id>', methods = ['GET', 'POST'])
@login_required
def change_employee_in_project(id, empl_id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_manager == 1 and user.project_id == int(id):
        if request.method == 'POST':
            user.change_employee_role(id, empl_id, request.form.get('role'), cur)
            conn.commit()

            disconnect(conn, cur)
            return redirect(url_for('project', id = id))
        else:
            empl_data = user.get_employee_data(empl_id, cur)
            
            disconnect(conn, cur)
            return render_template('change_employee_in_project.html', id = id, empl_id = empl_id, empl_data = empl_data)
    else:
        disconnect(conn, cur)
        return redirect(url_for('project', id = id))


@app.route('/project_<id>/remove_employee_from_project_<empl_id>', methods = ['POST'])
@login_required
def remove_employee_from_project(id, empl_id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_manager == 1 and user.project_id == int(id):
        user.deassign_employee(id, empl_id, cur)
        conn.commit()
        
        disconnect(conn, cur)
        return redirect(url_for('project', id = id))
    else:
        disconnect(conn, cur)
        return redirect(url_for('project', id = id))


@app.route('/department')
@login_required
def department():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    staff = user.get_department_staff(cur)
    disconnect(conn, cur)
    
    return render_template('department.html', staff=staff, department = user.department_name)


@app.route('/tasks')
@login_required
def tasks():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    tasks = user.get_current_tasks(cur)
    
    if user.is_head == 1 or user.is_manager == 1:
        assigned_tasks = user.get_tasks_assigned_by(cur)
        taskmaster = True
    else:
        assigned_tasks = None
        taskmaster = False
    
    disconnect(conn, cur)
    return render_template('tasks.html', tasks = tasks, assigned_tasks = assigned_tasks, taskmaster = taskmaster)


@app.route('/tasks/change_task_<id>', methods = ['GET', 'POST'])
@login_required
def change_task(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)

    if request.method == 'POST':
        deadline = convert_dl(request.form.get('deadline_date'), request.form.get('deadline_time'))

        user.change_task(cur, id, request.form.get('task_name'), request.form.get('task_description'), deadline, request.form.get('employee'))
        conn.commit()
        
        disconnect(conn, cur)
        return redirect('/tasks')
    else:
        if user.is_head == 1:
            staff = user.get_department_staff(cur)
        elif user.is_manager == 1:
            staff = user.get_project_staff(user.project_id, cur)
        else:
            disconnect(conn,cur)
            return redirect('/tasks')

        task = user.get_task_data(id, cur)

        disconnect(conn, cur)
        
        return render_template('change_task.html', id = id, task = task, staff = staff)


@app.route('/tasks/remove_task_<id>', methods = ['POST'])
@login_required
def remove_task(id):
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_head == 1 or user.is_manager == 1:
        user.remove_task(id, cur)
        conn.commit()
        print('removed')
        disconnect(conn, cur)
        return redirect('/tasks')
    else:
        disconnect(conn, cur)
        return redirect('/tasks')


@app.route('/tasks/create_task', methods = ['GET', 'POST'])
@login_required
def create_task():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if request.method == 'POST':
        deadline = convert_dl(request.form.get('deadline_date'), request.form.get('deadline_time'))
        user.add_task(request.form.get('task_name'), request.form.get('task_description'), deadline, request.form.get('employee'), cur)
        conn.commit()
        disconnect(conn, cur)
        return redirect('/tasks')
    else:
        if user.is_head == 1:
            staff = user.get_department_staff(cur)
        elif user.is_manager == 1:
            staff = user.get_project_staff(user.project_id, cur)
        else:
            disconnect(conn,cur)
            return redirect('/tasks')
        
        disconnect(conn, cur)
        return render_template('create_task.html', staff = staff)


@app.route('/admin')
@login_required
def admin():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    disconnect(conn, cur)
    
    if user.is_admin == 1:
        return render_template('admin.html')
    else:
        return redirect('/')


@app.route('/admin/add_department', methods = ['GET', 'POST'])
@login_required
def add_department():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_admin == 1:
        if request.method == 'POST':
            user.add_department(request.form.get('department'), cur)
            conn.commit()
            
            disconnect(conn, cur)
            return redirect('/admin')
        else:
            disconnect(conn, cur)
            return render_template('add_department.html')
    else:
        disconnect(conn, cur)
        return redirect('/')
    

@app.route('/admin/add_employee', methods = ['GET', 'POST'])
@login_required
def add_employee():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    
    if user.is_admin == 1:
        if request.method == 'POST':
            user.add_employee(
                request.form.get('name'),
                request.form.get('username'),
                request.form.get('password'),
                request.form.get('email'),
                request.form.get('position'),
                request.form.get('department_id'),
                request.form.get('is_head'),
                request.form.get('is_manager'),
                request.form.get('is_admin'),
                cur
            )
            conn.commit()
            
            disconnect(conn, cur)
            return redirect('/admin')
        else:
            departments = user.get_departments(cur)
            
            disconnect(conn, cur)
            return render_template('add_employee.html', departments = departments)
    else:
        disconnect(conn, cur)
        return redirect('/')


@app.route('/admin/add_project', methods = ['GET', 'POST'])
@login_required
def add_project():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)

    if user.is_admin == 1:    
        if request.method == 'POST':
            user.add_project(
                request.form.get('name'),
                request.form.get('description'),
                request.form.get('start'),
                request.form.get('finish'),
                request.form.get('pm'),
                cur
            )
            conn.commit()
            
            disconnect(conn, cur)
            return redirect('/admin')
        else:
            pms = user.get_project_managers(cur)
            
            disconnect(conn, cur)
            return render_template('add_project.html', pms = pms)
    else:
        disconnect(conn, cur)
        return redirect('/')
        
            
@app.route('/login', methods = ['GET', 'POST'])
def login():
    session.clear()
    
    if request.method == 'POST':
        empl_data = check_user(request.form.get('username'), request.form.get('password'))
        if empl_data:
            conn, cur = connect(empl_data['username'], empl_data['password'])
            if empl_data['is_admin'] == 1:
                user = Admin(empl_data)
                session['is_admin'] = True
            elif empl_data['is_head'] == 1:
                user = Head(empl_data)
                session['is_head'] = True
            elif empl_data['is_manager'] == 1:
                user = Manager(empl_data, cur)
                session['is_manager'] = True
            else:
                user = User(empl_data)
            
            session ['user'] = user  

            disconnect(conn, cur)
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
    