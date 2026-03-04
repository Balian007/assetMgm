package com.company.asset.module.digital.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("digital_asset")
public class DigitalAsset {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String assetNo;
    private String assetName;
    private Long categoryId;
    private Long projectId;
    private String description;

    // PUBLIC/INTERNAL/CONFIDENTIAL/SECRET
    private String dataLevel;
    // STRUCTURED/UNSTRUCTURED
    private String dataType;

    private String storageType;
    private String storagePath;
    private Long storageSize;

    // ACTIVE/DEPRECATED/ARCHIVED
    private String status;
    private String version;

    private Long ownerId;
    private Long custodianId;
    private Double qualityScore;
    private String tags;      // JSON
    private String extraInfo; // JSON

    @TableField(fill = FieldFill.INSERT)
    private Long createdBy;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
    @TableLogic
    private Integer deleted;
}
