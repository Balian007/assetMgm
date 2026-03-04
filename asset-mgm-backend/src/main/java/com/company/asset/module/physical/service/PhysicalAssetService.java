package com.company.asset.module.physical.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.company.asset.common.exception.BusinessException;
import com.company.asset.module.physical.entity.PhysicalAsset;
import com.company.asset.module.physical.mapper.PhysicalAssetMapper;
import com.company.asset.module.project.entity.Project;
import com.company.asset.module.project.mapper.ProjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Year;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PhysicalAssetService extends ServiceImpl<PhysicalAssetMapper, PhysicalAsset> {

    private final ProjectMapper projectMapper;

    public IPage<Map<String, Object>> pageList(int pageNum, int pageSize,
                                                String assetName, Long categoryId,
                                                String status, Long projectId) {
        Page<Map<String, Object>> page = new Page<>(pageNum, pageSize, false);
        IPage<Map<String, Object>> result = baseMapper.selectPageWithDetail(page, assetName, categoryId, status, projectId);
        Long total = baseMapper.selectPageWithDetailCount(assetName, categoryId, status, projectId);
        result.setTotal(total != null ? total : 0);
        return result;
    }

    public PhysicalAsset createAsset(PhysicalAsset asset) {
        validateProject(asset.getProjectId());

        String categoryCode = "DEV";
        asset.setAssetNo("PA-" + Year.now().getValue() + "-" + categoryCode + "-" + generateSeq());
        applyDerivedFields(asset);
        save(asset);
        return asset;
    }

    public void updateAsset(Long id, PhysicalAsset asset) {
        PhysicalAsset dbAsset = getById(id);
        if (dbAsset == null) {
            throw new BusinessException("资产不存在");
        }
        validateProject(asset.getProjectId());
        asset.setId(id);
        applyDerivedFields(asset);
        updateById(asset);
    }

    public void updateStatus(Long id, String newStatus, String reason, Long operatorId) {
        PhysicalAsset asset = getById(id);
        if (asset == null) {
            throw new BusinessException("资产不存在");
        }
        asset.setStatus(newStatus);
        updateById(asset);
    }

    private void applyDerivedFields(PhysicalAsset asset) {
        if (asset.getPurchaseDate() != null && asset.getWarrantyYears() != null) {
            asset.setWarrantyExpire(asset.getPurchaseDate().plusYears(asset.getWarrantyYears()));
        }
        if (!StringUtils.hasText(asset.getStatus())) {
            asset.setStatus("IDLE");
        }
    }

    private void validateProject(Long projectId) {
        if (projectId == null) {
            throw new BusinessException("资产必须归属项目");
        }
        Long count = projectMapper.selectCount(new LambdaQueryWrapper<Project>()
                .eq(Project::getId, projectId)
                .eq(Project::getDeleted, 0));
        if (count == null || count == 0) {
            throw new BusinessException("归属项目不存在");
        }
    }

    private String generateSeq() {
        return String.format("%05d", System.currentTimeMillis() % 100000);
    }
}
