-- GRC Queue Tracking System v2 — MySQL Schema
CREATE DATABASE IF NOT EXISTS queue_tracking_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE queue_tracking_db;

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('Admin','Staff','Student') NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS service_windows (
    window_id INT AUTO_INCREMENT PRIMARY KEY,
    window_name VARCHAR(50) NOT NULL,
    service_type ENUM('Registrar','Cashier','OSA') NOT NULL,
    assigned_staff_id INT DEFAULT NULL,
    is_open TINYINT(1) NOT NULL DEFAULT 0,
    skip_paused TINYINT(1) NOT NULL DEFAULT 0,
    queue_paused TINYINT(1) NOT NULL DEFAULT 0,
    mod_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    mod_by INT DEFAULT NULL,
    CONSTRAINT fk_sw_staff FOREIGN KEY (assigned_staff_id) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_sw_mod FOREIGN KEY (mod_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Per-service ticket numbering: R-001 C-001 O-001
-- A ticket ONLY appears on matching service_type window
CREATE TABLE IF NOT EXISTS queue_tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ticket_number VARCHAR(20) NOT NULL,
    service_type ENUM('Registrar','Cashier','OSA') NOT NULL,
    source ENUM('mobile','kiosk') NOT NULL DEFAULT 'mobile',
    walkin_name VARCHAR(100) DEFAULT NULL,
    walkin_id VARCHAR(30) DEFAULT NULL,
    year_section VARCHAR(50) DEFAULT NULL,
    purpose VARCHAR(200) DEFAULT NULL,
    window_id INT DEFAULT NULL,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    called_at TIMESTAMP NULL DEFAULT NULL,
    served_at TIMESTAMP NULL DEFAULT NULL,
    status ENUM('Waiting','Serving','Served','Skipped') NOT NULL DEFAULT 'Waiting',
    predicted_ert DECIMAL(8,2) DEFAULT NULL,
    skip_count TINYINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_qt_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_qt_window FOREIGN KEY (window_id) REFERENCES service_windows(window_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historical_data (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    actual_wait_time DECIMAL(8,2) NOT NULL,
    actual_service_time DECIMAL(8,2) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    queue_length_at_issue INT NOT NULL,
    time_of_day TINYINT NOT NULL,
    day_of_week TINYINT NOT NULL,
    windows_open_count TINYINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hd_ticket FOREIGN KEY (ticket_id) REFERENCES queue_tickets(ticket_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    action_detail TEXT NOT NULL,
    logged_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_al_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Default admin (password: Admin@123)
INSERT INTO users (username, password_hash, full_name, email, role) VALUES (
    'admin',
    '$2y$10$Uv.paWKTb5SN8caUw786wu6ba3T6u8aS0eFZiMTjpB.BHK1vYi/2G',
    'System Administrator', 'admin@grc.edu.ph', 'Admin'
);

-- MIGRATION: run this if you already have an existing database
-- ALTER TABLE queue_tickets ADD COLUMN skip_count TINYINT NOT NULL DEFAULT 0 AFTER predicted_ert;
-- ALTER TABLE service_windows ADD COLUMN skip_paused TINYINT(1) NOT NULL DEFAULT 0 AFTER is_open;

-- System settings table (for ERT override control panel)
CREATE TABLE IF NOT EXISTS system_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value VARCHAR(255) DEFAULT NULL,
    updated_by INT DEFAULT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ss_user FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Cashier walk-in transactions table
CREATE TABLE IF NOT EXISTS cashier_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    student_id VARCHAR(50) DEFAULT NULL,
    purpose VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    processed_by INT DEFAULT NULL,
    transaction_date DATE NOT NULL DEFAULT (CURDATE()),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ct_user FOREIGN KEY (processed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- MIGRATION (existing databases): run these in phpMyAdmin SQL tab
-- ALTER TABLE service_windows ADD COLUMN skip_paused TINYINT(1) NOT NULL DEFAULT 0 AFTER is_open;
-- CREATE TABLE IF NOT EXISTS system_settings (setting_id INT AUTO_INCREMENT PRIMARY KEY, setting_key VARCHAR(100) NOT NULL UNIQUE, setting_value VARCHAR(255) DEFAULT NULL, updated_by INT DEFAULT NULL, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB;
-- CREATE TABLE IF NOT EXISTS cashier_transactions (id INT AUTO_INCREMENT PRIMARY KEY, student_name VARCHAR(100) NOT NULL, student_id VARCHAR(50) DEFAULT NULL, purpose VARCHAR(200) NOT NULL, amount DECIMAL(10,2) DEFAULT NULL, notes TEXT DEFAULT NULL, processed_by INT DEFAULT NULL, transaction_date DATE NOT NULL DEFAULT (CURDATE()), created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB;

-- MIGRATION v28 — run these in phpMyAdmin SQL tab on existing databases:
-- ALTER TABLE queue_tickets ADD COLUMN year_section VARCHAR(50) DEFAULT NULL AFTER walkin_id;
-- ALTER TABLE queue_tickets ADD COLUMN purpose VARCHAR(200) DEFAULT NULL AFTER year_section;
-- ALTER TABLE service_windows ADD COLUMN queue_paused TINYINT(1) NOT NULL DEFAULT 0 AFTER skip_paused;
