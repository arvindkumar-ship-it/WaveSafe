UPDATE hospitals
SET capabilities = '{"trauma": true, "emergency": true, "oxygen": true, "icu": true, "pediatric": true, "coastal_access": true}'::jsonb
WHERE name = 'Apollo Hospital Chennai';
