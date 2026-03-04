package com.company.asset.module.digital.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.digital.entity.DigitalAsset;
import com.company.asset.module.digital.service.DigitalAssetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "数字资产")
@RestController
@RequestMapping("/api/digital/assets")
@RequiredArgsConstructor
public class DigitalAssetController {

    private final DigitalAssetService assetService;

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) String assetName,
                          @RequestParam(required = false) Long categoryId,
                          @RequestParam(required = false) String dataLevel,
                          @RequestParam(required = false) Long projectId) {
        Page<DigitalAsset> p = assetService.pageList(pageNum, pageSize, assetName, categoryId, dataLevel, projectId);
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "查询详情")
    @GetMapping("/{id}")
    public Result<DigitalAsset> getById(@PathVariable Long id) {
        return Result.ok(assetService.getById(id));
    }

    @Operation(summary = "新增数字资产")
    @PostMapping
    public Result<DigitalAsset> create(@RequestBody DigitalAsset asset) {
        return Result.ok(assetService.createAsset(asset));
    }

    @Operation(summary = "更新数字资产")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody DigitalAsset asset) {
        assetService.updateAsset(id, asset);
        return Result.ok();
    }

    @Operation(summary = "删除数字资产")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        assetService.removeById(id);
        return Result.ok();
    }
}
