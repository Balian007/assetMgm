-- 资产管理系统数据库建表脚本
-- 数据库: asset_mgm
-- 字符集: utf8mb4

CREATE DATABASE IF NOT EXISTS asset_mgm DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE asset_mgm;

-- ===================== 系统层 =====================

CREATE TABLE sys_dept (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    dept_name   VARCHAR(100) NOT NULL COMMENT '部门名称',
    sort_order  INT DEFAULT 0,
    leader_id   BIGINT COMMENT '负责人ID',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '部门表';

CREATE TABLE sys_user (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(50) NOT NULL UNIQUE COMMENT '登录名',
    password    VARCHAR(100) NOT NULL COMMENT 'BCrypt加密',
    real_name   VARCHAR(50) COMMENT '真实姓名',
    phone       VARCHAR(20),
    email       VARCHAR(100),
    dept_id     BIGINT COMMENT '部门ID',
    status      TINYINT DEFAULT 1 COMMENT '1启用 0禁用',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT DEFAULT 0
) COMMENT '用户表';

CREATE TABLE sys_role (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_code   VARCHAR(50) NOT NULL UNIQUE COMMENT 'ADMIN/OPS/PM/VIEWER',
    role_name   VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '角色表';

CREATE TABLE sys_user_role (
    user_id     BIGINT NOT NULL,
    role_id     BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id)
) COMMENT '用户角色关联';

CREATE TABLE sys_permission (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    perm_code   VARCHAR(100) COMMENT '权限码: physical:device:edit',
    perm_name   VARCHAR(50),
    perm_type   TINYINT COMMENT '1菜单 2按钮 3接口',
    path        VARCHAR(200),
    sort_order  INT DEFAULT 0
) COMMENT '权限表';

CREATE TABLE sys_role_permission (
    role_id     BIGINT NOT NULL,
    perm_id     BIGINT NOT NULL,
    PRIMARY KEY (role_id, perm_id)
) COMMENT '角色权限关联';

CREATE TABLE sys_operation_log (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT,
    username    VARCHAR(50),
    module      VARCHAR(50),
    action      VARCHAR(50),
    target_id   BIGINT,
    target_type VARCHAR(50),
    detail      TEXT COMMENT 'JSON',
    ip          VARCHAR(50),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_created (created_at)
) COMMENT '操作日志';

CREATE TABLE sys_notification (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT NOT NULL,
    title       VARCHAR(200),
    content     TEXT,
    notify_type VARCHAR(30) COMMENT 'WARRANTY_EXPIRE/INSPECTION_OVERDUE/ASSET_CHANGE',
    ref_type    VARCHAR(50),
    ref_id      BIGINT,
    is_read     TINYINT DEFAULT 0,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id, is_read)
) COMMENT '系统通知';

CREATE TABLE sys_attachment (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    biz_type    VARCHAR(50) COMMENT '业务类型',
    biz_id      BIGINT,
    file_name   VARCHAR(500),
    file_size   BIGINT,
    mime_type   VARCHAR(100),
    storage_path VARCHAR(1000),
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_biz (biz_type, biz_id)
) COMMENT '通用附件';

-- ===================== 项目层 =====================

CREATE TABLE project (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    project_no      VARCHAR(50) NOT NULL UNIQUE,
    project_name    VARCHAR(200) NOT NULL,
    description     TEXT,
    manager_id      BIGINT,
    dept_id         BIGINT,
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(20) DEFAULT 'PLANNING' COMMENT 'PLANNING/ACTIVE/COMPLETED/ARCHIVED',
    location        VARCHAR(200),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         TINYINT DEFAULT 0
) COMMENT '项目表';

-- ===================== 实物资产层 =====================

CREATE TABLE asset_location (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    loc_name    VARCHAR(100) NOT NULL,
    loc_type    VARCHAR(20) COMMENT 'BUILDING/FLOOR/ROOM/CABINET/RACK',
    address     VARCHAR(200),
    description VARCHAR(500),
    sort_order  INT DEFAULT 0,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '位置层级';

CREATE TABLE device_category (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    cat_code    VARCHAR(50) UNIQUE COMMENT 'SERVER/SWITCH/ROUTER/FIREWALL/CAMERA/IOT',
    cat_name    VARCHAR(100) NOT NULL,
    sort_order  INT DEFAULT 0
) COMMENT '设备分类';

CREATE TABLE physical_asset (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_no        VARCHAR(50) NOT NULL UNIQUE,
    asset_name      VARCHAR(200) NOT NULL,
    category_id     BIGINT NOT NULL,
    brand           VARCHAR(100),
    model           VARCHAR(100),
    serial_no       VARCHAR(100),
    spec            TEXT COMMENT '规格参数JSON',
    purchase_date   DATE,
    purchase_price  DECIMAL(12,2),
    supplier        VARCHAR(200),
    contract_no     VARCHAR(100),
    warranty_years  INT,
    warranty_expire DATE,
    location_id     BIGINT,
    project_id      BIGINT,
    custodian_id    BIGINT,
    status          VARCHAR(20) DEFAULT 'IDLE' COMMENT 'IN_USE/IDLE/MAINTENANCE/SCRAPPED/TRANSFERRED',
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
) COMMENT '实物资产台账';

CREATE TABLE asset_transfer_log (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL,
    transfer_type   VARCHAR(30) COMMENT 'PURCHASE_IN/ALLOCATE/TRANSFER/REPAIR_OUT/REPAIR_IN/SCRAP',
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
) COMMENT '资产流转记录';

CREATE TABLE inspection_task (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_no     VARCHAR(50) NOT NULL UNIQUE,
    task_name   VARCHAR(200),
    project_id  BIGINT,
    location_id BIGINT,
    assignee_id BIGINT,
    plan_date   DATE,
    status      VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/IN_PROGRESS/COMPLETED/OVERDUE',
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '巡检任务';

CREATE TABLE inspection_record (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id         BIGINT,
    asset_id        BIGINT,
    inspector_id    BIGINT NOT NULL,
    check_time      DATETIME NOT NULL,
    gps_lat         DECIMAL(10,7),
    gps_lng         DECIMAL(10,7),
    location_desc   VARCHAR(200),
    result          VARCHAR(20) COMMENT 'NORMAL/ABNORMAL/NEED_REPAIR',
    description     TEXT,
    photos          JSON,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task (task_id),
    INDEX idx_asset (asset_id),
    INDEX idx_inspector (inspector_id)
) COMMENT '巡检打卡记录';

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
    status      VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/IN_PROGRESS/COMPLETED/CANCELLED',
    photos      JSON,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_asset (asset_id)
) COMMENT '维修工单';

CREATE TABLE inventory_task (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_no     VARCHAR(50) NOT NULL UNIQUE,
    task_name   VARCHAR(200),
    scope_type  VARCHAR(20) COMMENT 'ALL/PROJECT/LOCATION/CATEGORY',
    scope_id    BIGINT,
    plan_date   DATE,
    status      VARCHAR(20) DEFAULT 'DRAFT',
    created_by  BIGINT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '盘点任务';

CREATE TABLE inventory_detail (
    id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id             BIGINT NOT NULL,
    asset_id            BIGINT NOT NULL,
    expected_location_id BIGINT,
    actual_location_id  BIGINT,
    expected_status     VARCHAR(20),
    actual_status       VARCHAR(20),
    result              VARCHAR(20) COMMENT 'NORMAL/SURPLUS/DEFICIT/LOCATION_DIFF',
    checker_id          BIGINT,
    check_time          DATETIME,
    remark              VARCHAR(500),
    INDEX idx_task (task_id)
) COMMENT '盘点明细';

-- ===================== 数字资产层 =====================

CREATE TABLE digital_asset_category (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT DEFAULT 0,
    cat_code    VARCHAR(50) COMMENT 'DATABASE/TABLE/DATASET/API/FILE/DOC/IMAGE/VIDEO/MODEL',
    cat_name    VARCHAR(100) NOT NULL,
    sort_order  INT DEFAULT 0
) COMMENT '数字资产分类';

CREATE TABLE digital_asset (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_no        VARCHAR(50) NOT NULL UNIQUE,
    asset_name      VARCHAR(200) NOT NULL,
    category_id     BIGINT NOT NULL,
    project_id      BIGINT,
    description     TEXT,
    data_level      VARCHAR(20) DEFAULT 'INTERNAL' COMMENT 'PUBLIC/INTERNAL/CONFIDENTIAL/SECRET',
    data_type       VARCHAR(20) COMMENT 'STRUCTURED/UNSTRUCTURED',
    storage_type    VARCHAR(30),
    storage_path    VARCHAR(500),
    storage_size    BIGINT,
    status          VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE/DEPRECATED/ARCHIVED',
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
) COMMENT '数字资产主表';

CREATE TABLE digital_asset_database (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    db_type         VARCHAR(30) COMMENT 'MySQL/Oracle/PostgreSQL/MongoDB',
    host            VARCHAR(200),
    port            INT,
    db_name         VARCHAR(100),
    charset         VARCHAR(30),
    table_count     INT,
    total_size      BIGINT,
    last_sync_time  DATETIME
) COMMENT '数据库资产详情';

CREATE TABLE digital_asset_table (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL UNIQUE,
    db_asset_id     BIGINT,
    table_name      VARCHAR(200),
    table_comment   VARCHAR(500),
    row_count       BIGINT,
    column_count    INT,
    columns_meta    JSON COMMENT '字段元数据',
    last_sync_time  DATETIME
) COMMENT '数据表资产详情';

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
    last_status     VARCHAR(20) COMMENT 'UP/DOWN/TIMEOUT',
    avg_response_ms INT,
    uptime_rate     DECIMAL(5,2)
) COMMENT 'API接口资产详情';

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
) COMMENT '文件资产详情';

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
) COMMENT '文件版本历史';

CREATE TABLE digital_asset_access (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    asset_id        BIGINT NOT NULL,
    grantee_type    VARCHAR(20) COMMENT 'USER/ROLE/DEPT',
    grantee_id      BIGINT,
    access_level    VARCHAR(20) COMMENT 'READ/WRITE/ADMIN',
    expire_date     DATE,
    granted_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_asset (asset_id),
    INDEX idx_grantee (grantee_type, grantee_id)
) COMMENT '数字资产访问授权';

CREATE TABLE digital_asset_lineage (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    source_asset_id BIGINT NOT NULL,
    target_asset_id BIGINT NOT NULL,
    relation_type   VARCHAR(50) COMMENT 'DERIVED_FROM/FEEDS_INTO/REFERENCES',
    description     VARCHAR(500),
    created_by      BIGINT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_asset_id),
    INDEX idx_target (target_asset_id)
) COMMENT '数据血缘关系';

-- ===================== 初始化数据 =====================

-- 初始管理员账号 (密码: Admin@123)
INSERT INTO sys_user (username, password, real_name, status)
VALUES ('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '系统管理员', 1);

-- 角色
INSERT INTO sys_role (role_code, role_name, description) VALUES
('ADMIN', '系统管理员', '拥有所有权限'),
('OPS', '运维人员', '负责设备巡检和维护'),
('PM', '项目经理', '管理项目资产'),
('VIEWER', '只读用户', '仅查看权限');

-- 设备分类
INSERT INTO device_category (parent_id, cat_code, cat_name, sort_order) VALUES
(0, 'COMPUTE', '计算设备', 1),
(0, 'NETWORK', '网络设备', 2),
(0, 'SECURITY', '安防设备', 3),
(0, 'IOT', '物联网设备', 4),
(1, 'SERVER', '服务器', 11),
(1, 'WORKSTATION', '工作站', 12),
(2, 'SWITCH', '交换机', 21),
(2, 'ROUTER', '路由器', 22),
(2, 'FIREWALL', '防火墙', 23),
(3, 'CAMERA', '摄像头', 31),
(3, 'NVR', '录像机', 32),
(4, 'SENSOR', '传感器', 41),
(4, 'GATEWAY', '网关', 42);

-- 数字资产分类
INSERT INTO digital_asset_category (parent_id, cat_code, cat_name, sort_order) VALUES
(0, 'STRUCTURED', '结构化数据', 1),
(0, 'UNSTRUCTURED', '非结构化数据', 2),
(1, 'DATABASE', '数据库', 11),
(1, 'TABLE', '数据表', 12),
(1, 'DATASET', '数据集', 13),
(1, 'API', 'API接口', 14),
(2, 'FILE', '文件', 21),
(2, 'DOC', '文档', 22),
(2, 'IMAGE', '图片', 23),
(2, 'VIDEO', '视频', 24),
(2, 'MODEL', '模型文件', 25);
