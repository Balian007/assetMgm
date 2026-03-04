-- 资产管理系统模拟数据脚本（可重复执行）
-- 适用: MySQL 5.7+
-- 执行前请先导入 schema.sql

USE asset_mgm;

SET FOREIGN_KEY_CHECKS = 0;

-- ===================== 清理历史模拟数据 =====================

DELETE FROM inspection_record
WHERE task_id IN (SELECT id FROM inspection_task WHERE task_no LIKE 'IT-MOCK-%')
   OR asset_id IN (SELECT id FROM physical_asset WHERE asset_no LIKE 'PA-MOCK-%')
   OR description LIKE 'MOCK:%';

DELETE FROM inventory_detail
WHERE task_id IN (SELECT id FROM inventory_task WHERE task_no LIKE 'INV-MOCK-%')
   OR remark LIKE 'MOCK:%';

DELETE FROM maintenance_order WHERE order_no LIKE 'MO-MOCK-%';
DELETE FROM inspection_task WHERE task_no LIKE 'IT-MOCK-%';
DELETE FROM inventory_task WHERE task_no LIKE 'INV-MOCK-%';
DELETE FROM asset_transfer_log WHERE reason LIKE 'MOCK:%';

DELETE FROM digital_asset_access
WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');
DELETE FROM digital_asset_lineage
WHERE source_asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%')
   OR target_asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');
DELETE FROM digital_asset_file_version
WHERE file_asset_id IN (SELECT id FROM digital_asset_file
                        WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%'));
DELETE FROM digital_asset_file
WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');
DELETE FROM digital_asset_api
WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');
DELETE FROM digital_asset_table
WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');
DELETE FROM digital_asset_database
WHERE asset_id IN (SELECT id FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%');

DELETE FROM physical_asset WHERE asset_no LIKE 'PA-MOCK-%';
DELETE FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%';
DELETE FROM project WHERE project_no LIKE 'PRJ-MOCK-%';
DELETE FROM asset_location WHERE loc_name LIKE 'MOCK-%';

DELETE FROM sys_user_role
WHERE user_id IN (SELECT id FROM sys_user WHERE username LIKE 'mock_%');
DELETE FROM sys_user WHERE username LIKE 'mock_%';
DELETE FROM sys_role WHERE role_code LIKE 'MOCK_%';
DELETE FROM sys_dept WHERE dept_name LIKE '模拟部门%';

-- ===================== 构造通用序列表（1~100） =====================

DROP TEMPORARY TABLE IF EXISTS tmp_seq;
CREATE TEMPORARY TABLE tmp_seq (
    n INT PRIMARY KEY
);

INSERT INTO tmp_seq (n)
SELECT t.n + 1
FROM (
    SELECT a.i + b.i * 10 AS n
    FROM (
        SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) a
    CROSS JOIN (
        SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) b
) t
WHERE t.n < 100
ORDER BY t.n;

SET @admin_id := (SELECT id FROM sys_user WHERE username = 'admin' LIMIT 1);

-- ===================== 系统模块：角色、部门、用户 =====================

INSERT INTO sys_role (role_code, role_name, description) VALUES
('MOCK_AUDITOR', '审计员', '模拟数据-审计权限'),
('MOCK_SECOPS', '安全运维', '模拟数据-安全运维'),
('MOCK_DATA_OWNER', '数据负责人', '模拟数据-数据资产负责人'),
('MOCK_ASSET_ADMIN', '资产管理员', '模拟数据-资产台账维护'),
('MOCK_INSPECTOR', '巡检专员', '模拟数据-巡检执行'),
('MOCK_MAINTAINER', '维修专员', '模拟数据-故障处理'),
('MOCK_DATA_STEWARD', '数据管家', '模拟数据-数据质量维护'),
('MOCK_PM_ASSIST', '项目助理', '模拟数据-项目协同'),
('MOCK_OBSERVER', '观察员', '模拟数据-观测与只读'),
('MOCK_GUEST', '访客', '模拟数据-受限访问');

INSERT INTO sys_dept (parent_id, dept_name, sort_order, created_at) VALUES
(0, '模拟部门1-平台研发部', 1, NOW()),
(0, '模拟部门2-数据治理部', 2, NOW()),
(0, '模拟部门3-基础运维部', 3, NOW()),
(0, '模拟部门4-安全保障部', 4, NOW()),
(0, '模拟部门5-项目管理部', 5, NOW());

INSERT INTO sys_user (
    username, password, real_name, phone, email, dept_id, status, created_at, updated_at, deleted
)
SELECT
    CONCAT('mock_user_', LPAD(s.n, 3, '0')),
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH',
    CONCAT('模拟用户', LPAD(s.n, 3, '0')),
    CONCAT('1380000', LPAD(s.n, 4, '0')),
    CONCAT('mock_user_', LPAD(s.n, 3, '0'), '@example.com'),
    (SELECT id FROM sys_dept WHERE dept_name =
        CASE ((s.n - 1) % 5)
            WHEN 0 THEN '模拟部门1-平台研发部'
            WHEN 1 THEN '模拟部门2-数据治理部'
            WHEN 2 THEN '模拟部门3-基础运维部'
            WHEN 3 THEN '模拟部门4-安全保障部'
            ELSE '模拟部门5-项目管理部'
        END
     LIMIT 1),
    IF(s.n % 10 = 0, 0, 1),
    NOW() - INTERVAL s.n DAY,
    NOW() - INTERVAL (s.n DIV 2) DAY,
    0
FROM tmp_seq s
WHERE s.n <= 30;

INSERT INTO sys_user_role (user_id, role_id)
SELECT
    u.id,
    r.id
FROM sys_user u
JOIN sys_role r ON r.role_code =
    CASE MOD(CAST(RIGHT(u.username, 3) AS UNSIGNED), 8)
        WHEN 0 THEN 'ADMIN'
        WHEN 1 THEN 'OPS'
        WHEN 2 THEN 'PM'
        WHEN 3 THEN 'VIEWER'
        WHEN 4 THEN 'MOCK_INSPECTOR'
        WHEN 5 THEN 'MOCK_MAINTAINER'
        WHEN 6 THEN 'MOCK_DATA_OWNER'
        ELSE 'MOCK_ASSET_ADMIN'
    END
WHERE u.username LIKE 'mock_user_%';

-- ===================== 位置模块：30条树形位置 =====================

INSERT INTO asset_location (parent_id, loc_name, loc_type, address, description, sort_order, created_at)
SELECT
    0,
    CONCAT('MOCK-B', s.n),
    'BUILDING',
    CONCAT('模拟园区A区', s.n, '号楼'),
    'MOCK:模拟楼栋',
    s.n,
    NOW()
FROM tmp_seq s
WHERE s.n <= 3;

INSERT INTO asset_location (parent_id, loc_name, loc_type, address, description, sort_order, created_at)
SELECT
    b.id,
    CONCAT(b.loc_name, '-F', sf.n),
    'FLOOR',
    b.address,
    'MOCK:模拟楼层',
    sf.n,
    NOW()
FROM asset_location b
JOIN tmp_seq sf ON sf.n <= 3
WHERE b.loc_name LIKE 'MOCK-B%'
  AND b.loc_type = 'BUILDING';

INSERT INTO asset_location (parent_id, loc_name, loc_type, address, description, sort_order, created_at)
SELECT
    f.id,
    CONCAT(f.loc_name, '-R', sr.n),
    'ROOM',
    f.address,
    'MOCK:模拟机房',
    sr.n,
    NOW()
FROM asset_location f
JOIN tmp_seq sr ON sr.n <= 2
WHERE f.loc_name LIKE 'MOCK-B%-F%'
  AND f.loc_type = 'FLOOR';

-- ===================== 项目模块：40条 =====================

INSERT INTO project (
    project_no, project_name, description, manager_id, dept_id,
    start_date, end_date, status, location, created_at, updated_at, deleted
)
SELECT
    CONCAT('PRJ-MOCK-', LPAD(s.n, 3, '0')),
    CONCAT('模拟项目-', LPAD(s.n, 3, '0')),
    CONCAT('MOCK:用于联调和演示的项目数据 #', s.n),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM sys_dept WHERE dept_name =
        CASE ((s.n - 1) % 5)
            WHEN 0 THEN '模拟部门1-平台研发部'
            WHEN 1 THEN '模拟部门2-数据治理部'
            WHEN 2 THEN '模拟部门3-基础运维部'
            WHEN 3 THEN '模拟部门4-安全保障部'
            ELSE '模拟部门5-项目管理部'
        END
     LIMIT 1),
    CURDATE() - INTERVAL (s.n * 5) DAY,
    CURDATE() + INTERVAL (120 - s.n) DAY,
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'PLANNING'
        WHEN 2 THEN 'ACTIVE'
        WHEN 3 THEN 'COMPLETED'
        ELSE 'ARCHIVED'
    END,
    CONCAT('MOCK-B', ((s.n - 1) % 3) + 1),
    NOW() - INTERVAL s.n DAY,
    NOW() - INTERVAL (s.n DIV 2) DAY,
    0
FROM tmp_seq s
WHERE s.n <= 40;

-- ===================== 实物资产模块 =====================
-- 设备台账：100条

INSERT INTO physical_asset (
    asset_no, asset_name, category_id, brand, model, serial_no, spec,
    purchase_date, purchase_price, supplier, contract_no, warranty_years, warranty_expire,
    location_id, project_id, custodian_id, status,
    useful_life, residual_rate, depreciation_method,
    qr_code, remark, created_by, created_at, updated_at, deleted
)
SELECT
    CONCAT('PA-MOCK-', LPAD(s.n, 4, '0')),
    CONCAT('模拟实物资产-', LPAD(s.n, 4, '0')),
    (SELECT id FROM device_category WHERE cat_code =
        CASE MOD(s.n, 6)
            WHEN 1 THEN 'SERVER'
            WHEN 2 THEN 'SWITCH'
            WHEN 3 THEN 'ROUTER'
            WHEN 4 THEN 'FIREWALL'
            WHEN 5 THEN 'CAMERA'
            ELSE 'SENSOR'
        END
    LIMIT 1),
    ELT((MOD(s.n, 5) + 1), 'Huawei', 'H3C', 'Cisco', 'Dell', 'Lenovo'),
    CONCAT('Model-', LPAD((s.n % 50) + 1, 3, '0')),
    CONCAT('SN', LPAD(100000 + s.n, 8, '0')),
    JSON_OBJECT('cpu', CONCAT((s.n % 16) + 4, 'C'), 'memory', CONCAT((s.n % 8 + 1) * 8, 'GB'), 'note', 'MOCK'),
    CURDATE() - INTERVAL (s.n * 7) DAY,
    ROUND(5000 + s.n * 123.45, 2),
    CONCAT('模拟供应商-', ((s.n - 1) % 10) + 1),
    CONCAT('MOCK-CON-', LPAD(((s.n - 1) % 20) + 1, 3, '0')),
    CASE WHEN MOD(s.n, 2) = 0 THEN 3 ELSE 5 END,
    DATE_ADD(CURDATE(), INTERVAL ((s.n * 5) % 400 - 100) DAY),
    (SELECT id FROM asset_location
      WHERE loc_name = CONCAT(
          'MOCK-B', ((s.n - 1) % 3) + 1,
          '-F', (((s.n - 1) DIV 3) % 3) + 1,
          '-R', (((s.n - 1) DIV 9) % 2) + 1
      )
      LIMIT 1),
    (SELECT id FROM project WHERE project_no = CONCAT('PRJ-MOCK-', LPAD(((s.n - 1) % 40) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    CASE MOD(s.n, 5)
        WHEN 1 THEN 'IN_USE'
        WHEN 2 THEN 'IDLE'
        WHEN 3 THEN 'MAINTENANCE'
        WHEN 4 THEN 'SCRAPPED'
        ELSE 'TRANSFERRED'
    END,
    5 + (s.n % 6),
    0.0500,
    'STRAIGHT_LINE',
    CONCAT('QR://PA-MOCK-', LPAD(s.n, 4, '0')),
    CONCAT('MOCK:实物资产备注 #', s.n),
    @admin_id,
    NOW() - INTERVAL s.n DAY,
    NOW() - INTERVAL (s.n DIV 3) DAY,
    0
FROM tmp_seq s;

-- 巡检任务：40条
INSERT INTO inspection_task (
    task_no, task_name, project_id, location_id, assignee_id, plan_date, status, created_by, created_at
)
SELECT
    CONCAT('IT-MOCK-', LPAD(s.n, 3, '0')),
    CONCAT('模拟巡检任务-', LPAD(s.n, 3, '0')),
    (SELECT id FROM project WHERE project_no = CONCAT('PRJ-MOCK-', LPAD(((s.n - 1) % 40) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM asset_location WHERE loc_name = CONCAT(
        'MOCK-B', ((s.n - 1) % 3) + 1,
        '-F', (((s.n - 1) DIV 3) % 3) + 1,
        '-R', (((s.n - 1) DIV 9) % 2) + 1
    ) LIMIT 1),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    CURDATE() + INTERVAL (s.n % 21 - 10) DAY,
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'PENDING'
        WHEN 2 THEN 'IN_PROGRESS'
        WHEN 3 THEN 'COMPLETED'
        ELSE 'OVERDUE'
    END,
    @admin_id,
    NOW() - INTERVAL s.n DAY
FROM tmp_seq s
WHERE s.n <= 40;

-- 巡检记录：80条
INSERT INTO inspection_record (
    task_id, asset_id, inspector_id, check_time,
    gps_lat, gps_lng, location_desc, result, description, photos, created_at
)
SELECT
    (SELECT id FROM inspection_task WHERE task_no = CONCAT('IT-MOCK-', LPAD(((s.n - 1) % 40) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM physical_asset WHERE asset_no = CONCAT('PA-MOCK-', LPAD(((s.n - 1) % 100) + 1, 4, '0')) LIMIT 1),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    NOW() - INTERVAL s.n HOUR,
    ROUND(31.2000000 + s.n * 0.0001, 7),
    ROUND(121.4000000 + s.n * 0.0001, 7),
    CONCAT('MOCK-B', ((s.n - 1) % 3) + 1, '-F', ((s.n - 1) % 3) + 1, '-R', ((s.n - 1) % 2) + 1),
    CASE MOD(s.n, 3)
        WHEN 1 THEN 'NORMAL'
        WHEN 2 THEN 'ABNORMAL'
        ELSE 'NEED_REPAIR'
    END,
    CONCAT('MOCK:巡检记录说明 #', s.n),
    JSON_ARRAY(CONCAT('https://mock.local/inspection/', s.n, '.jpg')),
    NOW() - INTERVAL s.n HOUR
FROM tmp_seq s
WHERE s.n <= 80;

-- 维修工单：50条
INSERT INTO maintenance_order (
    order_no, asset_id, fault_desc, reporter_id, report_time,
    assignee_id, start_time, finish_time, result, cost, status, photos, created_at
)
SELECT
    CONCAT('MO-MOCK-', LPAD(s.n, 3, '0')),
    (SELECT id FROM physical_asset WHERE asset_no = CONCAT('PA-MOCK-', LPAD(((s.n - 1) % 100) + 1, 4, '0')) LIMIT 1),
    CONCAT('MOCK:故障描述 #', s.n),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    NOW() - INTERVAL s.n DAY,
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n + 5) % 30) + 1, 3, '0')) LIMIT 1),
    CASE WHEN MOD(s.n, 4) IN (2, 3) THEN NOW() - INTERVAL (s.n - 1) DAY ELSE NULL END,
    CASE WHEN MOD(s.n, 4) = 3 THEN NOW() - INTERVAL (s.n - 2) DAY ELSE NULL END,
    CASE WHEN MOD(s.n, 4) = 3 THEN CONCAT('MOCK:维修完成，已恢复 #', s.n) ELSE NULL END,
    CASE WHEN MOD(s.n, 4) = 3 THEN ROUND(200 + s.n * 8.8, 2) ELSE NULL END,
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'PENDING'
        WHEN 2 THEN 'IN_PROGRESS'
        WHEN 3 THEN 'COMPLETED'
        ELSE 'CANCELLED'
    END,
    JSON_ARRAY(CONCAT('https://mock.local/maintenance/', s.n, '.jpg')),
    NOW() - INTERVAL s.n DAY
FROM tmp_seq s
WHERE s.n <= 50;

-- 盘点任务：20条
INSERT INTO inventory_task (
    task_no, task_name, scope_type, scope_id, plan_date, status, created_by, created_at
)
SELECT
    CONCAT('INV-MOCK-', LPAD(s.n, 3, '0')),
    CONCAT('模拟盘点任务-', LPAD(s.n, 3, '0')),
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'ALL'
        WHEN 2 THEN 'PROJECT'
        WHEN 3 THEN 'LOCATION'
        ELSE 'CATEGORY'
    END,
    CASE MOD(s.n, 4)
        WHEN 1 THEN NULL
        WHEN 2 THEN (SELECT id FROM project WHERE project_no = CONCAT('PRJ-MOCK-', LPAD(((s.n - 1) % 40) + 1, 3, '0')) LIMIT 1)
        WHEN 3 THEN (SELECT id FROM asset_location WHERE loc_name = CONCAT(
            'MOCK-B', ((s.n - 1) % 3) + 1,
            '-F', (((s.n - 1) DIV 3) % 3) + 1,
            '-R', (((s.n - 1) DIV 9) % 2) + 1
        ) LIMIT 1)
        ELSE (SELECT id FROM device_category WHERE cat_code =
            CASE MOD(s.n, 6)
                WHEN 1 THEN 'SERVER'
                WHEN 2 THEN 'SWITCH'
                WHEN 3 THEN 'ROUTER'
                WHEN 4 THEN 'FIREWALL'
                WHEN 5 THEN 'CAMERA'
                ELSE 'SENSOR'
            END
         LIMIT 1)
    END,
    CURDATE() + INTERVAL (s.n % 15 - 7) DAY,
    CASE MOD(s.n, 3)
        WHEN 1 THEN 'DRAFT'
        WHEN 2 THEN 'IN_PROGRESS'
        ELSE 'COMPLETED'
    END,
    @admin_id,
    NOW() - INTERVAL s.n DAY
FROM tmp_seq s
WHERE s.n <= 20;

-- 盘点明细：100条
INSERT INTO inventory_detail (
    task_id, asset_id, expected_location_id, actual_location_id,
    expected_status, actual_status, result, checker_id, check_time, remark
)
SELECT
    (SELECT id FROM inventory_task WHERE task_no = CONCAT('INV-MOCK-', LPAD(((s.n - 1) % 20) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM physical_asset WHERE asset_no = CONCAT('PA-MOCK-', LPAD(((s.n - 1) % 100) + 1, 4, '0')) LIMIT 1),
    (SELECT id FROM asset_location WHERE loc_name = CONCAT(
        'MOCK-B', ((s.n - 1) % 3) + 1,
        '-F', (((s.n - 1) DIV 3) % 3) + 1,
        '-R', (((s.n - 1) DIV 9) % 2) + 1
    ) LIMIT 1),
    (SELECT id FROM asset_location WHERE loc_name = CONCAT(
        'MOCK-B', (s.n % 3) + 1,
        '-F', ((s.n DIV 3) % 3) + 1,
        '-R', ((s.n DIV 9) % 2) + 1
    ) LIMIT 1),
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'IN_USE'
        WHEN 2 THEN 'IDLE'
        WHEN 3 THEN 'MAINTENANCE'
        ELSE 'SCRAPPED'
    END,
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'IN_USE'
        WHEN 2 THEN 'IDLE'
        WHEN 3 THEN 'MAINTENANCE'
        ELSE 'SCRAPPED'
    END,
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'NORMAL'
        WHEN 2 THEN 'SURPLUS'
        WHEN 3 THEN 'DEFICIT'
        ELSE 'LOCATION_DIFF'
    END,
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    NOW() - INTERVAL s.n HOUR,
    CONCAT('MOCK:盘点明细 #', s.n)
FROM tmp_seq s;

-- ===================== 数字资产模块：80条 =====================

INSERT INTO digital_asset (
    asset_no, asset_name, category_id, project_id, description,
    data_level, data_type, storage_type, storage_path, storage_size,
    status, version, owner_id, custodian_id, quality_score,
    tags, extra_info, created_by, created_at, updated_at, deleted
)
SELECT
    CONCAT('DA-MOCK-', LPAD(s.n, 4, '0')),
    CONCAT('模拟数字资产-', LPAD(s.n, 4, '0')),
    (SELECT id FROM digital_asset_category WHERE cat_code =
        CASE MOD(s.n, 8)
            WHEN 1 THEN 'DATABASE'
            WHEN 2 THEN 'TABLE'
            WHEN 3 THEN 'DATASET'
            WHEN 4 THEN 'API'
            WHEN 5 THEN 'FILE'
            WHEN 6 THEN 'DOC'
            WHEN 7 THEN 'IMAGE'
            ELSE 'VIDEO'
        END
    LIMIT 1),
    (SELECT id FROM project WHERE project_no = CONCAT('PRJ-MOCK-', LPAD(((s.n - 1) % 40) + 1, 3, '0')) LIMIT 1),
    CONCAT('MOCK:数字资产描述 #', s.n),
    CASE MOD(s.n, 4)
        WHEN 1 THEN 'PUBLIC'
        WHEN 2 THEN 'INTERNAL'
        WHEN 3 THEN 'CONFIDENTIAL'
        ELSE 'SECRET'
    END,
    CASE WHEN MOD(s.n, 2) = 0 THEN 'STRUCTURED' ELSE 'UNSTRUCTURED' END,
    CASE MOD(s.n, 3)
        WHEN 1 THEN 'MYSQL'
        WHEN 2 THEN 'OSS'
        ELSE 'NAS'
    END,
    CONCAT('/mock/data/asset_', LPAD(s.n, 4, '0')),
    1024 * 1024 * ((s.n % 500) + 10),
    CASE MOD(s.n, 3)
        WHEN 1 THEN 'ACTIVE'
        WHEN 2 THEN 'DEPRECATED'
        ELSE 'ARCHIVED'
    END,
    CONCAT('v', (s.n % 5) + 1, '.', (s.n % 10)),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n - 1) % 30) + 1, 3, '0')) LIMIT 1),
    (SELECT id FROM sys_user WHERE username = CONCAT('mock_user_', LPAD(((s.n + 7) % 30) + 1, 3, '0')) LIMIT 1),
    ROUND(70 + (s.n % 30) + (s.n % 100) / 100, 2),
    JSON_ARRAY('MOCK', '数字资产', CONCAT('tag', MOD(s.n, 10))),
    JSON_OBJECT('source', 'mock-script', 'batch', s.n),
    @admin_id,
    NOW() - INTERVAL s.n DAY,
    NOW() - INTERVAL (s.n DIV 2) DAY,
    0
FROM tmp_seq s
WHERE s.n <= 80;

-- ===================== 统计输出 =====================

SELECT 'sys_user(mock)' AS module_name, COUNT(*) AS mock_count FROM sys_user WHERE username LIKE 'mock_user_%'
UNION ALL
SELECT 'sys_role(mock)', COUNT(*) FROM sys_role WHERE role_code LIKE 'MOCK_%'
UNION ALL
SELECT 'asset_location(mock)', COUNT(*) FROM asset_location WHERE loc_name LIKE 'MOCK-%'
UNION ALL
SELECT 'project(mock)', COUNT(*) FROM project WHERE project_no LIKE 'PRJ-MOCK-%'
UNION ALL
SELECT 'physical_asset(mock)', COUNT(*) FROM physical_asset WHERE asset_no LIKE 'PA-MOCK-%'
UNION ALL
SELECT 'inspection_task(mock)', COUNT(*) FROM inspection_task WHERE task_no LIKE 'IT-MOCK-%'
UNION ALL
SELECT 'inspection_record(mock)', COUNT(*) FROM inspection_record WHERE description LIKE 'MOCK:%'
UNION ALL
SELECT 'maintenance_order(mock)', COUNT(*) FROM maintenance_order WHERE order_no LIKE 'MO-MOCK-%'
UNION ALL
SELECT 'inventory_task(mock)', COUNT(*) FROM inventory_task WHERE task_no LIKE 'INV-MOCK-%'
UNION ALL
SELECT 'inventory_detail(mock)', COUNT(*) FROM inventory_detail WHERE remark LIKE 'MOCK:%'
UNION ALL
SELECT 'digital_asset(mock)', COUNT(*) FROM digital_asset WHERE asset_no LIKE 'DA-MOCK-%';

DROP TEMPORARY TABLE IF EXISTS tmp_seq;
SET FOREIGN_KEY_CHECKS = 1;
