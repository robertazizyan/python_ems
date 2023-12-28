import mariadb
import sys
from flask import Flask, redirect, render_template, request, session
from flask_session import Session
from helpers import User, Admin, Head, Manager, check_user, login_required, connect

app = Flask(__name__)

app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

# Render an index page
@app.route('/')
@login_required
def index():
    user = session.get('user')
    conn, cur = connect(user.username, user.password)
    tasks = user.get_current_tasks(cur)
    projects = user.get_current_projects(cur)

    return render_template('cabinet.html', user = user, tasks = tasks, projects = projects)

@app.route('/')

@app.route('/login', methods = ['GET', 'POST'])
def login():
    session.clear()
    
    if request.method == 'POST':
        empl_data = check_user(request.form.get('username'), request.form.get('password'))
        if empl_data:
            print('got empl_data')
            if empl_data['is_admin'] == 1:
                user = Admin(empl_data)
            elif empl_data['is_head'] == 1:
                user = Head(empl_data)
            elif empl_data['is_manager'] == 1:
                user = Manager(empl_data)
            else:
                user = User(empl_data)
            
            session ['user'] = user    
        
            return redirect('/')
        else:
            return render_template('login.html')        
    else:
        return render_template('login.html')

   
@app.route('/logout', methods = ['GET', 'POST'])
@login.required 
def logout():
    if session['user']:
        session.clear()
        return redirect('/')
    