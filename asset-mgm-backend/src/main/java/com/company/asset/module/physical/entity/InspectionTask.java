package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("inspection_task")
public class InspectionTask {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String taskNo;
    private String taskName;
    private Long projectId;
    private Long locationId;
    private Long assigneeId;
    private LocalDate planDate;
    // PENDING/IN_PROGRESS/COMPLETED/OVERDUE
    private String status;
    @TableField(fill = FieldFill.INSERT)
    private Long createdBy;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
