# Power BI Dashboard — Setup Guide

## Overview
This file explains how to recreate the **Sales Advanced Analytics Dashboard**
in Power BI Desktop using the cleaned CSV data files exported by the Python notebook.

---

## Prerequisites
- Power BI Desktop (free download: https://powerbi.microsoft.com/desktop/)
- All CSV files from the `data/` folder

---

## Step 1 — Load Data Sources

Open Power BI Desktop → **Get Data → Text/CSV**, and load these files:

| File | Purpose |
|---|---|
| `cleaned_sales_data.csv` | Main fact table — all orders |
| `rfm_segments.csv` | Customer RFM scores and segments |
| `cohort_retention.csv` | Cohort retention matrix |
| `sales_forecast.csv` | 12-month revenue forecast |
| `monthly_summary.csv` | Aggregated monthly KPIs |

---

## Step 2 — Data Model (Relationships)

In the **Model View**, create these relationships:

```
cleaned_sales_data.customer_id  →  rfm_segments.customer_id
                                    (Many-to-One)
```

All other tables are independent summary tables used directly in visuals.

---

## Step 3 — DAX Measures

Create the following measures in a dedicated `_Measures` table:

```dax
Total Revenue =
    SUM(cleaned_sales_data[revenue])

Total Profit =
    SUM(cleaned_sales_data[profit])

Total Orders =
    DISTINCTCOUNT(cleaned_sales_data[order_id])

Avg Profit Margin =
    AVERAGE(cleaned_sales_data[profit_margin])

Avg Order Value =
    DIVIDE([Total Revenue], [Total Orders])

YoY Revenue Growth =
    VAR CurrYear = CALCULATE([Total Revenue])
    VAR PrevYear = CALCULATE([Total Revenue],
                             SAMEPERIODLASTYEAR(cleaned_sales_data[order_date]))
    RETURN DIVIDE(CurrYear - PrevYear, PrevYear)

Customer Count =
    DISTINCTCOUNT(cleaned_sales_data[customer_id])
```

---

## Step 4 — Dashboard Pages

### Page 1: Executive Overview
| Visual | Type | Fields |
|---|---|---|
| Total Revenue | KPI Card | [Total Revenue] |
| Total Profit | KPI Card | [Total Profit] |
| Total Orders | KPI Card | [Total Orders] |
| Avg Margin | KPI Card | [Avg Profit Margin] |
| Avg Order Value | KPI Card | [Avg Order Value] |
| Monthly Trend | Line Chart | Axis: month_year, Values: revenue |
| Revenue by Region | Bar Chart | Axis: region, Values: revenue |

### Page 2: Product & Category Analysis
| Visual | Type | Fields |
|---|---|---|
| Top 10 Products | Horizontal Bar | product_name, revenue (Top N = 10) |
| Category Revenue | Donut Chart | category, revenue |
| Category Margin | Column Chart | category, profit_margin |
| Product Profitability Table | Table | product_name, revenue, profit, margin |

### Page 3: Customer Analytics
| Visual | Type | Fields |
|---|---|---|
| Customer Segments | Bar Chart | rfm_segments: customer_segment, count |
| Segment Revenue | Stacked Bar | customer_segment, revenue |
| RFM Score Distribution | Scatter | r_score, f_score (size = monetary) |
| Top 10 Customers | Table | customer_name, lifetime_value, segment |

### Page 4: Cohort & Forecasting
| Visual | Type | Fields |
|---|---|---|
| Cohort Heatmap | Matrix | Rows: Cohort_Month, Cols: M0–M11, Values: retention % |
| Sales Forecast | Line Chart | Actuals + forecast line with CI shading |
| YoY Growth | Waterfall Chart | year, revenue |

---

## Step 5 — Filters & Slicers

Add these slicers to each page using **Sync Slicers**:

- **Year** → `cleaned_sales_data[year]`
- **Region** → `cleaned_sales_data[region]`
- **Category** → `cleaned_sales_data[category]`
- **Customer Segment** → `cleaned_sales_data[customer_segment]`

---

## Step 6 — Design Settings

### Theme
- Use the built-in **"Classic"** or **"Accessible Default"** light theme
- Background color: `#F7F9FC`
- Card backgrounds: `#FFFFFF`
- Primary color: `#2B7BB9`

### Formatting Tips
- Turn off visual borders (use subtle shadow instead)
- Use consistent font: **Segoe UI** or **Calibri**
- KPI cards: font size 24pt for values, 10pt for labels
- Add a header text box with the dashboard title and subtitle

---

## Step 7 — Publish

1. Save as `sales_dashboard.pbix`
2. Place the `.pbix` file in the `powerbi/` folder
3. Optionally publish to Power BI Service for online sharing

---

## Dashboard Preview

![Dashboard Preview](../images/dashboard_preview.png)

---

## Notes

- The `.pbix` file is not included in this repo as it requires Power BI Desktop to open.
- All data is synthetic and generated for portfolio demonstration purposes.
- The `dashboard_preview.png` in the `images/` folder shows the intended final layout.
