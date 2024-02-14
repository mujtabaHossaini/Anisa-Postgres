select 2;
select "Ali" ; -- syntax error 
select 'ALI' ;  
select 'Ali' as "ALI" ;
select 'ALi' as name, 28 as age; 

SELECT 'Hello' || ' ' || 'World';
 
SELECT 'Hello' || ' ' || 'World' as "Message";


SELECT 'Hello' || ' ' || 'World' as 'Message'; -- syntax error, "" is used for column names

select concat('Hello', ' ', 'World!') as "Message"; 


SELECT 'Hello' + ' ' + 'World' as "Message"; -- error

SELECT 5 * 3; -- 15

SELECT '90' *3; -- 270

SELECT '90'::int *3 as "Cast Operation";

SELECT current_date, current_time , current_timestamp ; -- YYYY-MM-DD

SELECT current_timestamp - current_time;
SELECT current_timestamp - current_date;
select current_date::timestamp; -- 2024-02-14 00:00:00.000

SELECT length('Database'); -- 8

SELECT random(); -- random between 0 and 1

select round(random() * 100); -- random between 0 and 100



SELECT sin(pi() / 2);

SELECT 'PI :' || pi()  ; -- PI :3.141592653589793



CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

SELECT uuid_generate_v4();


