package com.company.asset.module.system.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName("asset_location")
public class AssetLocation {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long parentId;
    private String locName;
    // BUILDING/FLOOR/ROOM/CABINET/RACK
    private String locType;
    private String address;
    private String description;
    private Integer sortOrder;
    @TableField(exist = false)
    private List<AssetLocation> children;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
