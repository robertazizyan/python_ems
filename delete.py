import sys
import mariadb
import csv

def main():
    try:
        conn = mariadb.connect(
            user = 'ems_admin',
            password = 'ems_admin',
            host = 'localhost',
            port = 3306,
            autocommit = True
        )
        print('Connected to database')
        cur = conn.cursor()
    except mariadb.Error as e:
        print('Error connecting to the database')
        sys.exit(e)

    # DROP the database and roles associated with it
    cur.execute('DROP DATABASE ems')
    cur.execute('DROP ROLE admin')
    cur.execute('DROP ROLE employee')
    cur.execute('DROP ROLE department_head')
    cur.execute('DROP ROLE project_manager')

    # Delete all users from the database
    with open('csv_files/employees.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            try:
                print(f"Deleting {line['name']}")
                cur.execute('DROP USER ?', (line['username'], ))
            except mariadb.Error as e:
                print(f"Couldn't delete {line['name']}")
                print(e)
                
            
if __name__ == '__main__':
    main()