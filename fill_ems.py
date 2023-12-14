import sys
import mariadb
import csv

def main():
    #connect to the database first
    try:
        conn = mariadb.connect(
            user = 'ems_admin',
            password = 'ems_admin',
            database = 'ems'
        )
        print('Connected to database')
    except mariadb.Error as e:
        sys.exit(e)
    
    cur = conn.cursor()
    
    # Add departments to ems db first
    with open('csv_files/departments.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('CALL `add_department`(?)', (line['name'], ))
    
    # Add employees (and consequently fill departments_employees table)
    with open('csv_files/employees.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('CALL `add_employee`(?, ?, ?, ?, ?, ?, ?)', (line['name'], line['username'], line['password'], line['email'], line['position'], line['dep_id'], line['head']))
    
    # Add projects
    with open('csv_files/projects.csv', mode = 'r') as file:
        reader = csv.DictReader(file, delimiter = ';')
        for line in reader:
            cur.execute('CALL `add_project`(?, ?, ?, ?)', (line['name'], line['description'], line['start'], line['finish']))       
    
    # Fill projects_employees relationship table
    with open('csv_files/projects_employees.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('CALL `add_employee_to_project`(?, ?, ?)', (line['project_id'], line['employee_id'], line['role']))
    
    # Add tasks
    with open('csv_files/tasks.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('CALL `add_task`(?, ?, ?, ?, ?)', (line['name'], line['description'], line['deadline'], line['project_id'], line['employee_id']))    
        
    # Commit all changes to the database    
    conn.commit()
    print('Database filled successfully')

if __name__ == '__main__':
    main()