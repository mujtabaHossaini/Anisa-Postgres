## [Arrays](https://www.postgresql.org/docs/current/arrays.html) 

- [8.15.1. Declaration of Array Types](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-DECLARATION)
- [8.15.2. Array Value Input](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-INPUT)
- [8.15.3. Accessing Arrays](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-ACCESSING)
- [8.15.4. Modifying Arrays](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-MODIFYING)
- [8.15.5. Searching in Arrays](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-SEARCHING)
- [8.15.6. Array Input and Output Syntax](https://www.postgresql.org/docs/current/arrays.html#ARRAYS-IO)



PostgreSQL allows columns of a table to be defined as variable-length multidimensional arrays. Arrays of any built-in or user-defined base type, enum type, composite type, range type, or domain can be created.

### 8.15.1. Declaration of Array Types 



To illustrate the use of array types, we create this table:

```
CREATE TABLE sal_emp (
    name            text,
    pay_by_quarter  integer[],
    schedule        text[][]
);
```

As shown, an array data type is named by appending square brackets (`[]`) to the data type name of the array elements. The above command will create a table named `sal_emp` with a column of type `text` (`name`), a one-dimensional array of type `integer` (`pay_by_quarter`), which represents the employee's salary by quarter, and a two-dimensional array of `text` (`schedule`), which represents the employee's weekly schedule.

The syntax for `CREATE TABLE` allows the exact size of arrays to be specified, for example:

```
CREATE TABLE tictactoe (
    squares   integer[3][3]
);
```

However, the current implementation ignores any supplied array size limits, i.e., the behavior is the same as for arrays of unspecified length.

The current implementation does not enforce the declared number of dimensions either. Arrays of a particular element type are all considered to be of the same type, regardless of size or number of dimensions. So, declaring the array size or number of dimensions in `CREATE TABLE` is simply documentation; it does not affect run-time behavior.

An alternative syntax, which conforms to the SQL standard by using the keyword `ARRAY`, can be used for one-dimensional arrays. `pay_by_quarter` could have been defined as:

```
    pay_by_quarter  integer ARRAY[4],
```

Or, if no array size is to be specified:

```
    pay_by_quarter  integer ARRAY,
```

As before, however, PostgreSQL does not enforce the size restriction in any case.

### 8.15.2. Array Value Input 



To write an array value as a literal constant, enclose the element values within curly braces and separate them by commas. (If you know C, this is not unlike the C syntax for initializing structures.) You can put double quotes around any element value, and must do so if it contains commas or curly braces. (More details appear below.) Thus, the general format of an array constant is the following:

```
'{ val1 delim val2 delim ... }'
```

where *`delim`* is the delimiter character for the type, as recorded in its `pg_type` entry. Among the standard data types provided in the PostgreSQL distribution, all use a comma (`,`), except for type `box` which uses a semicolon (`;`). Each *`val`* is either a constant of the array element type, or a subarray. An example of an array constant is:

```
'{{1,2,3},{4,5,6},{7,8,9}}'
```

This constant is a two-dimensional, 3-by-3 array consisting of three subarrays of integers.

To set an element of an array constant to NULL, write `NULL` for the element value. (Any upper- or lower-case variant of `NULL` will do.) If you want an actual string value “NULL”, you must put double quotes around it.

(These kinds of array constants are actually only a special case of the generic type constants discussed in [Section 4.1.2.7](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS-GENERIC). The constant is initially treated as a string and passed to the array input conversion routine. An explicit type specification might be necessary.)

Now we can show some `INSERT` statements:

```
INSERT INTO sal_emp
    VALUES ('Bill',
    '{10000, 10000, 10000, 10000}',
    '{{"meeting", "lunch"}, {"training", "presentation"}}');

INSERT INTO sal_emp
    VALUES ('Carol',
    '{20000, 25000, 25000, 25000}',
    '{{"breakfast", "consulting"}, {"meeting", "lunch"}}');
```

The result of the previous two inserts looks like this:

```
SELECT * FROM sal_emp;
 name  |      pay_by_quarter       |                 schedule
-------+---------------------------+-------------------------------------------
 Bill  | {10000,10000,10000,10000} | {{meeting,lunch},{training,presentation}}
 Carol | {20000,25000,25000,25000} | {{breakfast,consulting},{meeting,lunch}}
(2 rows)
```

Multidimensional arrays must have matching extents for each dimension. A mismatch causes an error, for example:

```
INSERT INTO sal_emp
    VALUES ('Bill',
    '{10000, 10000, 10000, 10000}',
    '{{"meeting", "lunch"}, {"meeting"}}');
ERROR:  multidimensional arrays must have array expressions with matching dimensions
```

The `ARRAY` constructor syntax can also be used:

```
INSERT INTO sal_emp
    VALUES ('Bill',
    ARRAY[10000, 10000, 10000, 10000],
    ARRAY[['meeting', 'lunch'], ['training', 'presentation']]);

INSERT INTO sal_emp
    VALUES ('Carol',
    ARRAY[20000, 25000, 25000, 25000],
    ARRAY[['breakfast', 'consulting'], ['meeting', 'lunch']]);
```

Notice that the array elements are ordinary SQL constants or expressions; for instance, string literals are single quoted, instead of double quoted as they would be in an array literal. The `ARRAY` constructor syntax is discussed in more detail in [Section 4.2.12](https://www.postgresql.org/docs/current/sql-expressions.html#SQL-SYNTAX-ARRAY-CONSTRUCTORS).

### 8.15.3. Accessing Arrays 



Now, we can run some queries on the table. First, we show how to access a single element of an array. This query retrieves the names of the employees whose pay changed in the second quarter:

```
SELECT name FROM sal_emp WHERE pay_by_quarter[1] <> pay_by_quarter[2];

 name
-------
 Carol
(1 row)
```

The array subscript numbers are written within square brackets. By default PostgreSQL uses a one-based numbering convention for arrays, that is, an array of *`n`* elements starts with `array[1]` and ends with `array[*`n`*]`.

This query retrieves the third quarter pay of all employees:

```
SELECT pay_by_quarter[3] FROM sal_emp;

 pay_by_quarter
----------------
          10000
          25000
(2 rows)
```

We can also access arbitrary rectangular slices of an array, or subarrays. An array slice is denoted by writing `*`lower-bound`*:*`upper-bound`*` for one or more array dimensions. For example, this query retrieves the first item on Bill's schedule for the first two days of the week:

```
SELECT schedule[1:2][1:1] FROM sal_emp WHERE name = 'Bill';

        schedule
------------------------
 {{meeting},{training}}
(1 row)
```

If any dimension is written as a slice, i.e., contains a colon, then all dimensions are treated as slices. Any dimension that has only a single number (no colon) is treated as being from 1 to the number specified. For example, `[2]` is treated as `[1:2]`, as in this example:

```
SELECT schedule[1:2][2] FROM sal_emp WHERE name = 'Bill';

                 schedule
-------------------------------------------
 {{meeting,lunch},{training,presentation}}
(1 row)
```

To avoid confusion with the non-slice case, it's best to use slice syntax for all dimensions, e.g., `[1:2][1:1]`, not `[2][1:1]`.

It is possible to omit the *`lower-bound`* and/or *`upper-bound`* of a slice specifier; the missing bound is replaced by the lower or upper limit of the array's subscripts. For example:

```
SELECT schedule[:2][2:] FROM sal_emp WHERE name = 'Bill';

        schedule
------------------------
 {{lunch},{presentation}}
(1 row)

SELECT schedule[:][1:1] FROM sal_emp WHERE name = 'Bill';

        schedule
------------------------
 {{meeting},{training}}
(1 row)
```

An array subscript expression will return null if either the array itself or any of the subscript expressions are null. Also, null is returned if a subscript is outside the array bounds (this case does not raise an error). For example, if `schedule` currently has the dimensions `[1:3][1:2]` then referencing `schedule[3][3]` yields NULL. Similarly, an array reference with the wrong number of subscripts yields a null rather than an error.

An array slice expression likewise yields null if the array itself or any of the subscript expressions are null. However, in other cases such as selecting an array slice that is completely outside the current array bounds, a slice expression yields an empty (zero-dimensional) array instead of null. (This does not match non-slice behavior and is done for historical reasons.) If the requested slice partially overlaps the array bounds, then it is silently reduced to just the overlapping region instead of returning null.

The current dimensions of any array value can be retrieved with the `array_dims` function:

```
SELECT array_dims(schedule) FROM sal_emp WHERE name = 'Carol';

 array_dims
------------
 [1:2][1:2]
(1 row)
```

`array_dims` produces a `text` result, which is convenient for people to read but perhaps inconvenient for programs. Dimensions can also be retrieved with `array_upper` and `array_lower`, which return the upper and lower bound of a specified array dimension, respectively:

```
SELECT array_upper(schedule, 1) FROM sal_emp WHERE name = 'Carol';

 array_upper
-------------
           2
(1 row)
```

`array_length` will return the length of a specified array dimension:

```
SELECT array_length(schedule, 1) FROM sal_emp WHERE name = 'Carol';

 array_length
--------------
            2
(1 row)
```

`cardinality` returns the total number of elements in an array across all dimensions. It is effectively the number of rows a call to `unnest` would yield:

```
SELECT cardinality(schedule) FROM sal_emp WHERE name = 'Carol';

 cardinality
-------------
           4
(1 row)
```

### 8.15.4. Modifying Arrays 



An array value can be replaced completely:

```
UPDATE sal_emp SET pay_by_quarter = '{25000,25000,27000,27000}'
    WHERE name = 'Carol';
```

or using the `ARRAY` expression syntax:

```
UPDATE sal_emp SET pay_by_quarter = ARRAY[25000,25000,27000,27000]
    WHERE name = 'Carol';
```

An array can also be updated at a single element:

```
UPDATE sal_emp SET pay_by_quarter[4] = 15000
    WHERE name = 'Bill';
```

or updated in a slice:

```
UPDATE sal_emp SET pay_by_quarter[1:2] = '{27000,27000}'
    WHERE name = 'Carol';
```

The slice syntaxes with omitted *`lower-bound`* and/or *`upper-bound`* can be used too, but only when updating an array value that is not NULL or zero-dimensional (otherwise, there is no existing subscript limit to substitute).

A stored array value can be enlarged by assigning to elements not already present. Any positions between those previously present and the newly assigned elements will be filled with nulls. For example, if array `myarray` currently has 4 elements, it will have six elements after an update that assigns to `myarray[6]`; `myarray[5]` will contain null. Currently, enlargement in this fashion is only allowed for one-dimensional arrays, not multidimensional arrays.

Subscripted assignment allows creation of arrays that do not use one-based subscripts. For example one might assign to `myarray[-2:7]` to create an array with subscript values from -2 to 7.

New array values can also be constructed using the concatenation operator, `||`:

```
SELECT ARRAY[1,2] || ARRAY[3,4];
 ?column?
-----------
 {1,2,3,4}
(1 row)

SELECT ARRAY[5,6] || ARRAY[[1,2],[3,4]];
      ?column?
---------------------
 {{5,6},{1,2},{3,4}}
(1 row)
```

The concatenation operator allows a single element to be pushed onto the beginning or end of a one-dimensional array. It also accepts two *`N`*-dimensional arrays, or an *`N`*-dimensional and an *`N+1`*-dimensional array.

When a single element is pushed onto either the beginning or end of a one-dimensional array, the result is an array with the same lower bound subscript as the array operand. For example:

```
SELECT array_dims(1 || '[0:1]={2,3}'::int[]);
 array_dims
------------
 [0:2]
(1 row)

SELECT array_dims(ARRAY[1,2] || 3);
 array_dims
------------
 [1:3]
(1 row)
```

When two arrays with an equal number of dimensions are concatenated, the result retains the lower bound subscript of the left-hand operand's outer dimension. The result is an array comprising every element of the left-hand operand followed by every element of the right-hand operand. For example:

```
SELECT array_dims(ARRAY[1,2] || ARRAY[3,4,5]);
 array_dims
------------
 [1:5]
(1 row)

SELECT array_dims(ARRAY[[1,2],[3,4]] || ARRAY[[5,6],[7,8],[9,0]]);
 array_dims
------------
 [1:5][1:2]
(1 row)
```

When an *`N`*-dimensional array is pushed onto the beginning or end of an *`N+1`*-dimensional array, the result is analogous to the element-array case above. Each *`N`*-dimensional sub-array is essentially an element of the *`N+1`*-dimensional array's outer dimension. For example:

```
SELECT array_dims(ARRAY[1,2] || ARRAY[[3,4],[5,6]]);
 array_dims
------------
 [1:3][1:2]
(1 row)
```

An array can also be constructed by using the functions `array_prepend`, `array_append`, or `array_cat`. The first two only support one-dimensional arrays, but `array_cat` supports multidimensional arrays. Some examples:

```
SELECT array_prepend(1, ARRAY[2,3]);
 array_prepend
---------------
 {1,2,3}
(1 row)

SELECT array_append(ARRAY[1,2], 3);
 array_append
--------------
 {1,2,3}
(1 row)

SELECT array_cat(ARRAY[1,2], ARRAY[3,4]);
 array_cat
-----------
 {1,2,3,4}
(1 row)

SELECT array_cat(ARRAY[[1,2],[3,4]], ARRAY[5,6]);
      array_cat
---------------------
 {{1,2},{3,4},{5,6}}
(1 row)

SELECT array_cat(ARRAY[5,6], ARRAY[[1,2],[3,4]]);
      array_cat
---------------------
 {{5,6},{1,2},{3,4}}
```

In simple cases, the concatenation operator discussed above is preferred over direct use of these functions. However, because the concatenation operator is overloaded to serve all three cases, there are situations where use of one of the functions is helpful to avoid ambiguity. For example consider:

```
SELECT ARRAY[1, 2] || '{3, 4}';  -- the untyped literal is taken as an array
 ?column?
-----------
 {1,2,3,4}

SELECT ARRAY[1, 2] || '7';                 -- so is this one
ERROR:  malformed array literal: "7"

SELECT ARRAY[1, 2] || NULL;                -- so is an undecorated NULL
 ?column?
----------
 {1,2}
(1 row)

SELECT array_append(ARRAY[1, 2], NULL);    -- this might have been meant
 array_append
--------------
 {1,2,NULL}
```

In the examples above, the parser sees an integer array on one side of the concatenation operator, and a constant of undetermined type on the other. The heuristic it uses to resolve the constant's type is to assume it's of the same type as the operator's other input — in this case, integer array. So the concatenation operator is presumed to represent `array_cat`, not `array_append`. When that's the wrong choice, it could be fixed by casting the constant to the array's element type; but explicit use of `array_append` might be a preferable solution.

### 8.15.5. Searching in Arrays 



To search for a value in an array, each value must be checked. This can be done manually, if you know the size of the array. For example:

```
SELECT * FROM sal_emp WHERE pay_by_quarter[1] = 10000 OR
                            pay_by_quarter[2] = 10000 OR
                            pay_by_quarter[3] = 10000 OR
                            pay_by_quarter[4] = 10000;
```

However, this quickly becomes tedious for large arrays, and is not helpful if the size of the array is unknown. An alternative method is described in [Section 9.24](https://www.postgresql.org/docs/current/functions-comparisons.html). The above query could be replaced by:

```
SELECT * FROM sal_emp WHERE 10000 = ANY (pay_by_quarter);
```

In addition, you can find rows where the array has all values equal to 10000 with:

```
SELECT * FROM sal_emp WHERE 10000 = ALL (pay_by_quarter);
```

Alternatively, the `generate_subscripts` function can be used. For example:

```
SELECT * FROM
   (SELECT pay_by_quarter,
           generate_subscripts(pay_by_quarter, 1) AS s
      FROM sal_emp) AS foo
 WHERE pay_by_quarter[s] = 10000;
```

This function is described in [Table 9.66](https://www.postgresql.org/docs/current/functions-srf.html#FUNCTIONS-SRF-SUBSCRIPTS).

You can also search an array using the `&&` operator, which checks whether the left operand overlaps with the right operand. For instance:

```
SELECT * FROM sal_emp WHERE pay_by_quarter && ARRAY[10000];
```

This and other array operators are further described in [Section 9.19](https://www.postgresql.org/docs/current/functions-array.html). It can be accelerated by an appropriate index, as described in [Section 11.2](https://www.postgresql.org/docs/current/indexes-types.html).

You can also search for specific values in an array using the `array_position` and `array_positions` functions. The former returns the subscript of the first occurrence of a value in an array; the latter returns an array with the subscripts of all occurrences of the value in the array. For example:

```
SELECT array_position(ARRAY['sun','mon','tue','wed','thu','fri','sat'], 'mon');
 array_position
----------------
              2
(1 row)

SELECT array_positions(ARRAY[1, 4, 3, 1, 3, 4, 2, 1], 1);
 array_positions
-----------------
 {1,4,8}
(1 row)
```



## [hstore — hstore key/value datatype](https://www.postgresql.org/docs/current/hstore.html#HSTORE)

- [F.18.1. `hstore` External Representation](https://www.postgresql.org/docs/current/hstore.html#HSTORE-EXTERNAL-REP)
- [F.18.2. `hstore` Operators and Functions](https://www.postgresql.org/docs/current/hstore.html#HSTORE-OPS-FUNCS)
- [F.18.3. Indexes](https://www.postgresql.org/docs/current/hstore.html#HSTORE-INDEXES)
- [F.18.4. Examples](https://www.postgresql.org/docs/current/hstore.html#HSTORE-EXAMPLES)
- [F.18.5. Statistics](https://www.postgresql.org/docs/current/hstore.html#HSTORE-STATISTICS)
- [F.18.6. Compatibility](https://www.postgresql.org/docs/current/hstore.html#HSTORE-COMPATIBILITY)
- [F.18.7. Transforms](https://www.postgresql.org/docs/current/hstore.html#HSTORE-TRANSFORMS)
- [F.18.8. Authors](https://www.postgresql.org/docs/current/hstore.html#HSTORE-AUTHORS)



This module implements the `hstore` data type for storing sets of key/value pairs within a single PostgreSQL value. This can be useful in various scenarios, such as rows with many attributes that are rarely examined, or semi-structured data. Keys and values are simply text strings.

This module is considered “trusted”, that is, it can be installed by non-superusers who have `CREATE` privilege on the current database.

### F.18.1. `hstore` External Representation 

The text representation of an `hstore`, used for input and output, includes zero or more *`key`* `=>` *`value`* pairs separated by commas. Some examples:

```
k => v
foo => bar, baz => whatever
"1-a" => "anything at all"
```

The order of the pairs is not significant (and may not be reproduced on output). Whitespace between pairs or around the `=>` sign is ignored. Double-quote keys and values that include whitespace, commas, `=`s or `>`s. To include a double quote or a backslash in a key or value, escape it with a backslash.

Each key in an `hstore` is unique. If you declare an `hstore` with duplicate keys, only one will be stored in the `hstore` and there is no guarantee as to which will be kept:

```
SELECT 'a=>1,a=>2'::hstore;
  hstore
----------
 "a"=>"1"
```

A value (but not a key) can be an SQL `NULL`. For example:

```
key => NULL
```

The `NULL` keyword is case-insensitive. Double-quote the `NULL` to treat it as the ordinary string “NULL”.

### Note

Keep in mind that the `hstore` text format, when used for input, applies *before* any required quoting or escaping. If you are passing an `hstore` literal via a parameter, then no additional processing is needed. But if you're passing it as a quoted literal constant, then any single-quote characters and (depending on the setting of the `standard_conforming_strings` configuration parameter) backslash characters need to be escaped correctly. See [Section 4.1.2.1](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS) for more on the handling of string constants.

On output, double quotes always surround keys and values, even when it's not strictly necessary.

### F.18.2. `hstore` Operators and Functions 

The operators provided by the `hstore` module are shown in [Table F.7](https://www.postgresql.org/docs/current/hstore.html#HSTORE-OP-TABLE), the functions in [Table F.8](https://www.postgresql.org/docs/current/hstore.html#HSTORE-FUNC-TABLE).

**Table F.7. `hstore` Operators**

| OperatorDescriptionExample(s)                                |
| ------------------------------------------------------------ |
| `hstore` `->` `text` → `text`Returns value associated with given key, or `NULL` if not present.`'a=>x, b=>y'::hstore -> 'a'` → `x` |
| `hstore` `->` `text[]` → `text[]`Returns values associated with given keys, or `NULL` if not present.`'a=>x, b=>y, c=>z'::hstore -> ARRAY['c','a']` → `{"z","x"}` |
| `hstore` `||` `hstore` → `hstore`Concatenates two `hstore`s.`'a=>b, c=>d'::hstore || 'c=>x, d=>q'::hstore` → `"a"=>"b", "c"=>"x", "d"=>"q"` |
| `hstore` `?` `text` → `boolean`Does `hstore` contain key?`'a=>1'::hstore ? 'a'` → `t` |
| `hstore` `?&` `text[]` → `boolean`Does `hstore` contain all the specified keys?`'a=>1,b=>2'::hstore ?& ARRAY['a','b']` → `t` |
| `hstore` `?|` `text[]` → `boolean`Does `hstore` contain any of the specified keys?`'a=>1,b=>2'::hstore ?| ARRAY['b','c']` → `t` |
| `hstore` `@>` `hstore` → `boolean`Does left operand contain right?`'a=>b, b=>1, c=>NULL'::hstore @> 'b=>1'` → `t` |
| `hstore` `<@` `hstore` → `boolean`Is left operand contained in right?`'a=>c'::hstore <@ 'a=>b, b=>1, c=>NULL'` → `f` |
| `hstore` `-` `text` → `hstore`Deletes key from left operand.`'a=>1, b=>2, c=>3'::hstore - 'b'::text` → `"a"=>"1", "c"=>"3"` |
| `hstore` `-` `text[]` → `hstore`Deletes keys from left operand.`'a=>1, b=>2, c=>3'::hstore - ARRAY['a','b']` → `"c"=>"3"` |
| `hstore` `-` `hstore` → `hstore`Deletes pairs from left operand that match pairs in the right operand.`'a=>1, b=>2, c=>3'::hstore - 'a=>4, b=>2'::hstore` → `"a"=>"1", "c"=>"3"` |
| `anyelement` `#=` `hstore` → `anyelement`Replaces fields in the left operand (which must be a composite type) with matching values from `hstore`.`ROW(1,3) #= 'f1=>11'::hstore` → `(11,3)` |
| `%%` `hstore` → `text[]`Converts `hstore` to an array of alternating keys and values.`%% 'a=>foo, b=>bar'::hstore` → `{a,foo,b,bar}` |
| `%#` `hstore` → `text[]`Converts `hstore` to a two-dimensional key/value array.`%# 'a=>foo, b=>bar'::hstore` → `{{a,foo},{b,bar}}` |

**Table F.8. `hstore` Functions**

| FunctionDescriptionExample(s)                                |
| ------------------------------------------------------------ |
| `hstore` ( `record` ) → `hstore`Constructs an `hstore` from a record or row.`hstore(ROW(1,2))` → `"f1"=>"1", "f2"=>"2"` |
| `hstore` ( `text[]` ) → `hstore`Constructs an `hstore` from an array, which may be either a key/value array, or a two-dimensional array.`hstore(ARRAY['a','1','b','2'])` → `"a"=>"1", "b"=>"2"``hstore(ARRAY[['c','3'],['d','4']])` → `"c"=>"3", "d"=>"4"` |
| `hstore` ( `text[]`, `text[]` ) → `hstore`Constructs an `hstore` from separate key and value arrays.`hstore(ARRAY['a','b'], ARRAY['1','2'])` → `"a"=>"1", "b"=>"2"` |
| `hstore` ( `text`, `text` ) → `hstore`Makes a single-item `hstore`.`hstore('a', 'b')` → `"a"=>"b"` |
| `akeys` ( `hstore` ) → `text[]`Extracts an `hstore`'s keys as an array.`akeys('a=>1,b=>2')` → `{a,b}` |
| `skeys` ( `hstore` ) → `setof text`Extracts an `hstore`'s keys as a set.`skeys('a=>1,b=>2')` →`a b ` |
| `avals` ( `hstore` ) → `text[]`Extracts an `hstore`'s values as an array.`avals('a=>1,b=>2')` → `{1,2}` |
| `svals` ( `hstore` ) → `setof text`Extracts an `hstore`'s values as a set.`svals('a=>1,b=>2')` →`1 2 ` |
| `hstore_to_array` ( `hstore` ) → `text[]`Extracts an `hstore`'s keys and values as an array of alternating keys and values.`hstore_to_array('a=>1,b=>2')` → `{a,1,b,2}` |
| `hstore_to_matrix` ( `hstore` ) → `text[]`Extracts an `hstore`'s keys and values as a two-dimensional array.`hstore_to_matrix('a=>1,b=>2')` → `{{a,1},{b,2}}` |
| `hstore_to_json` ( `hstore` ) → `json`Converts an `hstore` to a `json` value, converting all non-null values to JSON strings.This function is used implicitly when an `hstore` value is cast to `json`.`hstore_to_json('"a key"=>1, b=>t, c=>null, d=>12345, e=>012345, f=>1.234, g=>2.345e+4')` → `{"a key": "1", "b": "t", "c": null, "d": "12345", "e": "012345", "f": "1.234", "g": "2.345e+4"}` |
| `hstore_to_jsonb` ( `hstore` ) → `jsonb`Converts an `hstore` to a `jsonb` value, converting all non-null values to JSON strings.This function is used implicitly when an `hstore` value is cast to `jsonb`.`hstore_to_jsonb('"a key"=>1, b=>t, c=>null, d=>12345, e=>012345, f=>1.234, g=>2.345e+4')` → `{"a key": "1", "b": "t", "c": null, "d": "12345", "e": "012345", "f": "1.234", "g": "2.345e+4"}` |
| `hstore_to_json_loose` ( `hstore` ) → `json`Converts an `hstore` to a `json` value, but attempts to distinguish numerical and Boolean values so they are unquoted in the JSON.`hstore_to_json_loose('"a key"=>1, b=>t, c=>null, d=>12345, e=>012345, f=>1.234, g=>2.345e+4')` → `{"a key": 1, "b": true, "c": null, "d": 12345, "e": "012345", "f": 1.234, "g": 2.345e+4}` |
| `hstore_to_jsonb_loose` ( `hstore` ) → `jsonb`Converts an `hstore` to a `jsonb` value, but attempts to distinguish numerical and Boolean values so they are unquoted in the JSON.`hstore_to_jsonb_loose('"a key"=>1, b=>t, c=>null, d=>12345, e=>012345, f=>1.234, g=>2.345e+4')` → `{"a key": 1, "b": true, "c": null, "d": 12345, "e": "012345", "f": 1.234, "g": 2.345e+4}` |
| `slice` ( `hstore`, `text[]` ) → `hstore`Extracts a subset of an `hstore` containing only the specified keys.`slice('a=>1,b=>2,c=>3'::hstore, ARRAY['b','c','x'])` → `"b"=>"2", "c"=>"3"` |
| `each` ( `hstore` ) → `setof record` ( *`key`* `text`, *`value`* `text` )Extracts an `hstore`'s keys and values as a set of records.`select * from each('a=>1,b=>2')` →` key | value -----+------- a   | 1 b   | 2 ` |
| `exist` ( `hstore`, `text` ) → `boolean`Does `hstore` contain key?`exist('a=>1', 'a')` → `t` |
| `defined` ( `hstore`, `text` ) → `boolean`Does `hstore` contain a non-`NULL` value for key?`defined('a=>NULL', 'a')` → `f` |
| `delete` ( `hstore`, `text` ) → `hstore`Deletes pair with matching key.`delete('a=>1,b=>2', 'b')` → `"a"=>"1"` |
| `delete` ( `hstore`, `text[]` ) → `hstore`Deletes pairs with matching keys.`delete('a=>1,b=>2,c=>3', ARRAY['a','b'])` → `"c"=>"3"` |
| `delete` ( `hstore`, `hstore` ) → `hstore`Deletes pairs matching those in the second argument.`delete('a=>1,b=>2', 'a=>4,b=>2'::hstore)` → `"a"=>"1"` |
| `populate_record` ( `anyelement`, `hstore` ) → `anyelement`Replaces fields in the left operand (which must be a composite type) with matching values from `hstore`.`populate_record(ROW(1,2), 'f1=>42'::hstore)` → `(42,2)` |

In addition to these operators and functions, values of the `hstore` type can be subscripted, allowing them to act like associative arrays. Only a single subscript of type `text` can be specified; it is interpreted as a key and the corresponding value is fetched or stored. For example,

```
CREATE TABLE mytable (h hstore);
INSERT INTO mytable VALUES ('a=>b, c=>d');
SELECT h['a'] FROM mytable;
 h
---
 b
(1 row)

UPDATE mytable SET h['c'] = 'new';
SELECT h FROM mytable;
          h
----------------------
 "a"=>"b", "c"=>"new"
(1 row)
```

A subscripted fetch returns `NULL` if the subscript is `NULL` or that key does not exist in the `hstore`. (Thus, a subscripted fetch is not greatly different from the `->` operator.) A subscripted update fails if the subscript is `NULL`; otherwise, it replaces the value for that key, adding an entry to the `hstore` if the key does not already exist.

### F.18.3. Indexes 

`hstore` has GiST and GIN index support for the `@>`, `?`, `?&` and `?|` operators. For example:

```
CREATE INDEX hidx ON testhstore USING GIST (h);

CREATE INDEX hidx ON testhstore USING GIN (h);
```

`gist_hstore_ops` GiST opclass approximates a set of key/value pairs as a bitmap signature. Its optional integer parameter `siglen` determines the signature length in bytes. The default length is 16 bytes. Valid values of signature length are between 1 and 2024 bytes. Longer signatures lead to a more precise search (scanning a smaller fraction of the index and fewer heap pages), at the cost of a larger index.

Example of creating such an index with a signature length of 32 bytes:

```
CREATE INDEX hidx ON testhstore USING GIST (h gist_hstore_ops(siglen=32));
```

`hstore` also supports `btree` or `hash` indexes for the `=` operator. This allows `hstore` columns to be declared `UNIQUE`, or to be used in `GROUP BY`, `ORDER BY` or `DISTINCT` expressions. The sort ordering for `hstore` values is not particularly useful, but these indexes may be useful for equivalence lookups. Create indexes for `=` comparisons as follows:

```
CREATE INDEX hidx ON testhstore USING BTREE (h);

CREATE INDEX hidx ON testhstore USING HASH (h);
```

### F.18.4. Examples 

Add a key, or update an existing key with a new value:

```
UPDATE tab SET h['c'] = '3';
```

Another way to do the same thing is:

```
UPDATE tab SET h = h || hstore('c', '3');
```

If multiple keys are to be added or changed in one operation, the concatenation approach is more efficient than subscripting:

```
UPDATE tab SET h = h || hstore(array['q', 'w'], array['11', '12']);
```

Delete a key:

```
UPDATE tab SET h = delete(h, 'k1');
```

Convert a `record` to an `hstore`:

```
CREATE TABLE test (col1 integer, col2 text, col3 text);
INSERT INTO test VALUES (123, 'foo', 'bar');

SELECT hstore(t) FROM test AS t;
                   hstore
---------------------------------------------
 "col1"=>"123", "col2"=>"foo", "col3"=>"bar"
(1 row)
```

Convert an `hstore` to a predefined `record` type:

```
CREATE TABLE test (col1 integer, col2 text, col3 text);

SELECT * FROM populate_record(null::test,
                              '"col1"=>"456", "col2"=>"zzz"');
 col1 | col2 | col3
------+------+------
  456 | zzz  |
(1 row)
```

Modify an existing record using the values from an `hstore`:

```
CREATE TABLE test (col1 integer, col2 text, col3 text);
INSERT INTO test VALUES (123, 'foo', 'bar');

SELECT (r).* FROM (SELECT t #= '"col3"=>"baz"' AS r FROM test t) s;
 col1 | col2 | col3
------+------+------
  123 | foo  | baz
(1 row)
```

### F.18.5. Statistics 

The `hstore` type, because of its intrinsic liberality, could contain a lot of different keys. Checking for valid keys is the task of the application. The following examples demonstrate several techniques for checking keys and obtaining statistics.

Simple example:

```
SELECT * FROM each('aaa=>bq, b=>NULL, ""=>1');
```

Using a table:

```
CREATE TABLE stat AS SELECT (each(h)).key, (each(h)).value FROM testhstore;
```

Online statistics:

```
SELECT key, count(*) FROM
  (SELECT (each(h)).key FROM testhstore) AS stat
  GROUP BY key
  ORDER BY count DESC, key;
    key    | count
-----------+-------
 line      |   883
 query     |   207
 pos       |   203
 node      |   202
 space     |   197
 status    |   195
 public    |   194
 title     |   190
 org       |   189
...................
```

### F.18.6. Compatibility 

As of PostgreSQL 9.0, `hstore` uses a different internal representation than previous versions. This presents no obstacle for dump/restore upgrades since the text representation (used in the dump) is unchanged.

In the event of a binary upgrade, upward compatibility is maintained by having the new code recognize old-format data. This will entail a slight performance penalty when processing data that has not yet been modified by the new code. It is possible to force an upgrade of all values in a table column by doing an `UPDATE` statement as follows:

```
UPDATE tablename SET hstorecol = hstorecol || '';
```

Another way to do it is:

```
ALTER TABLE tablename ALTER hstorecol TYPE hstore USING hstorecol || '';
```

The `ALTER TABLE` method requires an `ACCESS EXCLUSIVE` lock on the table, but does not result in bloating the table with old row versions.