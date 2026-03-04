package com.company.asset.module.physical.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.physical.entity.InventoryDetail;
import com.company.asset.module.physical.entity.InventoryTask;
import com.company.asset.module.physical.mapper.InventoryDetailMapper;
import com.company.asset.module.physical.mapper.InventoryTaskMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "资产盘点")
@RestController
@RequestMapping("/api/physical/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryTaskMapper taskMapper;
    private final InventoryDetailMapper detailMapper;

    @Operation(summary = "分页查询盘点任务")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) String status) {
        Page<InventoryTask> p = new Page<>(pageNum, pageSize);
        taskMapper.selectPage(p, new LambdaQueryWrapper<InventoryTask>()
                .eq(StringUtils.hasText(status), InventoryTask::getStatus, status)
                .orderByDesc(InventoryTask::getCreatedAt));
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "创建盘点任务")
    @PostMapping
    public Result<InventoryTask> create(@RequestBody InventoryTask task) {
        task.setTaskNo("INV-" + System.currentTimeMillis());
        task.setStatus("DRAFT");
        taskMapper.insert(task);
        return Result.ok(task);
    }

    @Operation(summary = "更新盘点任务")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody InventoryTask task) {
        task.setId(id);
        taskMapper.updateById(task);
        return Result.ok();
    }

    @Operation(summary = "查询盘点明细")
    @GetMapping("/{taskId}/details")
    public Result<List<InventoryDetail>> details(@PathVariable Long taskId) {
        return Result.ok(detailMapper.selectList(
                new LambdaQueryWrapper<InventoryDetail>()
                        .eq(InventoryDetail::getTaskId, taskId)));
    }

    @Operation(summary = "提交盘点明细")
    @PostMapping("/{taskId}/details")
    public Result<?> submitDetail(@PathVariable Long taskId, @RequestBody InventoryDetail detail) {
        detail.setTaskId(taskId);
        detailMapper.insert(detail);
        return Result.ok();
    }

    @Operation(summary = "删除盘点任务")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        taskMapper.deleteById(id);
        return Result.ok();
    }
}
