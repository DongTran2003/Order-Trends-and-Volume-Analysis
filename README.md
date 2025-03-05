# Introduction

### About the project
This project focuses on analyzing order trends and volume over time for **Leuleu Accessorize**, a growing jewelry and accessories brand in Vietnam. The goal is to provide data-driven insights to support decision-making and improve inventory and supplier management. Through in-depth analysis and recommendations, this project aims to help the business optimize its ordering process and enhance transparency in inventory tracking.

Beyond the technical aspects, this project is especially meaningful to me because it allows me to help my sister, the business owner, navigate the world of digital transformation. Before this, she managed her business without leveraging data, unaware of how data analytics could significantly improve her operations. By introducing her to data-driven decision-making, I am not only helping her solve existing business challenges but also demonstrating **the power of analytics in real-world applications**—a passion that drives my work as a data analyst.

### Case Study: Leuleu Accessorize
Founded in 2014, Leuleu Accessorize began as a small boutique offering **affordable, stylish, and trendy jewelry**. Over the years, it expanded rapidly, adding new product lines such as Leuleu Lingerie and Leuleu Aeon Mall Shop. However, with this growth came operational challenges, particularly in inventory and supplier management.

#### The Business Challenge

In 2021, Leuleu Accessorize adopted its **first CRM system**, integrating multiple data sources to streamline operations. However, supplier-related data from Chinese manufacturers was not included in the system. As a result:

- Key details like **order id, total paid for each order, total items, and supplier information were missing**.
- Inventory records only tracked item counts without recording their costs, making it difficult to determine **total inventory value**.
- The lack of order-level transparency created difficulties in **tracing orders, managing suppliers, and assessing stock valuation**.

To address these issues, my primary tasks in this project include:

- **Extracting and consolidating a dataset containing detailed order records** from 2022 onwards, including order number, import dates, prices and quantities of items within each order, total paid before and after discount, and supplier details.
- **Performing order trend and volume analysis** to uncover actionable insights.

This project has been an incredible opportunity to apply my data analysis skills to a real-world business while directly helping my sister transform her business operations. It also strengthens my expertise in data extraction, analysis, and visualization, which are essential skills in my career as a data analyst.

### Techniques Used
To accomplish the project goals, the following tools and techniques were utilized:
- **Web Scraping with Python**: 
    - Extracted all order data from 1688, a Chinese E-commerce platform spanning 2022 to 2025 using **BeautifulSoup**
    - Used **Selenium** to navigate challenges like lack of APIs, CAPTCHA restrictions, and dynamic content loading.
- **Data Cleaning & EDA with MySQL**: Processed and cleaned raw data using MySQL, handling duplicates and exploring insights about order trends and patterns.
- **Data Visualization with Power BI**: Designed interactive dashboards to visualize order trends and volume fluctuations, provising actionable insights to enhance decision-making in inventory and supplier management.

# Web Scraping with Python 🕸️

Before scraping the data, it's essential to understand the structure of the webpage and how the information is displayed:

<img src='image/Order_list.png' width='800' align='center'> 


### Inspecting and Locating Key Data Points

To extract relevant details such as order number and supplier name, we use the browser’s Inspect Tool (press F12) to analyze the page’s HTML structure. This helps identify the exact elements where the data is stored. 

### Scraping Data with BeautifulSoup

Once the key elements are located, we use BeautifulSoup to parse the HTML and extract the required information into a structured dataset. The [Local_file_scraping.ipynb](code/Local_file_scraping.ipynb) notebook demonstrates the full implementation, where we loop through each order to extract its details.

At this stage, we are testing the script with a local HTML file to ensure the extraction logic works correctly before applying it to the live website. 

<img src='image/CSV.png' width='800' align='center'>

\
The saved file now contains the following attributes: 
- ***order_id***
- ***date***
- ***supplier*** 
- ***supplier_link***
- ***image*** (which is saved as the url link to the image)
- ***product_link*** 
- ***price*** and ***quantity***
- ***total_before_discount*** and ***total_after_discount***.


### Scraping Data from the Live Website

After successfully testing our code on a local HTML file, we can now run it on the live 1688 website. This requires Selenium, a Python package used for automating web interactions.

The key difference between scraping from a local file versus a live website is the need to:

- Log in manually to bypass **CAPTCHA**.
- **Implement pagination** so the script can loop through multiple pages (from page 1 to 68, covering orders dating back to 2022), which can be done by adding 1 more loop to the current code.

By incorporating these adjustments, we can extract all order details efficiently and store them in a structured dataset. The [Live_website_scraping](code/Live_website_scraping.ipynb) notebook shows how I addressed these tasks and import the extracted data into a [final CSV file](code/all_orders_2022_2025.csv) 

*Note: To protect the privacy of order details and supplier information, certain columns have been removed.*

# Data Cleaning & EDA with MySQL

The current dataset, which can be imported into MySQL using [all_orders_database_import.sql](code/all_orders_database_import.sql) contains some null values in the ***total_before_discount*** column. This occurs because certain orders did not receive any discounts, meaning the final price was directly stored in ***total_after_discount***. To ensure consistency, we can update ***total_before_discount*** to ***match total_after_discount*** for these cases:

```SQL
UPDATE all_orders
SET total_before_discount = total_after_discount
WHERE total_before_discount IS NULL;
```

To improve tracking and data integrity, I have added ***id*** and ***supplier_id*** columns, serving as unique identifiers for each item and supplier, respectively. 

### Analyzing Trends with SQL

**MySQL** is a powerful tool for uncovering trends and insights in the dataset. The [SQL_EDA.sql](code/SQL_EDA.sql) file contains 12 querries designed to analyze various aspects of order trends and spending behavior. These queries help the business owner gain valuable insights, such as:

```SQL
-- How often do I place orders on monthly average
WITH total_months_each_year AS (
	SELECT 
		YEAR(date) AS year, 
		COUNT(DISTINCT MONTH(date))  AS total_month
    FROM all_orders 
    GROUP BY YEAR(date)
    )
, total_orders_each_year AS (
	SELECT
		COUNT(DISTINCT order_id) as total_orders,
		YEAR(date) as year
	FROM all_orders
	GROUP BY 2
    )
SELECT 
	t1.year,
    t1.total_month,
    t2.total_orders,
    t2.total_orders/t1.total_month AS AVG_order_permonth
FROM total_months_each_year t1
JOIN total_orders_each_year t2 ON t1.year = t2.year
ORDER BY 1;
```
The result will be as following:

| Year | Total Months | Total Orders | Avg Orders per Month |
|------|-------------|--------------|----------------------|
| 2022 | 9           | 398          | 44.2222              |
| 2023 | 12          | 812          | 67.6667              |
| 2024 | 12          | 1282         | 106.8333             |
| 2025 | 2           | 106          | 53.0000              |

Or knowing the longest gap between orders, which is **35 days**:

```SQL
-- What is the longest gap between orders?
WITH CTE AS (
	SELECT DISTINCT order_id, date FROM all_orders 
)
SELECT
    date,
    LAG(date, 1, 0) OVER(ORDER BY date) AS last_order_day,
    DATEDIFF(date, LAG(date, 1, 0) OVER(ORDER BY date)) AS day_gap
FROM CTE
ORDER BY 3 DESC
LIMIT 5;
```

| Date       | Last Order Day | Day Gap|
|------------|--------------|--------|
| 2023-02-07 | 2023-01-03   | 35     |
| 2025-02-07 | 2025-01-15   | 23     |
| 2024-02-20 | 2024-01-29   | 22     |
| 2024-08-23 | 2024-08-09   | 14     |
| 2022-09-04 | 2022-08-22   | 13     |

Or having an **order summary** from all the suppliers:

| Supplier ID | Supplier Name                          | Total Orders | Total Items | Total Spent | Total Discount |
|------------|--------------------------------------|--------------|-------------|-------------|----------------|
| 528        | 义乌市韩爵饰品厂                     | 67           | 1459        | 74709.26    | 1096.23        |
| 215        | 义乌市宝钰饰品有限公司               | 35           | 315         | 36951.65    | 212.51         |
| 265        | 义乌市悦楠服饰有限公司               | 35           | 312         | 81172.16    | 1968.20        |
| 69         | 临海市梦纤语服装加工厂               | 27           | 256         | 85777.35    | 0.00           |
| 97         | 义乌市紧铭电子商务有限公司           | 25           | 520         | 11949.90    | 2.10           |

# Data Visualization with Power BI

MySQL helps uncovering some insights, but it would be a lot more powerful and actionable with visualizations. After connecting MySQL server to Power BI and import the data into the app, I started building a dashboard that summaries all the key points important for understand the order trends and spending of the business. The Power BI dashboard can be downloaded [here](code/LeuleuReport.pbix):

<img src='image/Dashboard.png' width='900'>

