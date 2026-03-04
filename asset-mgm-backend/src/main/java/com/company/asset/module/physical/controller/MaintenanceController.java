package com.company.asset.module.physical.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.physical.entity.MaintenanceOrder;
import com.company.asset.module.physical.mapper.MaintenanceOrderMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@Tag(name = "维修工单")
@RestController
@RequestMapping("/api/physical/maintenance")
@RequiredArgsConstructor
public class MaintenanceController {

    private final MaintenanceOrderMapper mapper;

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) Long assetId,
                          @RequestParam(required = false) String status) {
        Page<MaintenanceOrder> p = new Page<>(pageNum, pageSize);
        mapper.selectPage(p, new LambdaQueryWrapper<MaintenanceOrder>()
                .eq(assetId != null, MaintenanceOrder::getAssetId, assetId)
                .eq(StringUtils.hasText(status), MaintenanceOrder::getStatus, status)
                .orderByDesc(MaintenanceOrder::getCreatedAt));
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "新增工单")
    @PostMapping
    public Result<MaintenanceOrder> create(@RequestBody MaintenanceOrder order) {
        order.setOrderNo("MO-" + System.currentTimeMillis());
        order.setStatus("PENDING");
        order.setReportTime(LocalDateTime.now());
        mapper.insert(order);
        return Result.ok(order);
    }

    @Operation(summary = "更新工单")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody MaintenanceOrder order) {
        order.setId(id);
        mapper.updateById(order);
        return Result.ok();
    }

    @Operation(summary = "完成工单")
    @PutMapping("/{id}/complete")
    public Result<?> complete(@PathVariable Long id, @RequestBody MaintenanceOrder order) {
        order.setId(id);
        order.setStatus("COMPLETED");
        order.setFinishTime(LocalDateTime.now());
        mapper.updateById(order);
        return Result.ok();
    }

    @Operation(summary = "删除工单")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        mapper.deleteById(id);
        return Result.ok();
    }
}
