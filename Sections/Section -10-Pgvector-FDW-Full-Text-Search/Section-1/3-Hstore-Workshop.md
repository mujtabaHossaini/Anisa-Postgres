# [PostgreSQL hstore](https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-hstore/)

**Summary**: in this tutorial, you’ll learn how to work with **PostgreSQL hstore** data type.

The hstore module implements the hstore data type for storing key-value pairs in a single value. The keys and values are text strings only.

In practice, you can find the hstore data type useful in some cases, such as semi-structured data or rows with many attributes that are rarely queried.

## Enable PostgreSQL hstore extension

Before working with the hstore data type, you need to enable the hstore extension which loads the **contrib** module to your PostgreSQL instance.

The following statement creates the hstore extension:

```
CREATE EXTENSION hstore;Code language: SQL (Structured Query Language) (sql)
```

## Create a table with hstore data type

We create a table named `books` that has three columns:

-  `id` is the primary key that identifies the book.
-  `title` is the title of the products
-  `attr` stores attributes of the book such as ISBN, weight, and paperback. The data type of the `attr` column is hstore.

We use the [CREATE TABLE statement](https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-create-table/) to create the `books` table as follows:

```
CREATE TABLE books (
	id serial primary key,
	title VARCHAR (255),
	attr hstore
);Code language: SQL (Structured Query Language) (sql)
```

## Insert data into the PostgreSQL hstore column

The following `INSERT` statement inserts data into the hstore column:

```
INSERT INTO books (title, attr) 
VALUES 
  (
    'PostgreSQL Tutorial', '"paperback" => "243",
     "publisher" => "postgresqltutorial.com",
     "language"  => "English",
     "ISBN-13"   => "978-1449370000",
     "weight"    => "11.2 ounces"'
  );
Code language: SQL (Structured Query Language) (sql)
```

The data that we insert into the hstore column is a list of comma-separated key =>value pairs. Both keys and values are quoted using double quotes (“”).

Let’s insert one more row.

```
INSERT INTO books (title, attr) 
VALUES 
  (
    'PostgreSQL Cheat Sheet', '
"paperback" => "5",
"publisher" => "postgresqltutorial.com",
"language"  => "English",
"ISBN-13"   => "978-1449370001",
"weight"    => "1 ounces"'
  );
Code language: SQL (Structured Query Language) (sql)
```

## Query data from an hstore column

Querying data from an hstore column is similar to querying data from a column with native data type using the `SELECT` statement as follows:

```
SELECT attr FROM books;
```

[![postgresql hstore query](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-query.jpg)](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-query.jpg)

## Query value for a specific key

Postgresql hstore provides the `->` operator to query the value of a specific key from an hstore column. For example, if we want to know ISBN-13 of all available books in the `books` table, we can use the `->` operator as follows:

```
SELECT
	attr -> 'ISBN-13' AS isbn
FROM
	books;
```

![postgresql hstore query key](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-query-key.jpg)

## Use value in the WHERE clause

You can use the `->` operator in the `WHERE` clause to filter the rows whose values of the hstore column match the input value. For example, the following  query retrieves the `title` and `weight` of a book that has `ISBN-13` value matches `978-1449370000:`

```
SELECT
	title, attr -> 'weight' AS weight
FROM
	books
WHERE
	attr -> 'ISBN-13' = '978-1449370000';

```

![postgresql hstore WHERE clause](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-WHERE-clause.jpg)

## Add key-value pairs to existing rows

With a hstore column, you can easily add a new key-value pair to existing rows e.g., you can add a free shipping key to the `attr` column of the `books` table as follows:

```
UPDATE books
SET attr = attr || '"freeshipping"=>"yes"' :: hstore;
```

Now, you can check to see if the `"freeshipping" => "yes"` pair has been added successfully.

```
SELECT
	title,
        attr -> 'freeshipping' AS freeshipping
FROM
	books;
```

![postgresql hstore add key-value](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-add-key-value.jpg)

## Update existing key-value pair

You can update the existing key-value pair using the `UPDATE` statement. The following statement updates the value of the `"freeshipping"` key to `"no"`.

```
UPDATE books
SET attr = attr || '"freeshipping"=>"no"' :: hstore;
```

## Remove existing key-value pair

PostgreSQL allows you to remove existing key-value pair from an hstore column. For example, the following statement removes the `"freeshipping"=>"no"` key-value pair in the `attr` column.

```
UPDATE books 
SET attr = delete(attr, 'freeshipping');Code language: SQL (Structured Query Language) (sql)
```

## Check for a specific key in hstore column

You can check for a specific key in an hstore column using the `?` operator in the `WHERE` clause. For example, the following statement returns all rows with attr contains key `publisher`.

```
SELECT
  title,
  attr->'publisher' as publisher,
  attr
FROM
	books
WHERE
	attr ? 'publisher'
```

![postgesql hstore check key](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgesql-hstore-check-key.jpg)

## Check for a key-value pair

You can query based on the hstore key-value pair using the @> operator. The following statement retrieves all rows whose `attr` column contains a key-value pair that matches `"weight"=>"11.2 ounces"`.

```
SELECT
	title
FROM
	books
WHERE
	attr @> '"weight"=>"11.2 ounces"' :: hstore;
```

![postgresql hstore check key-pair](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-check-key-pair.jpg)

## Query rows that contain multiple specified keys

You can query the rows whose hstore column contains multiple keys using `?&` operator. For example, you can get books where `attr` column contains both `language` and `weight` keys.

```
SELECT
	title
FROM
	books
WHERE
	attr ?& ARRAY [ 'language', 'weight' ];
```

![postgresql hstore check multiple keys](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-check-multiple-keys.jpg)

To check if a row whose hstore column contains any key from a list of keys, you use the `?|` operator instead of the `?&` operator.

## Get all keys from an hstore column

To get all keys from an hstore column, you use the `akeys()` function as follows:

```
SELECT
	akeys (attr)
FROM
	books;Code language: SQL (Structured Query Language) (sql)
```

![postgresql hstore akeys function](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-akeys-function.jpg)

Or you can use the `skey()` function if you want PostgreSQL to return the result as a set.

```
SELECT
	skeys (attr)
FROM
	books;
```

![postgresql hstore skeys function](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-skeys-function.jpg)

## Get all values from an hstore column

Like keys, you can get all values from an hstore column using the  `avals()` function in the form of arrays.

```
SELECT
	avals (attr)
FROM
	books;
```

[![postgresql hstore avals function](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-avals-function.jpg)](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-avals-function.jpg)

Or you can use the  `svals()` function if you want to get the result as a set.

```
SELECT
	svals (attr)
FROM
	books;
```

![postgresql hstore svals](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-svals.jpg)

## Convert hstore data to JSON

PostgreSQL provides the `hstore_to_json()` function to convert hstore data to [JSON](https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-json/). See the following statement:

```
SELECT
  title,
  hstore_to_json (attr) json
FROM
  books;
```

![postgresql hstore to json](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-to-json.jpg)

## Convert hstore data to sets

To convert hstore data to sets, you use the  `each()` function as follows:

```
SELECT
	title,
	(EACH(attr) ).*
FROM
	books;
```

![postgresql hstore to sets](https://www.postgresqltutorial.com/wp-content/uploads/2015/07/postgresql-hstore-to-sets.jpg)

In this tutorial, we have shown you how to work with the PostgreSQL hstore data type and introduced you to the most useful operations that you can perform against the hstore data type.