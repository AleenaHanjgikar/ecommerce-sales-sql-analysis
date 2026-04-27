# 📊 E-Commerce Sales Analysis (SQL Project)

---

## 📌 Project Overview

This project analyzes an Indian e-commerce dataset using MySQL to extract meaningful business insights.

The goal is to simulate real-world data analyst tasks such as:

* Data cleaning
* Feature engineering
* KPI generation
* Business problem solving using SQL

---

## 🗂 Dataset

* 130 rows of e-commerce transactions
* Includes:

  * Customer details
  * Product information
  * Order & shipping dates
  * Pricing, discounts, and payment modes

---

## ⚙️ Database Setup

```sql
CREATE DATABASE ecommerce_db;
USE ecommerce_db;
```

---

## 🧱 Table Structure

Main table: `sales`

Includes:

* Customer info
* Product details
* Pricing & discount
* Shipping cost
* Payment mode

---

## 🔄 Data Cleaning

* Converted string dates using:

```sql
STR_TO_DATE(order_date, '%d-%m-%Y')
```

---

## 🧮 Feature Engineering (View: v_sales)

Created calculated columns:

* Revenue
* Net Revenue
* Delivery Days
* Order Year / Month / Quarter

---

## 📈 Business Questions Solved

### 1. Overall KPIs

* Total Orders
* Total Revenue
* Unique Customers
* Avg Order Value

### 2. Sales Analysis

* Monthly sales trends
* Quarterly performance

### 3. Customer Insights

* Segment-wise analysis
* Repeat vs new customers

### 4. Product Performance

* Top-selling products
* Category & sub-category analysis

### 5. Operational Insights

* Delivery time analysis
* Shipping cost impact

---

## 🛠 Tools Used

* MySQL
* SQL (Joins, Aggregations, Views, Date Functions)

---

## 🚀 How to Run

1. Import dataset into MySQL
2. Run the SQL script:

```
ecommerce_sales_analysis.sql
```

---

## 📌 Key Insights

* Electronics generated highest revenue
* Discounts significantly impact net profit
* Delivery time varies by region
* Certain categories dominate sales volume

---

