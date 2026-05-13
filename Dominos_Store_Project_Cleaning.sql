-- Clean Dominos / Store / Ecommerce Database

SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM order_details;

--Step 1 :- To Check for duplicates

--1st way

DELETE 
FROM customers
WHERE custId NOT IN (
	SELECT MIN(custId)
	FROM orders
	GROUP BY email
);

--2nd way
	
DELETE
FROM customers
WHERE custId IN(
	SELECT custId
	FROM(
			SELECT custId,
				   ROW_NUMBER() OVER(PARTITION BY email ORDER BY custId) AS rn	
				   FROM customers
		) t
		WHERE t.rn > 1
);


--Step 2 :- Check for null values

SELECT *
FROM customers
WHERE email IS NULL
   OR phone IS NULL;

--Step 3 :- Treating null values

UPDATE customers
SET phone = 0
WHERE phone IS NULL;


UPDATE customers
SET city  = ' - '
WHERE  city is null;


--Step 4 :- Handling Negative Values
--CHECK
SELECT * 
FROM order_details
WHERE quantity < 1;

UPDATE order_details
SET quantity = 0
WHERE quantity < 1;


--Step 5 :- Fixing Inconsistent Date Formats & Invalid Dates
SELECT order_id, order_date
FROM orders
WHERE order_date::TEXT !~ '^(19|20)\d\d-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$';



--Step 6 :- Fixing Invalid Email Addresses

SELECT custid, email
FROM customers
WHERE email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

SELECT * FROM orders;

--Step 7 :- Checking the datatype

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders'
AND column_name = 'status';














