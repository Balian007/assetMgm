package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("inspection_record")
public class InspectionRecord {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long taskId;
    private Long assetId;
    private Long inspectorId;
    private LocalDateTime checkTime;
    private java.math.BigDecimal gpsLat;
    private java.math.BigDecimal gpsLng;
    private String locationDesc;
    // NORMAL/ABNORMAL/NEED_REPAIR
    private String result;
    private String description;
    private String photos;  // JSON 数组
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
