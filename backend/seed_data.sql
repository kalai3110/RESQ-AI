-- =======================================================
-- Seed Realistic Initial Data for Disaster Response Demo
-- =======================================================

USE disaster_response_db;

-- 1. Insert Initial Users
-- Password for all demo accounts: password123 (hashed with SHA256 or bcrypt)
INSERT INTO users (id, name, email, password_hash, role, phone) VALUES
(1, 'Commander Alex Vance', 'admin@disaster.org', 'pbkdf2:sha256:600000$adminpass$8f4a13e2bf5efd4b68f5c66e921d7b3a985d8d0b57fa0d110795c64394f1c9c4', 'admin', '+91 98401 11223'),
(2, 'Captain Rajesh Kumar (Rescue Alpha)', 'rescue.alpha@disaster.org', 'pbkdf2:sha256:600000$rescuepass$8f4a13e2bf5efd4b68f5c66e921d7b3a985d8d0b57fa0d110795c64394f1c9c4', 'rescue', '+91 94440 22334'),
(3, 'Dr. Sarah Connor (Medical Unit)', 'medical@disaster.org', 'pbkdf2:sha256:600000$medicpass$8f4a13e2bf5efd4b68f5c66e921d7b3a985d8d0b57fa0d110795c64394f1c9c4', 'rescue', '+91 98840 33445'),
(4, 'Priya Sharma (Citizen)', 'priya@gmail.com', 'pbkdf2:sha256:600000$citizenpass$8f4a13e2bf5efd4b68f5c66e921d7b3a985d8d0b57fa0d110795c64394f1c9c4', 'citizen', '+91 91760 44556'),
(5, 'Karthik Raja (Citizen)', 'karthik@gmail.com', 'pbkdf2:sha256:600000$citizenpass$8f4a13e2bf5efd4b68f5c66e921d7b3a985d8d0b57fa0d110795c64394f1c9c4', 'citizen', '+91 98410 55667');

-- 2. Insert Initial Disaster Reports
INSERT INTO disaster_reports (id, user_id, disaster_type, district, area, address, latitude, longitude, people_affected, injured, missing, immediate_help_required, property_damage, infrastructure_damage, damage_level, description, image_url, severity, priority, status) VALUES
(1025, 4, 'Flood', 'Madurai', 'Vaigai Riverbed Sector 4', 'Near Goripalayam Bridge & Anna Nagar Lowlands', 9.9252000, 78.1198000, 200, 40, 15, 65, 1, 1, 'High', 'Severe flash flooding following intense continuous rainfall. Multiple houses submerged, 15 people trapped on rooftops.', NULL, 'CRITICAL', 'P1', 'Rescue in Progress'),
(1026, 5, 'Cyclone', 'Cuddalore', 'Coastal Ward 12', 'Silver Beach Fishermen Colony, Block C', 11.7480000, 79.7714000, 150, 18, 4, 30, 1, 1, 'Critical', 'Cyclone storm surge damaged roofs and uprooted power lines. Boats damaged, several families displaced.', NULL, 'HIGH', 'P2', 'Verified'),
(1027, 4, 'Fire', 'Chennai', 'Guindy Industrial Estate', 'Plot 45, Phase II, Near Metro Station', 13.0067000, 80.2026000, 45, 12, 0, 15, 1, 0, 'Medium', 'Chemical warehouse fire breakout. Toxic smoke spreading to adjacent residential area.', NULL, 'HIGH', 'P2', 'Rescue in Progress'),
(1028, 5, 'Landslide', 'Nilgiris', 'Coonoor Ghat Road Km 14', 'Near Marapalam Bridge & Tea Estate', 11.3530000, 76.7959000, 35, 5, 2, 8, 1, 1, 'Medium', 'Debris and boulder blockage on main arterial highway. 3 vehicles trapped under earth mound.', NULL, 'MEDIUM', 'P3', 'Verified'),
(1029, 4, 'Accident', 'Salem', 'NH44 Bypass Junction', 'Near Kondalampatti Roundabout', 11.6643000, 78.1460000, 15, 8, 0, 8, 1, 0, 'Low', 'Multi-vehicle collision involving bus and cargo trucks. First responders required for extrication.', NULL, 'LOW', 'P4', 'Resolved');

-- 3. Insert Rescue Teams
INSERT INTO rescue_teams (id, team_name, leader_name, contact, specialization, members_count, assigned_report_id, status, current_location) VALUES
(1, 'Rescue Team Alpha', 'Captain Rajesh Kumar', '+91 94440 22334', 'Flood & Swift Water Rescue', 12, 1025, 'On the Way', 'En route to Goripalayam, Madurai'),
(2, 'Rescue Team Bravo', 'Lieutenant Vikram Rao', '+91 94440 55661', 'Urban Search & Collapse Rescue', 10, 1027, 'Reached', 'Guindy Industrial Zone, Chennai'),
(3, 'Rescue Team Charlie', 'Major S. Sundaram', '+91 94440 77882', 'Mountain & Landslide Extrication', 8, 1028, 'Preparing', 'Coonoor Fire & Rescue Station'),
(4, 'Rescue Team Delta', 'Inspector Anitha Mary', '+91 94440 99003', 'Cyclone Evacuation & Medical Escort', 14, 1026, 'Assigned', 'Cuddalore Coastal Command HQ'),
(5, 'Rescue Team Echo (Reserve)', 'Sub-Inspector Mohan Raj', '+91 94440 11225', 'Rapid Triage & First Response', 8, NULL, 'Available', 'State Disaster Emergency Hub');

-- 4. Insert Shelters
INSERT INTO shelters (id, shelter_name, location, district, address, latitude, longitude, capacity, occupied, available, food_available, water_available, medical_available, status, contact_person, contact_phone) VALUES
(1, 'Government Relief Shelter - Central', 'Goripalayam Community Hall', 'Madurai', 'No 12, College Road, Goripalayam', 9.9320000, 78.1250000, 500, 320, 180, 1, 1, 1, 'Available', 'Thiru R. Murugan', '+91 98421 77112'),
(2, 'Cuddalore Coastal Cyclone Shelter #3', 'Silver Beach High School', 'Cuddalore', 'Main Beach Road, Devanampattinam', 11.7510000, 79.7740000, 400, 380, 20, 1, 1, 1, 'Limited', 'Mrs. K. Malathi', '+91 94432 88223'),
(3, 'Guindy Relief & Transit Camp', 'Alagappa School Grounds', 'Chennai', 'GST Road, Guindy, Chennai', 13.0100000, 80.2080000, 300, 110, 190, 1, 1, 1, 'Available', 'Mr. S. Ramesh', '+91 98402 99334'),
(4, 'Nilgiris Hill Relief Center', 'Coonoor Municipal Town Hall', 'Nilgiris', 'Upper Coonoor Market Road', 11.3560000, 76.7990000, 150, 150, 0, 1, 1, 1, 'Full', 'Mr. J. George', '+91 94860 11445'),
(5, 'Anna Nagar Disaster Refuge Hub', 'Madurai Corporation Indoor Stadium', 'Madurai', '80 Feet Road, Anna Nagar, Madurai', 9.9180000, 78.1400000, 600, 210, 390, 1, 1, 1, 'Available', 'Mrs. B. Kavitha', '+91 97900 55667');

-- 5. Insert Medical Assistance Requests
INSERT INTO medical_requests (id, report_id, injured_count, ambulance_required, first_aid_required, emergency_treatment_required, medical_required, status, assigned_hospital, ambulances_dispatched) VALUES
(1, 1025, 40, 1, 1, 1, 1, 'On the Way', 'Madurai Government Rajaji Hospital (GRH)', 4),
(2, 1026, 18, 1, 1, 0, 1, 'Assigned', 'Cuddalore District Headquarters Hospital', 2),
(3, 1027, 12, 1, 1, 1, 1, 'On the Way', 'Kalaignar Centenary Super Speciality Hospital, Guindy', 3),
(4, 1028, 5, 0, 1, 0, 1, 'Requested', 'Coonoor Government Lawley Hospital', 1);

-- 6. Insert Relief Resources
INSERT INTO relief_resources (id, resource_name, category, quantity, unit, status, location) VALUES
(1, 'Food Packets', 'Nutrition', 850, 'packets', 'Available', 'Madurai Emergency Supply Depot'),
(2, 'Drinking Water Bottles (1L)', 'Hydration', 1200, 'bottles', 'Available', 'Madurai Emergency Supply Depot'),
(3, 'Medicines & First Aid Kits', 'Medical', 150, 'kits', 'Limited', 'State Central Medical Store'),
(4, 'Blankets & Warm Clothes', 'Shelter & Bedding', 80, 'pieces', 'Low', 'Cuddalore Relief Depot'),
(5, 'Inflatable Rescue Boats', 'Rescue Equipment', 12, 'boats', 'Available', 'State Disaster Management Depot'),
(6, 'Life Jackets & Buoys', 'Rescue Equipment', 220, 'pieces', 'Available', 'Coastal Command Base'),
(7, 'Emergency Power Generators', 'Power & Utility', 15, 'units', 'Available', 'State Electricity Board Store');

-- 7. Insert Notifications
INSERT INTO notifications (id, user_id, title, message, notification_type, report_id, is_read) VALUES
(1, NULL, '🚨 P1 Critical Disaster Reported', 'Flood reported in Madurai (Vaigai Riverbed Sector 4). 200 people affected, 40 injured.', 'disaster_report', 1025, 0),
(2, 4, '🤖 AI Severity Analysis Completed', 'Report #DR-1025 classified as CRITICAL SEVERITY (Priority P1 – Immediate Response Required).', 'ai_severity', 1025, 0),
(3, 4, '🚑 Rescue Team Alpha Assigned', 'Rescue Team Alpha (12 members) has been dispatched and is currently On the Way to your location.', 'rescue_assigned', 1025, 0),
(4, NULL, '🏥 Medical Assistance Dispatched', '4 Ambulances dispatched from GRH Madurai to Vaigai Riverbed Sector 4.', 'medical_assigned', 1025, 0),
(5, NULL, '🏕️ Relief Shelter Capacity Updated', 'Goripalayam Community Hall has 180 available seats with food, water and medical facilities.', 'shelter_update', NULL, 1);
