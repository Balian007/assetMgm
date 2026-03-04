package com.company.asset.module.physical.controller;

import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.physical.entity.PhysicalAsset;
import com.company.asset.module.physical.service.PhysicalAssetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "实体资产")
@RestController
@RequestMapping("/api/physical/assets")
@RequiredArgsConstructor
public class PhysicalAssetController {

    private final PhysicalAssetService assetService;

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) String assetName,
                          @RequestParam(required = false) Long categoryId,
                          @RequestParam(required = false) String status,
                          @RequestParam(required = false) Long projectId) {
        var page = assetService.pageList(pageNum, pageSize, assetName, categoryId, status, projectId);
        return PageResult.page(page.getRecords(), page.getTotal());
    }

    @Operation(summary = "查询详情")
    @GetMapping("/{id}")
    public Result<PhysicalAsset> getById(@PathVariable Long id) {
        return Result.ok(assetService.getById(id));
    }

    @Operation(summary = "新增资产")
    @PostMapping
    public Result<PhysicalAsset> create(@RequestBody PhysicalAsset asset) {
        return Result.ok(assetService.createAsset(asset));
    }

    @Operation(summary = "更新资产")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody PhysicalAsset asset) {
        assetService.updateAsset(id, asset);
        return Result.ok();
    }

    @Operation(summary = "变更状态")
    @PutMapping("/{id}/status")
    public Result<?> updateStatus(@PathVariable Long id,
                                  @RequestParam String status,
                                  @RequestParam(required = false) String reason) {
        assetService.updateStatus(id, status, reason, null);
        return Result.ok();
    }

    @Operation(summary = "删除资产")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        assetService.removeById(id);
        return Result.ok();
    }
}
