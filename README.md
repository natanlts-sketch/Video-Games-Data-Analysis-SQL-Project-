# 🎮 Video Games Data Analysis (SQL Project)

## 📌 Project Overview

This project focuses on advanced data analysis using SQL on a video games dataset. The goal is to extract meaningful business insights by applying analytical techniques such as aggregations, window functions, and data modeling.

The analysis simulates real-world business questions related to product performance, market trends, and growth over time.

---

## 🛠️ Technologies Used

* SQL Server (T-SQL)
* Relational Databases
* Data Cleaning & Transformation
* Analytical SQL (CTEs, Window Functions)

---

## 📊 Key Skills Demonstrated

* Writing complex SQL queries using **CTEs**
* Using **Window Functions** (LAG, PARTITION BY)
* Performing **data cleaning** (handling NULLs, trimming, type conversion)
* Building **data scaffolding models**
* Calculating **YoY (Year-over-Year) growth**
* Performing **statistical analysis** (average, weighted average, mode)
* Translating data into **business insights**

---

## 📁 Dataset Description

The dataset contains information about video games, including:

* Name
* Platform
* Genre
* Year of Release
* Global Sales
* Critic Score & Count
* Rating

---

## 📌 Business Questions & Analysis

### 🔹 EX_2A – Games Released on 3+ Platforms

Identifies games distributed across multiple platforms and counts total occurrences.

**Insight:**
A total of **1,061 games** were released on 3 or more platforms, indicating strong cross-platform distribution strategies.

![EX\_2A Results](images/ex2a_games_3_or_more_platforms.png)
![EX\_2A Count](images/ex2a_total_games_3_or_more_platforms.png)

---

### 🔹 EX_2B – Genre Peak Performance

Finds the year in which the highest number of genres reached peak global sales.

**Insight:**
The year **2008** had the highest number of genres at peak performance (3 genres: Adventure, Fighting, Racing).

![EX\_2B Results](images/ex2b_genre_peak_year.png)

---

### 🔹 EX_3 – Critic Score Analysis

Calculates:

* Average score
* Weighted average (based on critic count)
* Mode (most frequent score)

**Insight:**
Weighted averages provide a more reliable measure of critic evaluation compared to simple averages.

![EX\_3 Results](images/ex3_rating_statistics.png)

---

### 🔹 EX_4 – Data Scaffolding Model

Generates all possible combinations of:

* Genre
* Platform
* Year

Missing values are filled with 0 to ensure a complete dataset.

**Insight:**
This technique ensures no gaps in data, which is critical for accurate reporting and trend analysis.

![EX\_4 Results](images/ex4_data_scaffolding_sample.png)

---

### 🔹 EX_5 – Year-over-Year Growth Analysis

Calculates YoY growth for each platform and identifies the highest growth period.

**Insight:**
The **Game Boy Advance (GBA) in 2001** showed the highest YoY growth in the dataset.

![EX\_5 Results](images/ex5_yoy_growth_top_platform.png)

---

## ⚠️ Assumptions & Notes

* Missing or invalid data was cleaned before analysis
* Year 2020 was excluded from YoY calculations due to inconsistencies
* Calculations are based on available dataset fields

---

## 🚀 Future Improvements

* Integrate Python (Pandas) for deeper analysis
* Connect results to BI tools (Tableau / Power BI)
* Build automated data pipelines
* Add more visualizations for storytelling

---

## 👤 Author

**Natan Mamedov**
Aspiring Data Analyst | SQL | Tableau | Python (in progress)
