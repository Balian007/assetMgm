package com.company.asset.module.digital.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.company.asset.common.exception.BusinessException;
import com.company.asset.module.digital.entity.DigitalAsset;
import com.company.asset.module.digital.mapper.DigitalAssetMapper;
import com.company.asset.module.project.entity.Project;
import com.company.asset.module.project.mapper.ProjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Year;

@Service
@RequiredArgsConstructor
public class DigitalAssetService extends ServiceImpl<DigitalAssetMapper, DigitalAsset> {

    private final ProjectMapper projectMapper;

    public Page<DigitalAsset> pageList(int pageNum, int pageSize,
                                       String assetName, Long categoryId,
                                       String dataLevel, Long projectId) {
        Page<DigitalAsset> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<DigitalAsset> wrapper = new LambdaQueryWrapper<DigitalAsset>()
                .like(StringUtils.hasText(assetName), DigitalAsset::getAssetName, assetName)
                .eq(categoryId != null, DigitalAsset::getCategoryId, categoryId)
                .eq(StringUtils.hasText(dataLevel), DigitalAsset::getDataLevel, dataLevel)
                .eq(projectId != null, DigitalAsset::getProjectId, projectId)
                .orderByDesc(DigitalAsset::getCreatedAt);
        return page(page, wrapper);
    }

    public DigitalAsset createAsset(DigitalAsset asset) {
        validateProject(asset.getProjectId());

        asset.setAssetNo("DA-" + Year.now().getValue() + "-" + generateCode(asset.getCategoryId()) + "-" + generateSeq());
        if (!StringUtils.hasText(asset.getStatus())) {
            asset.setStatus("ACTIVE");
        }
        if (!StringUtils.hasText(asset.getDataLevel())) {
            asset.setDataLevel("INTERNAL");
        }
        save(asset);
        return asset;
    }

    public void updateAsset(Long id, DigitalAsset asset) {
        DigitalAsset dbAsset = getById(id);
        if (dbAsset == null) {
            throw new BusinessException("资产不存在");
        }
        validateProject(asset.getProjectId());
        asset.setId(id);
        updateById(asset);
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

    private String generateCode(Long categoryId) {
        return categoryId != null ? String.format("C%d", categoryId) : "GEN";
    }

    private String generateSeq() {
        return String.format("%05d", System.currentTimeMillis() % 100000);
    }
}
