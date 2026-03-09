

CREATE DATABASE IF NOT EXISTS asset_mgm DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE asset_mgm;

SET NAMES utf8mb4;
CREATE TABLE sys_dept (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    dept_name   VARCHAR(100) NOT NULL,
    sort_order  INT DEFAULT 0,
    leader_id   BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sys_user (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(50) NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    real_name   VARCHAR(50),
    phone       VARCHAR(20),
    email       VARCHAR(100),
    dept_id     BIGINT,
    status      TINYINT DEFAULT 1,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT DEFAULT 0
);

CREATE TABLE sys_role (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_code   VARCHAR(50) NOT NULL UNIQUE,
    role_name   VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sys_user_role (
    user_id     BIGINT NOT NULL,
    role_id     BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE sys_permission (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    perm_code   VARCHAR(100),
    perm_name   VARCHAR(50),
    perm_type   TINYINT,
    path        VARCHAR(200),
    sort_order  INT DEFAULT 0
);

CREATE TABLE sys_role_permission (
    role_id     BIGINT NOT NULL,
    perm_id     BIGINT NOT NULL,
    PRIMARY KEY (role_id, perm_id)
);

CREATE TABLE sys_operation_log (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT,
    username    VARCHAR(50),
    module      VARCHAR(50),
    action      VARCHAR(50),
    target_id   BIGINT,
    target_type VARCHAR(50),
    detail      TEXT,
    ip          VARCHAR(50),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_created (created_at)
);

CREATE TABLE sys_notification (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT NOT NULL,
    title       VARCHAR(200),
    content     TEXT,
    notify_type VARCHAR(30),
    ref_type    VARCHAR(50),
    ref_id      BIGINT,
    is_read     TINYINT DEFAULT 0,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id, is_read)
);

CREATE TABLE sys_attachment (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    biz_type    VARCHAR(50),
    biz_id      BIGINT,
    file_name   VARCHAR(500),
    file_size   BIGINT,
    mime_type   VARCHAR(100),
    storage_path VARCHAR(1000),
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_biz (biz_type, biz_id)
);

CREATE TABLE project (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    project_no      VARCHAR(50) NOT NULL UNIQUE,
    project_name    VARCHAR(200) NOT NULL,
    description     TEXT,
    manager_id      BIGINT,
    dept_id         BIGINT,
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(20) DEFAULT 'PLANNING',
    location        VARCHAR(200),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT DEFAULT 0
);

CREATE TABLE asset_location (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    loc_name    VARCHAR(100) NOT NULL,
    loc_type    VARCHAR(20),
    address     VARCHAR(200),
    description VARCHAR(500),
    sort_order  INT DEFAULT 0,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE device_category (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    cat_code    VARCHAR(50) UNIQUE,
    cat_name    VARCHAR(100) NOT NULL,
    sort_order  INT DEFAULT 0
);

CREATE TABLE physical_asset (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_no        VARCHAR(50) NOT NULL UNIQUE,
    asset_name      VARCHAR(200) NOT NULL,
    category_id     BIGINT NOT NULL,
    brand           VARCHAR(100),
    model           VARCHAR(100),
    serial_no       VARCHAR(100),
    spec            TEXT,
    purchase_date   DATE,
    purchase_price  DECIMAL(12,2),
    supplier        VARCHAR(200),
    contract_no     VARCHAR(100),
    warranty_years  INT,
    warranty_expire DATE,
    location_id     BIGINT,
    project_id      BIGINT,
    custodian_id    BIGINT,
    status          VARCHAR(20) DEFAULT 'IDLE',
    useful_life     INT,
    residual_rate   DECIMAL(5,4) DEFAULT 0.05,
    depreciation_method VARCHAR(20) DEFAULT 'STRAIGHT_LINE',
    qr_code         VARCHAR(200),
    remark          TEXT,
    created_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT DEFAULT 0,
    INDEX idx_category (category_id),
    INDEX idx_project (project_id),
    INDEX idx_status (status),
    INDEX idx_warranty (warranty_expire)
);

CREATE TABLE asset_transfer_log (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL,
    transfer_type   VARCHAR(30),
    from_project_id BIGINT,
    to_project_id   BIGINT,
    from_location_id BIGINT,
    to_location_id  BIGINT,
    from_status     VARCHAR(20),
    to_status       VARCHAR(20),
    operator_id     BIGINT,
    transfer_date   DATE,
    reason          VARCHAR(500),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_asset (asset_id)
);

CREATE TABLE inspection_task (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_no     VARCHAR(50) NOT NULL UNIQUE,
    task_name   VARCHAR(200),
    project_id  BIGINT,
    location_id BIGINT,
    assignee_id BIGINT,
    plan_date   DATE,
    status      VARCHAR(20) DEFAULT 'PENDING',
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inspection_record (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id         BIGINT,
    asset_id        BIGINT,
    inspector_id    BIGINT NOT NULL,
    check_time      DATETIME NOT NULL,
    gps_lat         DECIMAL(10,7),
    gps_lng         DECIMAL(10,7),
    location_desc   VARCHAR(200),
    result          VARCHAR(20),
    description     TEXT,
    photos          JSON,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task (task_id),
    INDEX idx_asset (asset_id),
    INDEX idx_inspector (inspector_id)
);

CREATE TABLE maintenance_order (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_no    VARCHAR(50) NOT NULL UNIQUE,
    asset_id    BIGINT NOT NULL,
    fault_desc  TEXT,
    reporter_id BIGINT,
    report_time DATETIME,
    assignee_id BIGINT,
    start_time  DATETIME,
    finish_time DATETIME,
    result      TEXT,
    cost        DECIMAL(10,2),
    status      VARCHAR(20) DEFAULT 'PENDING',
    photos      JSON,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_asset (asset_id)
);

CREATE TABLE inventory_task (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_no     VARCHAR(50) NOT NULL UNIQUE,
    task_name   VARCHAR(200),
    scope_type  VARCHAR(20),
    scope_id    BIGINT,
    plan_date   DATE,
    status      VARCHAR(20) DEFAULT 'DRAFT',
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_detail (
    id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id             BIGINT NOT NULL,
    asset_id            BIGINT NOT NULL,
    expected_location_id BIGINT,
    actual_location_id  BIGINT,
    expected_status     VARCHAR(20),
    actual_status       VARCHAR(20),
    result              VARCHAR(20),
    checker_id          BIGINT,
    check_time          DATETIME,
    remark              VARCHAR(500),
    INDEX idx_task (task_id)
);

CREATE TABLE digital_asset_category (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    cat_code    VARCHAR(50),
    cat_name    VARCHAR(100) NOT NULL,
    sort_order  INT DEFAULT 0
);

CREATE TABLE digital_asset (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_no        VARCHAR(50) NOT NULL UNIQUE,
    asset_name      VARCHAR(200) NOT NULL,
    category_id     BIGINT NOT NULL,
    project_id      BIGINT,
    description     TEXT,
    data_level      VARCHAR(20) DEFAULT 'INTERNAL',
    data_type       VARCHAR(20),
    storage_type    VARCHAR(30),
    storage_path    VARCHAR(500),
    storage_size    BIGINT,
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    version         VARCHAR(50),
    owner_id        BIGINT,
    custodian_id    BIGINT,
    quality_score   DECIMAL(5,2),
    tags            JSON,
    extra_info      JSON,
    created_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT DEFAULT 0,
    INDEX idx_category (category_id),
    INDEX idx_project (project_id),
    INDEX idx_data_level (data_level)
);

CREATE TABLE digital_asset_database (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    db_type         VARCHAR(30),
    host            VARCHAR(200),
    port            INT,
    db_name         VARCHAR(100),
    charset         VARCHAR(30),
    table_count     INT,
    total_size      BIGINT,
    last_sync_time  DATETIME
);

CREATE TABLE digital_asset_table (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    db_asset_id     BIGINT,
    table_name      VARCHAR(200),
    table_comment   VARCHAR(500),
    row_count       BIGINT,
    column_count    INT,
    columns_meta    JSON,
    last_sync_time  DATETIME
);

CREATE TABLE digital_asset_api (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    api_url         VARCHAR(500),
    method          VARCHAR(10),
    protocol        VARCHAR(20),
    auth_type       VARCHAR(30),
    request_schema  JSON,
    response_schema JSON,
    last_check_time DATETIME,
    last_status     VARCHAR(20),
    avg_response_ms INT,
    uptime_rate     DECIMAL(5,2)
);

CREATE TABLE digital_asset_file (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    file_name       VARCHAR(500),
    file_ext        VARCHAR(20),
    file_size       BIGINT,
    mime_type       VARCHAR(100),
    storage_path    VARCHAR(1000),
    checksum        VARCHAR(64),
    current_version VARCHAR(50)
);

CREATE TABLE digital_asset_file_version (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    file_asset_id   BIGINT NOT NULL,
    version         VARCHAR(50),
    file_size       BIGINT,
    storage_path    VARCHAR(1000),
    checksum        VARCHAR(64),
    change_log      TEXT,
    created_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_file_asset (file_asset_id)
);

CREATE TABLE digital_asset_access (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL,
    grantee_type    VARCHAR(20),
    grantee_id      BIGINT,
    access_level    VARCHAR(20),
    expire_date     DATE,
    granted_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_asset (asset_id),
    INDEX idx_grantee (grantee_type, grantee_id)
);

CREATE TABLE digital_asset_lineage (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    source_asset_id BIGINT NOT NULL,
    target_asset_id BIGINT NOT NULL,
    relation_type   VARCHAR(50),
    description     VARCHAR(500),
    created_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_asset_id),
    INDEX idx_target (target_asset_id)
);

-- Bootstrap seed data
INSERT INTO sys_user (username, password, real_name, status, deleted)
VALUES ('admin', '$2a$10$QemLg5.jo/hACQ6mIpfbeu4PMpsYJoiH6tNci.4qupATIt02Tk266', 'System Administrator', 1, 0)
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  real_name = VALUES(real_name),
  status = 1,
  deleted = 0;

INSERT INTO sys_role (role_code, role_name, description) VALUES
('ADMIN', 'Administrator', 'Full permissions'),
('OPS', 'Operations', 'Ops and inspection'),
('PM', 'Project Manager', 'Project and asset management'),
('VIEWER', 'Viewer', 'Read-only access')
ON DUPLICATE KEY UPDATE
  role_name = VALUES(role_name),
  description = VALUES(description);

INSERT INTO sys_user_role (user_id, role_id)
SELECT u.id, r.id
FROM sys_user u
JOIN sys_role r ON r.role_code = 'ADMIN'
WHERE u.username = 'admin'
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);

-- QR Code Pool
CREATE TABLE qr_code_pool (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    qr_code         VARCHAR(100) NOT NULL UNIQUE,
    status          VARCHAR(20) DEFAULT 'AVAILABLE',
    asset_id        BIGINT,
    bound_at        DATETIME,
    bound_by        BIGINT,
    batch_no        VARCHAR(50),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_asset (asset_id),
    INDEX idx_batch (batch_no)
);