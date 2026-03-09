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
