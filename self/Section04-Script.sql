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

SELECT uuid_generate_v4(), uuid_generate_v1();

SELECT to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS');

select extract (month from current_timestamp);

select interval '2 days' * 3; -- 6 days

SELECT current_date + interval '1 week'; -- plus 7 days

SELECT substring('Hello World' from 1 for 5); -- Hello

SELECT substring('Hello World' from 1 for 50); -- Hello World

-- CASE returns only one value
SELECT 
	  CASE 
		WHEN 1 = 1 THEN 'True' 
	    ELSE 'False' 
	  end as "Boolean Operation"; -- True

	  
	  
	  
SELECT 
	  CASE 
		WHEN 1 = 1 THEN 5
		WHEN 1 = 1 THEN 5
		WHEN 1 = 1 THEN 5
		WHEN 1 = 1 THEN 5
	    ELSE 7
	  end * interval '1 days' as "Days"; -- 5 days

SELECT 'ALI ' || CASE WHEN 1 = 1 THEN 'True' ELSE 'False' END as "Test"; -- ALI true



SELECT array[1, 2, 3] || array[4, 5, 6]; -- {1,2,3,4,5,6}

SELECT 4 in array[4, 5, 6]; -- error

SELECT 4 = ANY (array[4, 5, 6]); -- true

SELECT 4 != ALL (array[4, 5, 6]); -- false -> []











