package com.company.asset.module.physical.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.company.asset.module.physical.entity.PhysicalAsset;
import com.company.asset.module.physical.entity.QrCodePool;
import com.company.asset.module.physical.mapper.QrCodePoolMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class QrCodePoolService extends ServiceImpl<QrCodePoolMapper, QrCodePool> {

    private final PhysicalAssetService physicalAssetService;

    @Transactional
    public String generateBatch(int count) {
        String date = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String batchNo = generateBatchNo(date);

        long startSeq = count(new QueryWrapper<QrCodePool>().likeRight("qr_code", "QR-" + date));

        List<QrCodePool> list = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            QrCodePool pool = new QrCodePool();
            pool.setQrCode(String.format("QR-%s-%05d", date, startSeq + i + 1));
            pool.setStatus("AVAILABLE");
            pool.setBatchNo(batchNo);
            list.add(pool);
        }

        saveBatch(list);
        return batchNo;
    }

    @Transactional
    public void bindToAsset(String qrCode, Long assetId, Long operatorId) {
        QrCodePool pool = getOne(new QueryWrapper<QrCodePool>().eq("qr_code", qrCode));
        if (pool == null) throw new RuntimeException("二维码不存在");
        if (!"AVAILABLE".equals(pool.getStatus())) throw new RuntimeException("二维码已被使用");

        PhysicalAsset asset = physicalAssetService.getById(assetId);
        if (asset == null) throw new RuntimeException("资产不存在");

        pool.setStatus("BOUND");
        pool.setAssetId(assetId);
        pool.setBoundAt(LocalDateTime.now());
        pool.setBoundBy(operatorId);
        updateById(pool);

        asset.setQrCode(qrCode);
        physicalAssetService.updateById(asset);
    }

    public QrCodePool getByCode(String qrCode) {
        return getOne(new QueryWrapper<QrCodePool>().eq("qr_code", qrCode));
    }

    private String generateBatchNo(String date) {
        long count = count(new QueryWrapper<QrCodePool>().likeRight("batch_no", "BATCH-" + date));
        return String.format("BATCH-%s-%03d", date, count + 1);
    }

    private String generateUniqueQrCode(String date) {
        long count = count(new QueryWrapper<QrCodePool>().likeRight("qr_code", "QR-" + date));
        return String.format("QR-%s-%05d", date, count + 1);
    }
}
