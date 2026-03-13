import pandas as pd
import mysql.connector
import numpy as np

# ── Load CSV ──────────────────────────────────────────────
df = pd.read_csv('data/cleaned_sales_data.csv')

# ── Clean columns ─────────────────────────────────────────
df = df.loc[:, ~df.columns.str.contains('Unnamed')]
df = df.loc[:, df.columns.notna()]
df = df.loc[:, df.columns.str.strip() != '']
df.columns = df.columns.str.strip()

# ── Keep only needed columns ──────────────────────────────
cols_needed = [
    'order_id','order_date','ship_date','customer_id','customer_name',
    'region','category','product_name','quantity','unit_price','unit_cost',
    'discount','revenue','total_cost','profit','profit_margin','order_value',
    'year','quarter','month','month_name','month_year','day_of_week',
    'days_to_ship','customer_segment','r_score','f_score','m_score'
]
df = df[cols_needed]

# ── Fix all NaN values ────────────────────────────────────
df = df.astype(object)
df = df.where(df.notna(), None)

for col in df.columns:
    df[col] = df[col].apply(
        lambda x: None if x is np.nan
        or x != x
        or str(x).lower() == 'nan'
        else x
    )

print('CSV loaded successfully')
print('Columns:', len(df.columns))
print('Rows:', len(df))
print('Null values:', df.isnull().sum().sum())

# ── Connect to MySQL ──────────────────────────────────────
MY_PASSWORD = '94400ssssjJ@'

try:
    conn = mysql.connector.connect(
        host='localhost',
        user='root',
        password=MY_PASSWORD,
        database='sales_analytics'
    )
    print('Connected to MySQL successfully')
except Exception as e:
    print('Connection FAILED:', e)
    exit()

cursor = conn.cursor()

# ── Clear old data ────────────────────────────────────────
cursor.execute('DELETE FROM sales_data')
print('Old data cleared')

# ── Insert rows ───────────────────────────────────────────
sql = """INSERT INTO sales_data (
    order_id, order_date, ship_date, customer_id, customer_name,
    region, category, product_name, quantity, unit_price, unit_cost,
    discount, revenue, total_cost, profit, profit_margin, order_value,
    year, quarter, month, month_name, month_year, day_of_week,
    days_to_ship, customer_segment, r_score, f_score, m_score
) VALUES (
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,
    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
)"""

rows = []
for row in df.itertuples(index=False):
    clean_row = tuple(
        None if v is np.nan or v != v or str(v).lower() == 'nan'
        else v
        for v in row
    )
    rows.append(clean_row)

print(f'Inserting {len(rows)} rows...')

try:
    cursor.executemany(sql, rows)
    conn.commit()
    print(f'Successfully inserted {cursor.rowcount} rows into sales_data')
except Exception as e:
    print('Insert FAILED:', e)
    conn.rollback()

cursor.close()
conn.close()
print('DONE!')


