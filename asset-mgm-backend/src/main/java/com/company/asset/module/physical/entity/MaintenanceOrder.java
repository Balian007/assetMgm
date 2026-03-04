package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("maintenance_order")
public class MaintenanceOrder {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String orderNo;
    private Long assetId;
    private String faultDesc;
    private Long reporterId;
    private LocalDateTime reportTime;
    private Long assigneeId;
    private LocalDateTime startTime;
    private LocalDateTime finishTime;
    private String result;
    private BigDecimal cost;
    // PENDING/IN_PROGRESS/COMPLETED/CANCELLED
    private String status;
    private String photos; // JSON
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
