import sys
import mariadb
import csv

def main():
    #connect to the database first
    try:
        conn = mariadb.connect(
            user = 'ems_admin',
            password = 'ems_admin',
            host = 'localhost',
            port = 3306,
            database = 'ems',
            autocommit = True
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
            print(f"adding {line['name']}")
            cur.execute('CALL `add_employee`(?, ?, ?, ?, ?, ?, ?, ?, ?)', (
                line['name'], 
                line['username'], 
                line['password'], 
                line['email'], line['position'], 
                int(line['department_id']), 
                int(line['is_head']), 
                int(line['is_manager']), 
                int(line['is_admin'])
            ))
            
    # Add projects
    with open('csv_files/projects.csv', mode = 'r') as file:
        reader = csv.DictReader(file, delimiter = ';')
        for line in reader:
            cur.execute('CALL `add_project`(?, ?, ?, ?)', (line['name'], line['description'], line['start'], line['finish']))       
    
    # Fill projects_employees relationship table
    with open('csv_files/projects_employees.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('CALL `add_employee_to_project`(?, ?, ?)', (int(line['project_id']), int(line['employee_id']), line['role']))
    
    # Add tasks
    with open('csv_files/tasks.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            project_related = int(line['project_related']) if line['project_related'] else None
            cur.execute('CALL `add_task`(?, ?, ?, ?, ?, ?)', (
                line['name'], 
                line['description'], 
                line['deadline'], 
                int(line['employee_id']), 
                int(line['assigned']), 
                project_related
            ))    
        
    # Commit all changes to the database    
    print('Database filled successfully')
    conn.close()

if __name__ == '__main__':
    main()