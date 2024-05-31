#### Load Northwind Database 

First we need to create the database

- `psql -f`

  ```bash
  $ psql -h localhost -p 5432 -U postgres -c "CREATE DATABASE northwind;"
  $ cd "E:\Anisa\Sample DBs"
  $ psql -d postgres -U postgres -d northwind -f northwind.sql
  $ psql -d postgres -U postgres -d northwind
  $ postgres=# \dt
  ```

- `psql -i`

  ```bash
  $ psql -d postgres -U postgres -d postgres
  postgres=# CREATE DATABASE northwind;
  postgres=# \c northwind
  postgres=# \i 'E:/Anisa/Sample DBs/northwind.sql'
  postgres=# \dt
  ```

  - note the `/` ans `'` single qoute around the path

- **DBeaver**

  - open ***dbeaver***, connect to the postgres, create a new DB namde `northwind`&  copy-paste the scripts and execute the sql file

- **pgAdmin**

  - open **pgAdmin**
  - create database `northwind`
  - right click on `northwind` and select `Query Tool`
  - copy & paste the SQL file contents