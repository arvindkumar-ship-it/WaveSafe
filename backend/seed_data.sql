--
-- PostgreSQL database dump
--

\restrict EzS4tFwg2YpddSnJTerbRGFkyrIEPcTSLKP8Qigm27RicDWyUK0JExfeG4Vo0f6

-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: beaches; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.beaches (id, name, state, district, coast_region, geom, centroid, has_lifeguard, public_access, active, created_at, updated_at) VALUES ('61f0f0d6-3b3d-411c-a2d8-cc91efa68153', 'Test Beach', 'Goa', 'North Goa', NULL, '0103000020E610000001000000050000008FC2F5285C6F52407B14AE47E1FA2E40713D0AD7A37052407B14AE47E1FA2E40713D0AD7A370524085EB51B81E052F408FC2F5285C6F524085EB51B81E052F408FC2F5285C6F52407B14AE47E1FA2E40', NULL, true, true, true, '2026-08-10 02:31:49.352953+05:30', '2026-08-10 02:31:49.352953+05:30');
INSERT INTO public.beaches (id, name, state, district, coast_region, geom, centroid, has_lifeguard, public_access, active, created_at, updated_at) VALUES ('e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'Marina Beach', 'Tamil Nadu', 'Chennai', 'East Coast', '0103000020E6100000010000000500000052B81E85EB1154409A99999999192A40C3F5285C8F1254409A99999999192A40C3F5285C8F1254401F85EB51B81E2A4052B81E85EB1154401F85EB51B81E2A4052B81E85EB1154409A99999999192A40', NULL, true, true, true, '2026-08-11 18:59:51.347111+05:30', '2026-08-11 18:59:51.347111+05:30');
INSERT INTO public.beaches (id, name, state, district, coast_region, geom, centroid, has_lifeguard, public_access, active, created_at, updated_at) VALUES ('36d5cd53-1347-4b40-8e35-621f4c30d242', 'Test Admin Beach', 'Kerala', 'Kochi', 'Malabar', '0103000020E61000000100000005000000713D0AD7A31053405C8FC2F528DC2340E17A14AE471153405C8FC2F528DC2340E17A14AE47115340E17A14AE47E12340713D0AD7A3105340E17A14AE47E12340713D0AD7A31053405C8FC2F528DC2340', NULL, true, true, true, '2026-08-15 04:07:43.209508+05:30', '2026-08-15 04:07:43.209508+05:30');
INSERT INTO public.beaches (id, name, state, district, coast_region, geom, centroid, has_lifeguard, public_access, active, created_at, updated_at) VALUES ('fe6c0a2a-1b0c-4c8e-908a-9ac31df517cb', 'Test Beach Admin', 'Tamil Nadu', 'Chennai', 'East Coast', '0103000020E6100000010000000500000060E5D022DB115440F2D24D6210182A40FCA9F1D24D125440F2D24D6210182A40FCA9F1D24D1254404260E5D0221B2A4060E5D022DB1154404260E5D0221B2A4060E5D022DB115440F2D24D6210182A40', NULL, true, true, true, '2026-08-23 01:43:53.199476+05:30', '2026-08-23 01:43:53.199476+05:30');


--
-- Data for Name: beach_activity_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('99c4face-2262-4cfd-91b9-a530fb460715', '61f0f0d6-3b3d-411c-a2d8-cc91efa68153', 'swimming', 1.500, 1.000, 15.000, 2.000, 50.000, 0.500, '{}', true, '2026-08-10 12:04:50.859878+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('28dd9482-9206-4f95-999e-ae8c2145cdff', '61f0f0d6-3b3d-411c-a2d8-cc91efa68153', 'beach_walk', 3.000, 2.000, 25.000, 4.000, 30.000, 0.300, '{}', true, '2026-08-10 12:05:00.101272+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('058acba1-523f-4a1e-a239-c21bb8312ff8', '61f0f0d6-3b3d-411c-a2d8-cc91efa68153', 'surfing', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-13 17:05:40.599319+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('4a0b607e-664d-480f-8d70-39b85e4283ee', '61f0f0d6-3b3d-411c-a2d8-cc91efa68153', 'boating', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-13 17:05:40.599319+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('20d8fd41-70a8-4f0f-9ca0-6f578026c7f2', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'swimming', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-13 17:05:40.599319+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('a5f4fc98-93ce-4508-b1f1-e585539e03dc', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'surfing', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-13 17:05:40.599319+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('d110a25a-94aa-44bc-8a0e-e2b8fafa27cd', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'boating', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-13 17:05:40.599319+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('746a9b25-064d-4b7e-a58b-b6f1bc168aaa', '36d5cd53-1347-4b40-8e35-621f4c30d242', 'swimming', 0.500, 1.200, 15.000, 2.000, NULL, NULL, 'null', true, '2026-08-15 04:23:04.723238+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('46b4ef85-7b82-4b51-a15a-d5d81383fce0', '36d5cd53-1347-4b40-8e35-621f4c30d242', 'surfing', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-22 18:03:52.667792+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('ee03b998-4140-4004-930b-0ee2f832e4a4', '36d5cd53-1347-4b40-8e35-621f4c30d242', 'boating', NULL, NULL, NULL, NULL, NULL, NULL, '{}', true, '2026-08-22 18:03:52.667792+05:30');
INSERT INTO public.beach_activity_profiles (id, beach_id, activity_type, min_safe_wave_height, max_safe_current_speed, max_safe_wind_speed, max_safe_swell, water_quality_min, tide_sensitivity, risk_weights, active, created_at) VALUES ('2e1bcdb4-3c8a-45eb-a358-f07076da52e2', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'diving', 0.500, 1.200, 25.000, 1.500, 60.000, 0.500, '{"wave": 0.3, "wind": 0.2, "swell": 0.2, "current": 0.3}', true, '2026-08-23 01:45:25.623137+05:30');


--
-- Data for Name: hospitals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.hospitals (id, name, type, geom, contact_phone, contact_email, capabilities, capacity_status, active, created_at) VALUES ('79e21160-6d42-4c2b-bdd6-6adf06bb6398', 'Apollo Hospital Chennai', 'multi-specialty', '0101000020E61000000AD7A3703D1254405C8FC2F5281C2A40', '04412345678', 'contact@apollo.example', '{"icu": true, "oxygen": true, "trauma": true, "emergency": true, "pediatric": true, "coastal_access": true}', 'available', true, '2026-08-11 19:07:04.671621+05:30');
INSERT INTO public.hospitals (id, name, type, geom, contact_phone, contact_email, capabilities, capacity_status, active, created_at) VALUES ('f9f1f926-bc1a-4d60-a1c4-f29b9bc45b46', 'Chennai National Hospital', 'trauma_center', '0101000020E61000005143650DA8125440F8A8BF5E61312A40', '+91 89390 33333', '', '{"icu": true, "oxygen": true, "trauma": true, "pediatric": true, "coastal_access": true}', 'available', true, '2026-08-22 17:59:47.496572+05:30');
INSERT INTO public.hospitals (id, name, type, geom, contact_phone, contact_email, capabilities, capacity_status, active, created_at) VALUES ('d5b8fd98-6e42-4f0d-8923-c1ab7d0ba98f', 'Tamil Nadu Government Multi Super Speciality Hospital', 'general', '0101000020E6100000F8A34D7A84115440D4939E8E6C232A40', '+91 44 2566 6000', '', '{"icu": true, "oxygen": true, "trauma": true, "pediatric": false, "coastal_access": true}', 'available', true, '2026-08-22 17:59:47.500837+05:30');
INSERT INTO public.hospitals (id, name, type, geom, contact_phone, contact_email, capabilities, capacity_status, active, created_at) VALUES ('8e6d8199-ec80-4e7d-b297-9d617349c678', 'Apollo Hospital Chennai', 'multi_specialty', '0101000020E610000039454772F90F5440575BB1BFEC1E2A40', '9876543211', 'test@apollo.test', '{"icu": true, "trauma_center": true}', 'available', true, '2026-08-23 01:47:11.388926+05:30');


--
-- Data for Name: jurisdictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.jurisdictions (id, name, authority_type, contact_phone, contact_email, service_area_geom, escalation_level, active, created_at) VALUES ('d6149f93-8f34-4796-9473-ef630f16c417', 'Chennai Marine Police', 'marine_police', '04498765433', 'marine@police.tn.gov.in', '0106000020E61000000100000001030000000100000005000000E17A14AE4711544014AE47E17A142A40333333333313544014AE47E17A142A403333333333135440A4703D0AD7232A40E17A14AE47115440A4703D0AD7232A40E17A14AE4711544014AE47E17A142A40', 1, true, '2026-08-12 10:47:19.291721+05:30');
INSERT INTO public.jurisdictions (id, name, authority_type, contact_phone, contact_email, service_area_geom, escalation_level, active, created_at) VALUES ('470dc092-1e99-4e5d-94e2-273273639048', 'D5 Marina Police Station', 'local_police', '+91 44 2345 2558', '', '0106000020E610000001000000010300000001000000050000008B6CE7FBA9115440DF4F8D976E122A40273108AC1C125440DF4F8D976E122A40273108AC1C125440BC74931804162A408B6CE7FBA9115440BC74931804162A408B6CE7FBA9115440DF4F8D976E122A40', 1, true, '2026-08-22 17:59:48.100076+05:30');
INSERT INTO public.jurisdictions (id, name, authority_type, contact_phone, contact_email, service_area_geom, escalation_level, active, created_at) VALUES ('e91a6705-444c-4b3d-a069-0b09e9876305', 'Marina Marine Police Station, Coastal Security Group', 'marine_police', '1093', '', '0106000020E61000000100000001030000000100000005000000355EBA490C12544054E3A59BC4202A40D122DBF97E12544054E3A59BC4202A40D122DBF97E1254403108AC1C5A242A40355EBA490C1254403108AC1C5A242A40355EBA490C12544054E3A59BC4202A40', 2, true, '2026-08-22 17:59:48.107162+05:30');
INSERT INTO public.jurisdictions (id, name, authority_type, contact_phone, contact_email, service_area_geom, escalation_level, active, created_at) VALUES ('068afce2-c577-469d-8771-18c2a22bf767', 'Indian Coast Guard Regional Headquarters Chennai', 'coast_guard', '+91-44-25391718', '', '0106000020E610000001000000010300000001000000050000001904560E2D125440E17A14AE47212A40B4C876BE9F125440E17A14AE47212A40B4C876BE9F125440BE9F1A2FDD242A401904560E2D125440BE9F1A2FDD242A401904560E2D125440E17A14AE47212A40', 3, true, '2026-08-22 17:59:48.108902+05:30');
INSERT INTO public.jurisdictions (id, name, authority_type, contact_phone, contact_email, service_area_geom, escalation_level, active, created_at) VALUES ('f36dca5f-6009-4d24-8bed-7a9174fd500c', 'Chennai Marine Police Jurisdiction', 'marine_police', '9876543210', 'test@marinepolice.test', '0106000020E6100000010000000103000000010000000500000060E5D022DB115440F2D24D6210182A40FCA9F1D24D125440F2D24D6210182A40FCA9F1D24D1254404260E5D0221B2A4060E5D022DB1154404260E5D0221B2A4060E5D022DB115440F2D24D6210182A40', 1, true, '2026-08-23 01:46:16.440202+05:30');


--
-- Data for Name: safe_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.safe_zones (id, beach_id, name, geom, elevation_m, route_notes, active, created_at) VALUES ('ce7aec7a-2250-472e-98ec-e3b4035a36aa', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'Marina Beach Safe Zone', '0103000020E61000000100000005000000D122DBF97E12544091ED7C3F351E2A40B4C876BE9F12544091ED7C3F351E2A40B4C876BE9F125440AC1C5A643B1F2A40D122DBF97E125440AC1C5A643B1F2A40D122DBF97E12544091ED7C3F351E2A40', 15.00, 'Head inland via main promenade road', true, '2026-08-12 14:44:26.531184+05:30');
INSERT INTO public.safe_zones (id, beach_id, name, geom, elevation_m, route_notes, active, created_at) VALUES ('85694cb7-1744-4621-b109-8f5fac0466dc', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'Kamarajar Salai Roadside Safe Zone (Marina Beach)', '0103000020E61000000100000005000000448B6CE7FB1154409EEFA7C64B172A40355EBA490C1254409EEFA7C64B172A40355EBA490C1254402B8716D9CE172A40448B6CE7FB1154402B8716D9CE172A40448B6CE7FB1154409EEFA7C64B172A40', 5.00, 'Elevated road, away from waterline; default demo zone, verify with local disaster authority before production use', true, '2026-08-22 18:04:16.366195+05:30');
INSERT INTO public.safe_zones (id, beach_id, name, geom, elevation_m, route_notes, active, created_at) VALUES ('f2d61ef4-c307-4dd1-82f7-4e9f78488c41', 'e5afce33-9d88-45cf-b2a7-6d5257a262d4', 'Kamarajar Salai Roadside Safe Zone (Marina Beach)', '0103000020E61000000100000005000000D9CEF753E31154407F6ABC7493182A40448B6CE7FB1154407F6ABC7493182A40448B6CE7FB115440D34D621058192A40D9CEF753E3115440D34D621058192A40D9CEF753E31154407F6ABC7493182A40', 5.00, 'Cross Kamarajar Salai road, walk east toward safe zone marker', true, '2026-08-23 01:47:42.945129+05:30');


--
-- PostgreSQL database dump complete
--

\unrestrict EzS4tFwg2YpddSnJTerbRGFkyrIEPcTSLKP8Qigm27RicDWyUK0JExfeG4Vo0f6

