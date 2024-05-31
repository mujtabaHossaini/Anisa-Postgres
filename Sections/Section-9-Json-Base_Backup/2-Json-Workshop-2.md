# Basics of JSON

Over the past 15 years, JSON has become the default system-to-system data transmission protocol. It’s simple, flexible, and expandable. APIs have adopted JSON. User authentication systems use JSON. Many years after it was created, it was solidified as an official standard: [RFC 7159](https://www.rfc-editor.org/rfc/rfc7159).

Postgres has two JSON datatypes: JSONB and *JSON*. JSONB is an optimized binary version of JSON, which is slower to store, but is optimized for querying and processing. *JSON* is an exact copy of the data with limited query functionality. In this tutorial, we will exclusively use JSONB.

## The JSONB data type

Within Postgres, JSONB is just a datatype. As with many data types, it comes with it’s own set of functions. Within Postgres, these functions provide an ability to do extract, compare, create, and manipulate *JSONB*. Covering the full possibilities (and caveats) of JSONB would take forever, this tutorial aims to nudge you along that path to do your own exploration.

First, a simple JSONB object can be as simple as the following:

```pgsql
SELECT'{"name": "batman", "superpower": "fighting skills"}'::jsonb;
```

Arrays can be the top-level element of JSONB:

```pgsql
SELECT'["batman", "superman"]'::jsonb;
```

JSONB can be objects nested inside of an array. With arrays and objects, you can take the structure as deep as you like!

```pgsql
SELECT'[{"name": "batman"}, {"name": "superman"}]'::jsonb;
```

Using `jsonb_to_recordset`, we can turn a array into a set of records:

```pgsql
SELECT
	* 
FROM jsonb_to_recordset('[{"name": "batman"}, {"name": "superman"}]'::jsonb) AS x(name TEXT);
```

As we just showed converting from *JSON* to set of records, we can also convert from set of records back to JSON*.* You can turn any object into JSONB, including a row in your table:

```pgsql
COPYSELECT
	to_jsonb(employees) 
FROM employees
LIMIT 5;
```

If you want to filter the columns, do the following:

```pgsql
COPY SELECT 
	to_jsonb(truncated_employees) 
FROM (
	SELECT first_name, last_name FROM employees LIMIT 10
) AS truncated_employees;
```

## Extracting data from JSONB data

There are two different ways to extract data from JSONB data: operators and JSONPath. Operators are like the following.

```pgsql
SELECT
	('{"name": "batman", "superpower": "fighting skills"}'::jsonb)->'name';
```

Above, we extract the name from the json object using the `->` operator. Notice this example and the following are using a slightly different, yet similar operator. We will explain the difference later. Next, we extract the first value of an array:

```pgsql
SELECT
	('[{"name": "batman"}, {"name": "superman"}]'::jsonb)[0]->>'name';
```

We used array notation `[0]` to return the first element of the array, then used the `->>` operator to return the value of the name attribute.



For top-level array, use the `0` as the value to be retrieved:

```pgsql
SELECT
	('["batman", "superman"]'::jsonb)->>0;
```



If you look at the [Postgres JSON functions](https://www.postgresql.org/docs/13/functions-json.html), you’ll see a large list of JSON manipulation and querying operators.

Above are examples using operators, and below, we will use JSONPath. JSONPath allows for more expressive manipulation and extracting. Below, we replicate the 2 prior examples using JSONPath instead of operators:

And, if you wanted to run the query on the array, it would look like the following:

```pgsql
SELECT
	jsonb_path_query(('[{"name": "batman"}, {"name": "superman"}]'::jsonb), '$[0].name');
```

But wait! There is more. With JSONPath, you can also extract values of objects within an array with the `$.key` syntax:

```pgsql
SELECT
	jsonb_path_query(('[{"name": "batman"}, {"name": "superman"}]'::jsonb), '$.name');
```

JSONPath is much deeper than this. You can perform many actions that Javascript also permits, like math, Regex, string operations, and more.

## Creating a JSONB column

Creating a JSONB column is similar to creating any column. Below, we add a `my_new_json_column` column to the employees table:

```pgsql
COPYALTER TABLE employees ADD COLUMN my_new_json_column JSONB DEFAULT NULL;
```

This statement uses the `ALTER TABLE` command to add columns with a datatype of JSONB.

## Inserting data into JSONB column

Inserting a new record into JSONB is as simple as:

```pgsql
COPYINSERT INTO employees (first_name, last_name, start_date, job_title, systems_access) VALUES ('Chris', 'Winslett', current_date, 'Master of the Highwire', '{"crm": 1662186380, "helpdesk": 1663290134, "admin_panel": null}');
```

Above, we are using an object with keys that represent the names of the system, and an epoch timestamp to represent the last time that person accessed that particular system.

## Top-level Object: How to query

For the top-level object query, we’ll use the `systems_access` column. It has been populated with a 1-layer object that has key-value pairs where the key represents a system, and the value represents the epoch timestamp of the last time the person interacted with the system, for example:

```pgsql
{
	"crm": 1663290134.655640, 
	"helpdesk": 1662186380.689519, 
	"admin_panel": null
}
```



*We’ve chosen EPOCH timestamps because it allows us to avoid some complexity of date-conversion. By using a float, in later examples, we can index a float contained within JSONB simply, while a date would introduce a bit more complexity than a tutorial warrants. The specific complexity is because casting text as a date is not immutable, and thus cannot be used to build index.*

Let’s return this JSONB object as part of a SELECT statement:

```pgsql
SELECT
	systems_access 
FROM employees 
WHERE id = 1;
```

We can even retrieve values within `systems_access`. Below, we return the values within the `crm` and `helpdesk` keys using two different operators:

```pgsql
SELECT
	systems_access->'crm' AS crm_value, 
	systems_access->>'helpdesk' AS helpdesk_value 
FROM employees 
WHERE id = 1;
```

What data types are getting returned? Below, we use `pg_typeof` to inspect the data types being returned:

```pgsql
SELECT
	pg_typeof(systems_access->'crm') AS crm_type, 
	pg_typeof(systems_access->>'helpdesk') AS helpdesk_type 
FROM employees 
WHERE id = 1;
```

Wow. One is `jsonb` and the other is `text`, but why? 

If you look closely at the query, when returning the `crm` value, we use `->` and when returning the `helpdesk` value, we use `->>`. This syntax difference is important because of the data type returned.

As you can imagine, knowing the type of object returned is important for the comparisons required of conditionals. Postgres, unlike Javascript, requires fairly explicit datatypes to get the comparisons correct (with the exception being dates, but that is a different tutorial).

Let’s run a query for everyone who has accessed the `crm` within the past 7 days. Said another way, how can we apply a conditional for the `crm` key within the `systems_access` JSONB field? Below is a query that will filter those values. Can we run something like the following?

```pgsql
SELECT
	first_name, 
	last_name 
FROM employees 
WHERE systems_access->>'crm' > EXTRACT('epoch' FROM now() - '7 day'::interval);
```

But, the answer is ‘no’, because we get the error message:

```plain
ERROR:  operator does not exist: text > numeric
LINE 5: WHERE systems_access->>'crm' > EXTRACT('epoch' FROM now() - ...
```

Postgres does not compare text with numeric. Why was `systems_access->>'crm'` text and not numeric? When storing JSONB, every value is text. We have 2 options: either compare equality as text or cast as numeric. *Comparing as a text would render the incorrect result.*

```pgsql
SELECT
	first_name, 
	last_name 
FROM employees 
WHERE 
	(systems_access->>'crm')::float > EXTRACT('epoch' FROM now() - '7 day'::interval);
```

Now, a command is properly run! And it returns the records you want. Hit the `q` key to exit the long list. To see those who have never accessed, let’s find those with NULL values for the CRM:

```pgsql
SELECT
	first_name, 
	last_name
FROM employees
WHERE 
	(systems_access->>'crm') IS NULL;
```

Hit the `q` key to exit the long list. Experiment with the casting (e.g. `::float`) on this — try removing it. Does the casting matter for this comparison? As you explore JSONB querying in Postgres, remember there is a difference between `->` and `->>`, and how to cast values for proper comparison.

## Top-level Object: How to update

There are two ways to update a JSONB column: 1) update the entire data, or 2) update a portion of the data. Side note: for both, Postgres sees the change as an entire update, we just use functions to calculate the new value and avoid a round-trip from the application layer.

To update the entire column is simple:

```pgsql
COPYUPDATE employees 
SET 
	systems_access = '{"crm": 1661637946.452246, "helpdesk": 1658433308.494507, "admin_panel": null}' 
WHERE id = 1;
```

But, if we wanted to update a single value, we could do the following:

```pgsql
COPYUPDATE employees 
SET
	systems_access = systems_access || jsonb_build_object('admin_panel', extract(epoch from now())) 
WHERE id = 1;
```

The `||` operator merges the two objects, and overwrites the keys on the left object with the keys from the right object. And, we use `jsonb_build_object` create a new object where either value in the equal can be a variable.

## Top-level Object: Indexing with BTREE

We have a two methods to index top-level objects. Additionally, there are caveats for choosing the proper index. When indexing a single value, use of `BTREE` is optimal.

To start with a simple `BTREE` index, imagine we want to query based on the `systems_access` field with access to `crm`. For this index, we explicitly state the field while casting that field as an `int`.

```pgsql
COPYCREATE INDEX employees_systems_access_crm 
ON employees 
USING BTREE (((systems_access->>'crm')::float));
```

Then, when we run the following query, it works using the index:

```pgsql
COPYEXPLAIN SELECT 
	* 
FROM employees 
WHERE 
	(systems_access->>'crm')::float > extract('epoch' FROM now() - '3 day'::interval);
```

Running the above command, you’ll see that the output has an `Index cond`, indicating it used the index for lookup. If you don’t see the `Index cond`, then you’ll need to update the table stats by running `ANALYZE employees;`.

Experiment running the `EXPLAIN` command above. Try `DROP INDEX employees_systems_access_crm`, and re-run the `EXPLAIN`. Then, recreate the index and run `EXPLAIN`. Compare the outputs. Now, try changing the interval from 3 days to 10 days — notice that it reverts to a table scan? This is the Postgres optimizer using table statistics to determine a table scan is faster than an index scan. The relatively small dataset we are using means that indexes may be slower than table scans.

## Top-level Object: Indexing with GIN

When working with GIN indexes at these sandbox data sizes, the query optimizer does not always choose to use the index. We will walk through creating the index, but know that the optimizer will have a mind of its own. For performance, the `BTREE` method above is the most predictable method for indexing. None the less, we would like to show how GIN indexing may work as well.

What if we wanted to query any of the values of the `systems_access` field? Then, we would want to use GIN indexes for this.

```pgsql
COPYCREATE INDEX employees_systems_access ON employees USING GIN ((systems_access) jsonb_path_ops);
```

Now, let’s see if we can use the index as part of our query by using `EXPLAIN`:

```pgsql
COPYEXPLAIN SELECT 
	* 
FROM employees 
WHERE 
	systems_access @@ ('$.helpdesk > ' || extract('epoch' FROM now() - '3 day'::interval)::text)::jsonpath;
```

This query probably may not use an index because we’ll need to update the table statistics. To do that, run `ANALYZE employees;` , then re-run the query above.

Once it works, let me put a caveat here and say that the combination of the `jsonb_path_ops` declaration at index creation and the use of the `@@` operator are crucial for success. When using `GIN` indexes, match the operators you wish to match with the comparisons you wish to run. For instance, if we ran the following query, the index would not be used:

```pgsql
COPYEXPLAIN SELECT 
	* 
FROM employees 
WHERE 
	systems_access->>'helpdesk' = '1';
```

The take-away on this example is when using JSONB, building indexes and queries that use those indexes take time and understanding. If we removed the `jsonb_path_ops` when creating the index, the original query using the `@@` would also fail to use an index. Additionally, if the right side of your operator included two values, like `{"helpdesk": 1, "crm": 1}`, then it would also fail to use the index.

## Structuring Data

A note about data structures (aka schema): you may have heard the term “schema-less” with regards to JSON databases. That is a misnomer. All applications have defined data structures, the question is: which part of your application stack enforces the data structure? When using Postgres tables, the data structure is enforced at the database level. Typically, when using JSON, the data structure is enforced at the application level.

When designing JSON data, it is important to think about how you will use and query the data. We had many options for structuring the addresses data that can be found in the employees table. For instance, we could have used the following structure — spend a few seconds comparing it to the value we used above.

```json
{
	"home": {
		"street": "698 Candlewood Lane", 
		"city": "Cabot Cove", 
		"state": "Maine", 
		"country": "United States"
	}
}
```



The above isn’t wrong — but I wanted to make some examples about updating arrays later. I would argue the above syntax is simpler for our use case, unless you want to index it. Why is indexing harder? To extract values, the keys (i.e. `home`) may be different than expected. We could also use a top-level address, but then we cannot store multiple addresses.

A lot of thought and experimentation should go into designing *JSON*, some of which is best learned through experience. In the end, go forth, make mistakes, and move forward. Nothing is ever “schema-less.”