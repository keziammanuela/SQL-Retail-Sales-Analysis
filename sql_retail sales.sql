-- DATABASE SETUP --

CREATE DATABASE water_retail_sales;
USE water_retail_sales;

CREATE TABLE Customer (
	CustomerID INT NOT NULL PRIMARY KEY,
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	Email VARCHAR(50),
	Phone VARCHAR(50),
	Address VARCHAR(50),
	City VARCHAR(50),
	State VARCHAR(50),
	Zipcode VARCHAR(50)
);

CREATE TABLE Salesperson (
	SalespersonID INT NOT NULL PRIMARY KEY,
	FirstName     VARCHAR(50),
	LastName      VARCHAR(50),
	Email         VARCHAR(50),
	Phone         VARCHAR(50),
	Address       VARCHAR(50),
	City          VARCHAR(50),
	State         VARCHAR(50),
	Zipcode       VARCHAR(50)
);

CREATE TABLE Orders (
	OrderID        INT NOT NULL,
	CreationDate   DATETIME,
	TotalDue       DOUBLE,
	Status         VARCHAR(50),
	CustomerID     INT NOT NULL,
	SalespersonID  INT NOT NULL,
	PRIMARY KEY (OrderID),
	FOREIGN KEY (CustomerID) 
		REFERENCES Customer (CustomerID)
		ON DELETE RESTRICT 
		ON UPDATE RESTRICT,
	FOREIGN KEY (SalespersonID) 
		REFERENCES Salesperson (SalespersonID)
		ON DELETE RESTRICT 
		ON UPDATE RESTRICT
);

CREATE TABLE Product (
	ProductID    INT NOT NULL PRIMARY KEY,
	ProductCode  VARCHAR(50),
	ProductName  VARCHAR(50),
	Size         INT,
	Variety      VARCHAR(50),
	Price        DOUBLE,
	Status       VARCHAR(50)
);

CREATE TABLE OrderItem (
	OrderItemID INT NOT NULL,
	OrderID     INT NOT NULL,
	ProductID   INT NOT NULL,
	Quantity    INT,
	PRIMARY KEY (OrderItemID),
	FOREIGN KEY (OrderID) 
		REFERENCES Orders (OrderID)
		ON UPDATE RESTRICT 
		ON DELETE CASCADE,
	FOREIGN KEY (ProductID) 
		REFERENCES Product (ProductID)
		ON UPDATE RESTRICT 
		ON DELETE CASCADE
);


-- DATA EXPLORATION --

SELECT COUNT(*) FROM customer;
-- Number of unique customers
SELECT COUNT(DISTINCT CustomerID) as total_customer FROM customer;

SELECT COUNT(*) FROM salesperson;
-- Number of unique salesperson
SELECT COUNT(DISTINCT SalespersonID) as total_salesperson FROM salesperson;

SELECT COUNT(*) FROM product;
-- Different product categories
SELECT COUNT(DISTINCT ProductID) as total_product FROM product;

SELECT COUNT(*) FROM orders;
-- Total number of transactions or orders
SELECT COUNT(DISTINCT OrderID) as total_orders FROM orders;

SELECT COUNT(*) FROM orderitem;

-- DATA CLEANING (CHECK MISSING VALUES) --

SELECT * FROM customer
WHERE 
	CustomerID IS NULL OR FirstName IS NULL OR LastName IS NULL OR 
	Email IS NULL OR Phone IS NULL OR Address IS NULL OR
	City IS NULL OR State IS NULL OR Zipcode IS NULL;

SELECT * FROM customer
WHERE 
	CustomerID IS NULL OR FirstName IS NULL OR LastName IS NULL OR 
	Email IS NULL OR Phone IS NULL OR Address IS NULL OR
	City IS NULL OR State IS NULL OR Zipcode IS NULL;
    
SELECT * FROM salesperson
WHERE 
	SalespersonID IS NULL OR FirstName IS NULL OR LastName IS NULL OR 
	Email IS NULL OR Phone IS NULL OR Address IS NULL OR
	City IS NULL OR State IS NULL OR Zipcode IS NULL;
    
SELECT * FROM orders
WHERE 
	OrderID IS NULL OR CreationDate IS NULL OR TotalDue IS NULL OR 
    Status IS NULL OR CustomerID IS NULL OR SalespersonID IS NULL;
    
SELECT * FROM product
WHERE 
	ProductID IS NULL OR ProductCode IS NULL OR ProductName IS NULL OR 
	Size IS NULL OR Variety IS NULL OR Price IS NULL OR
	Status IS NULL;

SELECT * FROM orderitem
WHERE 
	OrderItemID IS NULL OR OrderID IS NULL OR ProductID IS NULL OR Quantity IS NULL;


-- DATA ANALYSIS & FINDINGS --

-- 1. Retrieve all columns for sales made on a specific day ('2015-07-01)
SELECT * 
FROM orders 
WHERE CreationDate = '2015-08-17';

-- 2. Retrive all columns for sales made on a specific month of August 2015
SELECT * 
FROM orders 
WHERE DATE_FORMAT(CreationDate, '%Y-%m') = '2015-08'
ORDER BY CreationDate ASC;

-- 3. Retrieve the sales transactions from the earliest and latest dates in the table
SELECT * 
FROM orders
WHERE
	CreationDate = (SELECT MIN(CreationDate) FROM orders) OR
	CreationDate = (SELECT MAX(CreationDate) FROM orders)
ORDER BY CreationDate;

-- 4. Identify the state with the highest number of customers
SELECT 
	state, 
	COUNT(CustomerID) AS num_cust
FROM customer
GROUP BY state
ORDER BY num_cust DESC;

-- 5. Count the number of transactions where the product variety is 'Blueberry' and the quantity sold greater than 10
SELECT COUNT(DISTINCT OrderID)
FROM orderitem 
WHERE 
	quantity > 10 
AND ProductID IN (SELECT ProductID from product WHERE variety = 'Blueberry');

-- 6. Identify the total number of sales for each product variety
SELECT 
	Variety, 
	COUNT(DISTINCT OrderID) AS num_sales
FROM orderitem oi
JOIN product p
	ON oi.ProductID = p.ProductID
GROUP BY Variety
ORDER BY num_sales DESC;

-- 7. Calculate the total sales for each product variety 
SELECT 
	p.Variety, 
	ROUND(SUM(o.TotalDue), 2) as total_sales
FROM orderitem oi
	JOIN orders o 
		ON oi.OrderID = o.OrderID
	JOIN product p 
		ON oi.ProductID = p.ProductID
WHERE 
	o.Status = 'paid'
GROUP BY p.Variety
ORDER BY total_sales DESC;

-- 8. Calculate the average sales, average number of customer, average quantity for each month and identify the best-selling month in each year
SELECT
	YEAR(o.CreationDate) AS order_year,
    MONTH(o.CreationDate) AS order_month,
	ROUND(AVG(o.TotalDue), 2) AS avg_sales,
	ROUND(AVG(oi.quantity)) as avg_quantity
FROM orderitem oi
	JOIN orders o 
		ON oi.OrderID = o.OrderID
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- 9. Sales Person Segmentation
SELECT 
	sp.SalespersonID,
    sp.FirstName,
    sp.LastName,
	CASE 
		WHEN COUNT(DISTINCT o.OrderID) >= 10 OR SUM(o.TotalDue) > 500 THEN 'High Performer'
		WHEN COUNT(DISTINCT o.OrderID) >= 5 OR SUM(o.TotalDue) BETWEEN 250 AND 500 THEN 'Medium Performer'
		ELSE 'Low Performer'
    END salesperson_category,
    ROUND(SUM(o.TotalDue), 2) AS total_sales,
    COUNT(DISTINCT o.OrderID) AS total_orders,
    SUM(oi.Quantity) AS total_items_sold
FROM salesperson sp
	JOIN orders o 
		ON sp.SalespersonID = o.SalespersonID
	JOIN orderitem oi 
		ON o.OrderID = oi.OrderID
GROUP BY sp.SalespersonID, sp.FirstName, sp.LastName
ORDER BY total_sales DESC;

-- 10. Customer Segmentation
SELECT 
	c.CustomerID,
    c.FirstName,
    c.LastName,
	CASE 
		WHEN COUNT(DISTINCT o.OrderID) >= 3 OR SUM(o.TotalDue) > 400 THEN 'Top Buyer'
		ELSE 'New'
    END customer_category,
    ROUND(SUM(o.TotalDue), 2) AS total_sales,
    COUNT(DISTINCT o.OrderID) AS total_orders,
    SUM(oi.Quantity) AS total_items_sold
FROM customer c
	JOIN orders o 
		ON c.CustomerID = o.CustomerID
	JOIN orderitem oi 
		ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY total_sales DESC;

-- 11. Sales Cumulative Analysis
-- Calculates total sales per month and the cumulative running total over time
-- (This helps to understand whether the business is growing or declining)
SELECT 
	CreationDate,
	TotalDue,
	SUM(TotalDue) OVER (ORDER BY CreationDate) AS rolling_total
FROM (
	SELECT 
		DATE_FORMAT(CreationDate, '%Y-%m-01') AS CreationDate,
		SUM(TotalDue) AS TotalDue
	FROM orders
	WHERE Status = 'paid'
	GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
) AS monthly_data;


-- 12. Proportional Analysis
-- (Helps identify which category/variety product contributes the most to the business)
WITH total_sales_category AS (
	SELECT
		p.Variety,
		SUM(o.TotalDue) AS total_sales_cat
	FROM product p
		JOIN orderitem oi
			ON p.ProductID = oi.ProductID
		JOIN orders o 
			ON o.OrderID = oi.OrderID
	WHERE o.Status = 'paid'
	GROUP BY p.Variety
)

SELECT 
	Variety,
	total_sales_cat,
	SUM(total_sales_cat) OVER () AS overall_sales,
	CONCAT(ROUND((total_sales_cat * 100.0) / SUM(total_sales_cat) OVER (), 2), '%') AS contribution_percentage
FROM total_sales_category
ORDER BY total_sales_cat DESC;


-- 13. Performance Analysis
-- Compare current year sales with previous year sales
-- (Provides insight into business growth through year-over-year sales analysis)
WITH yearly_product_sales AS (
	SELECT
		p.variety AS product_name,
		SUM(o.TotalDue) AS total_sales,
		YEAR(o.CreationDate) AS order_year
	FROM product p
		JOIN orderitem oi
			ON p.ProductID = oi.ProductID
		JOIN orders o 
			ON o.OrderID = oi.OrderID
	WHERE o.Status = 'paid'
	GROUP BY YEAR(o.CreationDate), p.Variety
)

SELECT 
	order_year,
	product_name,
	total_sales,
  -- Average sales per product
	AVG(total_sales) OVER(PARTITION BY product_name) AS average_sales,
  -- Difference from product's average sales
	total_sales - AVG(total_sales) OVER(PARTITION BY product_name) AS diff_average,
  -- Category based on deviation from average sales
	CASE 
		WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Average'
		WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Average'
		ELSE 'Average'
	END AS Average_Change,
  -- Previous year’s sales
	LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS p_y_sales,
  -- Difference from previous year’s sales
	total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_p_y,
  -- Year-over-year (YoY) growth category
	CASE 
		WHEN total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		WHEN total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		ELSE 'No Change'
	END AS y_over_y
FROM yearly_product_sales;










