## **SQL Analysis of Northwind Database**

### **1. Database Exploration**
- **Tables Queried**: The analysis begins by exploring the `employees`, `categories`, `customers`, `order_details`, `orders`, and `products` tables.
- **Column Information**: Queries retrieve the column names for each table to understand the structure and available data.
- **Timespan**: The dataset covers orders from 1996 to 1998, confirmed through a query that extracts distinct years from the `orders` table.

### **2. Key Metrics**
- **Employee Count**: There are **9 employees** in the database, with their full names extracted.
- **Product Count**: There are **77 products** available in the product list.
- **Category Count**: There are **8 categories** of products.
- **Customer Count**: The database holds **91 customers**.
- **Order Count**: A total of **830 distinct orders** were placed during the analysis period, involving **2155 distinct products**.

### **3. Data Validation**
- **Null and Negative Value Checks**: 
  - The analysis checks for **NULL values** in key columns such as `quantity` and `unit_price` in the `order_details` table. No NULL values were found.
  - A check for **negative values** in `quantity` and `unit_price` confirmed that there were no unusual negative entries.

### **4. Custom Table Creation**
- The analysis involves creating a **custom table** that joins data from the `orders`, `customers`, and `order_details` tables.
- The table includes details such as `order_id`, `order_date`, `customer_id`, `company_name`, `product_id`, `unit_price`, and `quantity`.
