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
            autocommit = True
        )
        print('Connected to database')
        cur = conn.cursor()
    except mariadb.Error as e:
        sys.exit(e)

    with open('csv_files/employees.csv', mode = 'r') as file:
        reader = csv.DictReader(file)
        for line in reader:
            cur.execute('DROP USER ?', (line['username'], ))
            
if __name__ == '__main__':
    main()