### [Pg Vector Intro](https://github.com/pgvector/pgvector) 

- create the vector extension in `cbd_store` db :

  ```sql
  -- init.sql
  CREATE EXTENSION vector;
  
  
  ```

  

- create the product table :

  ```sql
  CREATE TABLE product (
      id SERIAL PRIMARY KEY,
      vector_description vector, 
      promised_ce INT,
      stock_level INT,
      category VARCHAR(255),
      title VARCHAR(255),
      brand VARCHAR(255),
      description TEXT
  );
  ```

  

- insert some data : 

  ```sql 
  INSERT INTO product (vector_description, promised_ce, stock_level, category, title, brand, description)
  VALUES 
      ('{1.2, 3.4, 5.6}', 24, 100, 'Electronics', 'Laptop', 'BrandX', 'Powerful laptop for gaming and productivity.'),
      ('{0.8, 2.6, 4.9}', 12, 50, 'Clothing', 'T-shirt', 'FashionCo', 'Comfortable cotton t-shirt for everyday wear.'),
      ('{2.1, 4.3, 6.5}', 36, 80, 'Home & Kitchen', 'Coffee Maker', 'KitchenMaster', 'Automatic coffee maker for brewing fresh coffee.'),
      ('{1.5, 3.8, 7.2}', 48, 120, 'Electronics', 'Smartphone', 'TechGiant', 'Latest smartphone with high-resolution display and powerful processor.'),
      ('{0.9, 2.4, 5.7}', 18, 60, 'Clothing', 'Jeans', 'DenimCo', 'Classic denim jeans with a comfortable fit.'),
      ('{2.3, 4.6, 8.9}', 64, 150, 'Home & Kitchen', 'Blender', 'KitchenMaster', 'Powerful blender for making smoothies and sauces.'),
      ('{1.8, 3.1, 6.4}', 30, 70, 'Electronics', 'Tablet', 'TechGiant', 'Versatile tablet for work and entertainment.'),
      ('{0.7, 2.9, 4.2}', 10, 40, 'Clothing', 'Sweater', 'FashionCo', 'Cozy sweater for chilly days.'),
      ('{2.5, 4.8, 7.1}', 42, 90, 'Home & Kitchen', 'Rice Cooker', 'KitchenMaster', 'Automatic rice cooker for perfectly cooked rice every time.'),
      ('{1.3, 3.6, 5.9}', 28, 80, 'Electronics', 'Smart Watch', 'TechGiant', 'Smart watch with fitness tracking and notification features.');
  
  
  or 
  
  
  
  INSERT INTO product (vector_description, promised_ce, stock_level, category, title, brand, description)
  VALUES
      (ARRAY[1.2, 3.4, 5.6], 24, 100, 'Electronics', 'Laptop', 'BrandX', 'Powerful laptop for gaming and productivity.'),
      (ARRAY[0.8, 2.6, 4.9], 12, 50, 'Clothing', 'T-shirt', 'FashionCo', 'Comfortable cotton t-shirt for everyday wear.'),
      (ARRAY[2.1, 4.3, 6.5], 36, 80, 'Home & Kitchen', 'Coffee Maker', 'KitchenMaster', 'Automatic coffee maker for brewing fresh coffee.'),
      (ARRAY[1.5, 3.8, 7.2], 48, 120, 'Electronics', 'Smartphone', 'TechGiant', 'Latest smartphone with high-resolution display and powerful processor.'),
      (ARRAY[0.9, 2.4, 5.7], 18, 60, 'Clothing', 'Jeans', 'DenimCo', 'Classic denim jeans with a comfortable fit.'),
      (ARRAY[2.3, 4.6, 8.9], 64, 150, 'Home & Kitchen', 'Blender', 'KitchenMaster', 'Powerful blender for making smoothies and sauces.'),
      (ARRAY[1.8, 3.1, 6.4], 30, 70, 'Electronics', 'Tablet', 'TechGiant', 'Versatile tablet for work and entertainment.'),
      (ARRAY[0.7, 2.9, 4.2], 10, 40, 'Clothing', 'Sweater', 'FashionCo', 'Cozy sweater for chilly days.'),
      (ARRAY[2.5, 4.8, 7.1], 42, 90, 'Home & Kitchen', 'Rice Cooker', 'KitchenMaster', 'Automatic rice cooker for perfectly cooked rice every time.'),
      (ARRAY[1.3, 3.6, 5.9], 28, 80, 'Electronics', 'Smart Watch', 'TechGiant', 'Smart watch with fitness tracking and notification features.');
  
  ```

  

- `select * from product`



## Getting Started

Enable the extension (do this once in each database where you want to use it)

```
CREATE EXTENSION vector;
```



Create a vector column with 3 dimensions

```
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
```



Insert vectors

```
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
```



Get the nearest neighbors by L2 distance

```
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```



Also supports inner product (`<#>`) and cosine distance (`<=>`)

Note: `<#>` returns the negative inner product since Postgres only supports `ASC` order index scans on operators

## Storing

Create a new table with a vector column

```
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
```



Or add a vector column to an existing table

```
ALTER TABLE items ADD COLUMN embedding vector(3);
```



Insert vectors

```
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
```



Upsert vectors

```
INSERT INTO items (id, embedding) VALUES (1, '[1,2,3]'), (2, '[4,5,6]')
    ON CONFLICT (id) DO UPDATE SET embedding = EXCLUDED.embedding;
```



Update vectors

```
UPDATE items SET embedding = '[1,2,3]' WHERE id = 1;
```



Delete vectors

```
DELETE FROM items WHERE id = 1;
```



## Querying

Get the nearest neighbors to a vector

```
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```



Get the nearest neighbors to a row

```
SELECT * FROM items WHERE id != 1 ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 1) LIMIT 5;
```



Get rows within a certain distance

```
SELECT * FROM items WHERE embedding <-> '[3,1,2]' < 5;
```



Note: Combine with `ORDER BY` and `LIMIT` to use an index

#### Distances

Get the distance

```
SELECT embedding <-> '[3,1,2]' AS distance FROM items;
```



For inner product, multiply by -1 (since `<#>` returns the negative inner product)

```
SELECT (embedding <#> '[3,1,2]') * -1 AS inner_product FROM items;
```



For cosine similarity, use 1 - cosine distance

```
SELECT 1 - (embedding <=> '[3,1,2]') AS cosine_similarity FROM items;
```



#### Aggregates

Average vectors

```
SELECT AVG(embedding) FROM items;
```



Average groups of vectors

```
SELECT category_id, AVG(embedding) FROM items GROUP BY category_id;
```



### Practical Samples

```-- Add a new column named vector_description
ALTER TABLE products ADD COLUMN pgvector_desc vector;
```

- create the embedding of each `seo_desc` using OpenAI/GPT4All/ ...
- store the embedding and start querying ... 