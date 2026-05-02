-- Dominos Store Project 

--Customers
CREATE TABLE customers(
    custid INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    phone VARCHAR(12) NOT NULL,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(6) NOT NULL
);
SELECT * FROM customers;

--order_details
CREATE TABLE order_details(
    order_details_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id VARCHAR(15) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)
);
SELECT * FROM order_details;


--orders
CREATE TABLE orders(
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    order_time VARCHAR(14) NOT NULL,
    custid INT NOT NULL,
    status VARCHAR(9) NOT NULL,
    FOREIGN KEY (custid) REFERENCES customers(custid)
);
SELECT * FROM orders;

--pizza_types
CREATE TABLE pizza_types(
    pizza_type_id VARCHAR(60) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients TEXT NOT NULL
);
SELECT * FROM pizza_types;

--pizzas
CREATE TABLE pizzas(
    pizza_id VARCHAR(15) PRIMARY KEY,
    pizza_type_id VARCHAR(60) NOT NULL,
    size VARCHAR(5) NOT NULL,
    price NUMERIC(5,2) NOT NULL,
    FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id)
);
SELECT * FROM pizzas;






