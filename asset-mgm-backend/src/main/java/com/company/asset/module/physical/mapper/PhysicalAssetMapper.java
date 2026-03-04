package com.company.asset.module.physical.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.module.physical.entity.PhysicalAsset;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Map;

@Mapper
public interface PhysicalAssetMapper extends BaseMapper<PhysicalAsset> {
    IPage<Map<String, Object>> selectPageWithDetail(Page<?> page,
                                                     @Param("assetName") String assetName,
                                                     @Param("categoryId") Long categoryId,
                                                     @Param("status") String status,
                                                     @Param("projectId") Long projectId);

    Long selectPageWithDetailCount(@Param("assetName") String assetName,
                                   @Param("categoryId") Long categoryId,
                                   @Param("status") String status,
                                   @Param("projectId") Long projectId);
}
