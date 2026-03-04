package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("physical_asset")
public class PhysicalAsset {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String assetNo;
    private String assetName;
    private Long categoryId;
    private String brand;
    private String model;
    private String serialNo;
    private String spec;           // JSON 规格参数

    // 采购信息
    private LocalDate purchaseDate;
    private BigDecimal purchasePrice;
    private String supplier;
    private String contractNo;
    private Integer warrantyYears;
    private LocalDate warrantyExpire;

    // 位置与归属
    private Long locationId;
    private Long projectId;
    private Long custodianId;

    // 状态: IN_USE/IDLE/MAINTENANCE/SCRAPPED/TRANSFERRED
    private String status;

    // 折旧
    private Integer usefulLife;
    private BigDecimal residualRate;
    private String depreciationMethod;

    private String qrCode;
    private String remark;

    @TableField(fill = FieldFill.INSERT)
    private Long createdBy;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
    @TableLogic
    private Integer deleted;
}
