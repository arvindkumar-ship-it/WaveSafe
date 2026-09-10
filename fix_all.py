import psycopg2
conn = psycopg2.connect(dbname='coastal_safety', user='coastal', password='changeme', host='localhost', port=5432)
conn.autocommit = True
cur = conn.cursor()

tables = [
    'beach_activity_profiles', 'beach_forecasts', 'beach_risk_scores', 'beaches',
    'emergency_contacts', 'hazard_alerts', 'hospitals', 'incident_reports',
    'incident_status_history', 'jurisdictions', 'location_pings', 'notification_queue',
    'offline_sync_queue', 'rescue_posts', 'safe_zones', 'trip_plans',
    'trip_risk_snapshots', 'user_contacts', 'user_devices', 'users'
]

cur.execute('CREATE EXTENSION IF NOT EXISTS pgcrypto')
for table in tables:
    cur.execute(f'ALTER TABLE {table} ALTER COLUMN id SET DEFAULT gen_random_uuid()')
    print(f'Fixed: {table}')

print('All done!')
cur.close()
conn.close()
