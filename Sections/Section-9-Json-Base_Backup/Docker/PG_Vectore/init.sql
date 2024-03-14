-- init.sql
CREATE EXTENSION vector;

CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    vector_description vector,  -- Assuming 'pv_vector' is your vector data type
    promised_ce INT,
    stock_level INT,
    category VARCHAR(255),
    title VARCHAR(255),
    brand VARCHAR(255),
    description TEXT
);

