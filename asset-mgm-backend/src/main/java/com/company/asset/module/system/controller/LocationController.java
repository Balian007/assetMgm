package com.company.asset.module.system.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.system.entity.AssetLocation;
import com.company.asset.module.system.mapper.AssetLocationMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "位置管理")
@RestController
@RequestMapping("/api/system/locations")
@RequiredArgsConstructor
public class LocationController {

    private final AssetLocationMapper mapper;

    @Operation(summary = "查询所有位置（树形）")
    @GetMapping("/tree")
    public Result<List<AssetLocation>> tree() {
        List<AssetLocation> list = mapper.selectList(
                new LambdaQueryWrapper<AssetLocation>().orderByAsc(AssetLocation::getSortOrder));
        return Result.ok(buildTree(list));
    }

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize) {
        Page<AssetLocation> p = new Page<>(pageNum, pageSize);
        mapper.selectPage(p, new LambdaQueryWrapper<AssetLocation>()
                .orderByAsc(AssetLocation::getSortOrder));
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "新增位置")
    @PostMapping
    public Result<AssetLocation> create(@RequestBody AssetLocation location) {
        if (location.getParentId() == null) location.setParentId(0L);
        mapper.insert(location);
        return Result.ok(location);
    }

    @Operation(summary = "更新位置")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody AssetLocation location) {
        location.setId(id);
        mapper.updateById(location);
        return Result.ok();
    }

    @Operation(summary = "删除位置")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        mapper.deleteById(id);
        return Result.ok();
    }

    private List<AssetLocation> buildTree(List<AssetLocation> list) {
        Map<Long, AssetLocation> map = new HashMap<>();
        List<AssetLocation> roots = new ArrayList<>();
        for (AssetLocation location : list) {
            location.setChildren(new ArrayList<>());
            map.put(location.getId(), location);
        }
        for (AssetLocation location : list) {
            Long parentId = location.getParentId();
            if (parentId == null || parentId == 0L) {
                roots.add(location);
                continue;
            }
            AssetLocation parent = map.get(parentId);
            if (parent == null) {
                roots.add(location);
                continue;
            }
            parent.getChildren().add(location);
        }
        return roots;
    }
}
