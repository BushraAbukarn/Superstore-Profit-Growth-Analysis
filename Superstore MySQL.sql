/*
1. Seasonal Sales Performance Analysis
2. Customer Shipping Method Preferences
3. Top Performing Products and Categories by Profitability
4. Low-Performing Products and Sub-Categories by Profitability 
Data Merge: Integrating Customer Information Across Tables Using ID
5. Revenue Analysis by State
6. Top 5 highest-selling products in the region with the highest revenue
7. Profit Contribution by Customer Segment 
*/ 

/* Connect to the Database */ 
USE sales_data; 

/* Modifying & Cleaning Data */ 
#1) Rename the imported table to order_info; 
RENAME TABLE mytable TO order_info;
#2) Modify dates columns in the order_info table; 
ALTER TABLE order_info 
MODIFY COLUMN Order_Date DATE,
MODIFY COLUMN Ship_Date DATE;
#3) Delete missing values in the order_info table; 
DELETE FROM order_info 
WHERE
    Order_Date IS NULL;
#4.1) Check if there's duplicate records in the order_info table based on the combination of Product_ID and Order_ID; 
SELECT 
    Product_ID, Order_ID, COUNT(*) AS Duplicate_N
FROM
    order_info
GROUP BY Product_ID , Order_ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_N DESC; 
#4.2) Review Duplicate Records;
SELECT 
    *
FROM
    order_info
WHERE
    Order_ID = 'US-2019-150119'; 
#4.3) Delete duplicate rows; 
SET SQL_SAFE_UPDATES =0;
WITH CTE_Duplicates AS (
    SELECT 
        Order_ID,
        ROW_NUMBER() OVER (PARTITION BY Product_ID, Order_ID ORDER BY (SELECT NULL)) AS RowNum
    FROM 
        order_info
)
DELETE FROM order_info 
WHERE Order_ID IN (
    SELECT Order_ID 
    FROM CTE_Duplicates 
    WHERE RowNum > 1
);

SET SQL_SAFE_UPDATES =1;


#1. ; 
CREATE TABLE sales_by_season AS
WITH Season_Calc AS (
  SELECT 
    YEAR(Order_Date) AS Year, 
    CASE 
      WHEN MONTH(Order_Date) IN (12, 1, 2) THEN 'Winter'
      WHEN MONTH(Order_Date) IN (3, 4, 5) THEN 'Spring'
      WHEN MONTH(Order_Date) IN (6, 7, 8) THEN 'Summer'
      ELSE 'Fall' 
    END AS Season,
    Sales, 
    Profit
  FROM 
    order_info
)
SELECT 
  Year, 
  Season, 
  ROUND(SUM(Sales), 2) AS Total_Sales, 
  ROUND(SUM(Profit), 2) AS Total_Profit
FROM 
  Season_Calc
GROUP BY 
  Year, 
  Season
ORDER BY 
  Year, 
  Season;

#2. ; 
SELECT 
    Ship_Mode, COUNT(Ship_Mode) AS Total_Shipments
FROM
    order_info
GROUP BY Ship_Mode
ORDER BY Total_Shipments DESC;

#3.1 ; 
SELECT 
    Category,
    ROUND(AVG(Sales), 2) AS Average_Sales,
    ROUND(AVG(Profit), 2) AS Average_Profit
FROM
    order_info
GROUP BY Category
ORDER BY Average_Sales , Average_Profit;
#3.2 ;
SELECT 
    Product_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM
    order_info
GROUP BY Product_Name
ORDER BY Total_Profit DESC
LIMIT 10;

#4. 1; 
SELECT 
    Sub_Category,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin
FROM
    order_info
GROUP BY Sub_Category
ORDER BY Profit_Margin; 

#4. 2; 
SELECT 
    Product_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM
    order_info
GROUP BY Product_Name
ORDER BY Total_Profit ASC
LIMIT 10;


/* Merge the two tables */ 
CREATE TABLE sales_summary AS SELECT c.Customer_ID,
    c.Segment,
    c.State,
    c.Region,
    o.Sub_Category,
    o.Product_Name,
    o.Sales,
    o.Quantity,
    o.Profit FROM
    customer_data c
        INNER JOIN
    order_info o ON c.ID = o.ID;

#5.1 ; 
SELECT 
    State,
    ROUND(AVG(Sales), 2) AS Average_Sales,
    ROUND(AVG(Profit), 2) AS Average_Profit
FROM
    sales_summary
GROUP BY State 
ORDER BY Average_Sales;

#5.2 ; 
SELECT 
    Region, ROUND(SUM(Profit), 2) AS Total_Profit
FROM
    sales_summary
GROUP BY Region
ORDER BY Total_Profit DESC;

#5.3 ; 
SELECT 
    Product_Name, SUM(Quantity) AS Total_Qunatity_Sold
FROM
    sales_summary
WHERE
    Region = 'East'
GROUP BY Product_Name
ORDER BY Total_Qunatity_Sold DESC
LIMIT 5; 

#5.4 ; 
SELECT 
    Sub_Category, ROUND(SUM(Profit), 2) AS Total_Profit
FROM
    sales_summary
GROUP BY Sub_Category
ORDER BY Total_Profit DESC;

#6. ; 
SELECT 
    Segment, ROUND(SUM(Profit), 2) AS Total_Profit
FROM
    sales_summary
GROUP BY Segment
ORDER BY Total_Profit DESC; 
