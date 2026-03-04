package com.company.asset.module.system.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_dept")
public class SysDept {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long parentId;
    private String deptName;
    private Integer sortOrder;
    private Long leaderId;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
