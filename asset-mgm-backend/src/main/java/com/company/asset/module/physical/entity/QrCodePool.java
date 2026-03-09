package com.company.asset.module.physical.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("qr_code_pool")
public class QrCodePool {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String qrCode;
    private String status;
    private Long assetId;
    private LocalDateTime boundAt;
    private Long boundBy;
    private String batchNo;
    private LocalDateTime createdAt;
}
