## **Python Analysis of Northwind Database**

### **1. Data Exploration and Loading**
- The dataset was loaded into the environment using **Pandas**, and a quick exploration was performed to inspect the key columns such as `order_id`, `product_id`, `employee_id`, `unit_price`, and `quantity`.
- The analysis focused on the `orders`, `order_details`, and `customers` tables.

### **2. Data Cleaning**
- **Missing Data Handling**: Checks were performed to detect any **missing values** in critical columns like `quantity` and `unit_price`. No major missing data issues were found.
- **Outlier Detection**: The analysis included identifying **outliers** in the `unit_price` and `quantity` columns, ensuring there were no negative or zero values.

### **3. Key Insights and Visualizations**
- **Revenue Analysis**: A calculation of **total revenue** was performed by multiplying the `quantity` by `unit_price` for each product.
- **Top Product Segments**: The dataset was segmented by **profitability** to determine which product categories generated the highest revenue.
- **Visualization**: Various **bar charts** and **line plots** were generated using **Matplotlib** to visualize product counts by profitability segment and revenue over time.
  - A bar chart was created to display **product count by profit segment**, with labels indicating the exact counts.

### **4. Employee Performance**
- The analysis included a **performance evaluation** of employees based on the number of orders processed and the revenue they contributed.
- **Visualizations**: Employee performance was visualized through bar plots, highlighting the top-performing employees in terms of revenue and orders processed.

### **5. Customer Segmentation**
- **RFM Analysis** (Recency, Frequency, Monetary) was conducted to segment customers based on their buying patterns.
  - **Champions**, **loyal customers**, and **lost customers** were identified.
- A **scatter plot** was used to visualize customer segments based on their profitability and purchasing frequency.
