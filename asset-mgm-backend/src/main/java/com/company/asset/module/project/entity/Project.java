package com.company.asset.module.project.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("project")
public class Project {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String projectNo;
    private String projectName;
    private String description;
    private Long managerId;
    private Long deptId;
    private LocalDate startDate;
    private LocalDate endDate;
    // PLANNING/ACTIVE/COMPLETED/ARCHIVED
    private String status;
    private String location;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
    @TableLogic
    private Integer deleted;
}
