-- Clean Dominos / Store / Ecommerce Database

--Step 1 :- To Check for duplicates
--Step 2 :- Check for null values
--Step 3 :- Treating null values
--Step 4 :- Handling Negative Values
--Step 5 :- Fixing Inconsistent Date Formats & Invalid Dates
--Step 6 :- Fixing Invalid Email Addresses
--Step 7 :- Checking the datatype

SELECT * FROM customers;
SELECT DISTINCT(email) AS unique_email
FROM customers;






















