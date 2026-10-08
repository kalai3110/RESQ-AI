-- =======================================================
-- AI-Based Disaster Response Assistant - MySQL Schema
-- =======================================================

CREATE DATABASE IF NOT EXISTS disaster_response_db;
USE disaster_response_db;

-- 1. Users Table (Role-based: Citizen, Rescue Worker, Admin)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(180) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'citizen',
    phone VARCHAR(30) DEFAULT NULL,
    firebase_uid VARCHAR(128) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Disaster Reports Table
CREATE TABLE IF NOT EXISTS disaster_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    disaster_type VARCHAR(60) NOT NULL,
    district VARCHAR(100) NOT NULL,
    area VARCHAR(150) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) DEFAULT NULL,
    longitude DECIMAL(10, 7) DEFAULT NULL,
    people_affected INT NOT NULL DEFAULT 0,
    injured INT NOT NULL DEFAULT 0,
    missing INT NOT NULL DEFAULT 0,
    immediate_help_required INT NOT NULL DEFAULT 0,
    property_damage TINYINT(1) DEFAULT 0,
    infrastructure_damage TINYINT(1) DEFAULT 0,
    damage_level VARCHAR(30) NOT NULL DEFAULT 'Medium',
    description TEXT,
    image_url VARCHAR(255) DEFAULT NULL,
    severity VARCHAR(30) NOT NULL DEFAULT 'MEDIUM',
    priority VARCHAR(10) NOT NULL DEFAULT 'P3',
    status VARCHAR(50) NOT NULL DEFAULT 'Reported',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Rescue Teams Table
CREATE TABLE IF NOT EXISTS rescue_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(120) NOT NULL,
    leader_name VARCHAR(120) NOT NULL,
    contact VARCHAR(40) NOT NULL,
    specialization VARCHAR(100) DEFAULT 'General Disaster Response',
    members_count INT DEFAULT 8,
    assigned_report_id INT DEFAULT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Available',
    current_location VARCHAR(150) DEFAULT 'Central Operations Base',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_report_id) REFERENCES disaster_reports(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Shelters Table
CREATE TABLE IF NOT EXISTS shelters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shelter_name VARCHAR(180) NOT NULL,
    location VARCHAR(180) NOT NULL,
    district VARCHAR(100) NOT NULL,
    address TEXT,
    latitude DECIMAL(10, 7) DEFAULT NULL,
    longitude DECIMAL(10, 7) DEFAULT NULL,
    capacity INT NOT NULL DEFAULT 100,
    occupied INT NOT NULL DEFAULT 0,
    available INT NOT NULL DEFAULT 100,
    food_available TINYINT(1) DEFAULT 1,
    water_available TINYINT(1) DEFAULT 1,
    medical_available TINYINT(1) DEFAULT 1,
    status VARCHAR(40) NOT NULL DEFAULT 'Available',
    contact_person VARCHAR(120) DEFAULT NULL,
    contact_phone VARCHAR(40) DEFAULT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Medical Assistance Requests Table
CREATE TABLE IF NOT EXISTS medical_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_id INT NOT NULL,
    injured_count INT NOT NULL DEFAULT 0,
    ambulance_required TINYINT(1) DEFAULT 0,
    first_aid_required TINYINT(1) DEFAULT 1,
    emergency_treatment_required TINYINT(1) DEFAULT 0,
    medical_required TINYINT(1) DEFAULT 1,
    status VARCHAR(50) NOT NULL DEFAULT 'Requested',
    assigned_hospital VARCHAR(150) DEFAULT NULL,
    ambulances_dispatched INT DEFAULT 0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (report_id) REFERENCES disaster_reports(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Relief Resources Table
CREATE TABLE IF NOT EXISTS relief_resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(120) NOT NULL,
    category VARCHAR(80) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    unit VARCHAR(40) NOT NULL DEFAULT 'units',
    status VARCHAR(40) NOT NULL DEFAULT 'Available',
    location VARCHAR(150) DEFAULT 'Main Emergency Depot',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT DEFAULT NULL,
    title VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(60) NOT NULL,
    report_id INT DEFAULT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (report_id) REFERENCES disaster_reports(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
