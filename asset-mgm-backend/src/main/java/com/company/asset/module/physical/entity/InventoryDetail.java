package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("inventory_detail")
public class InventoryDetail {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long taskId;
    private Long assetId;
    private Long expectedLocationId;
    private Long actualLocationId;
    private String expectedStatus;
    private String actualStatus;
    // NORMAL/SURPLUS/DEFICIT/LOCATION_DIFF
    private String result;
    private Long checkerId;
    private LocalDateTime checkTime;
    private String remark;
}
