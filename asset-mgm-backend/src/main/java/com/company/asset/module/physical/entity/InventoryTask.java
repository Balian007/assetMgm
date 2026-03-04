package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("inventory_task")
public class InventoryTask {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String taskNo;
    private String taskName;
    // ALL/PROJECT/LOCATION/CATEGORY
    private String scopeType;
    private Long scopeId;
    private LocalDate planDate;
    // DRAFT/IN_PROGRESS/COMPLETED
    private String status;
    @TableField(fill = FieldFill.INSERT)
    private Long createdBy;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
