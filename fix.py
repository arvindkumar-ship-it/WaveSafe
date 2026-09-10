import psycopg2
conn = psycopg2.connect(dbname='coastal_safety', user='coastal', password='changeme', host='localhost', port=5432)
conn.autocommit = True
cur = conn.cursor()

# Fix superseded default
cur.execute("ALTER TABLE safezone_guidance ALTER COLUMN superseded SET DEFAULT false")
print("superseded fixed")

# Find all id columns missing defaults
cur2 = conn.cursor()
cur2.execute("""
    SELECT table_name, column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND column_default IS NULL
    AND is_nullable = 'NO'
    AND column_name = 'id'
    ORDER BY table_name
""")
rows = cur2.fetchall()
print("Tables with missing id defaults:")
for r in rows: print(r)

cur.close()
cur2.close()
conn.close()
