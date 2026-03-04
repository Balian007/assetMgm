package com.company.asset.module.physical.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.physical.entity.InspectionRecord;
import com.company.asset.module.physical.entity.InspectionTask;
import com.company.asset.module.physical.service.InspectionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "巡检管理")
@RestController
@RequestMapping("/api/physical/inspections")
@RequiredArgsConstructor
public class InspectionController {

    private final InspectionService inspectionService;

    @Operation(summary = "分页查询巡检任务")
    @GetMapping("/tasks")
    public Result<?> pageTasks(@RequestParam(defaultValue = "1") int pageNum,
                                @RequestParam(defaultValue = "20") int pageSize,
                                @RequestParam(required = false) String status,
                                @RequestParam(required = false) Long projectId) {
        Page<InspectionTask> p = new Page<>(pageNum, pageSize);
        inspectionService.page(p, new LambdaQueryWrapper<InspectionTask>()
                .eq(StringUtils.hasText(status), InspectionTask::getStatus, status)
                .eq(projectId != null, InspectionTask::getProjectId, projectId)
                .orderByDesc(InspectionTask::getCreatedAt));
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "创建巡检任务")
    @PostMapping("/tasks")
    public Result<InspectionTask> createTask(@RequestBody InspectionTask task) {
        task.setTaskNo("IT-" + System.currentTimeMillis());
        task.setStatus("PENDING");
        inspectionService.save(task);
        return Result.ok(task);
    }

    @Operation(summary = "更新巡检任务")
    @PutMapping("/tasks/{id}")
    public Result<?> updateTask(@PathVariable Long id, @RequestBody InspectionTask task) {
        task.setId(id);
        inspectionService.updateById(task);
        return Result.ok();
    }

    @Operation(summary = "删除巡检任务")
    @DeleteMapping("/tasks/{id}")
    public Result<?> deleteTask(@PathVariable Long id) {
        inspectionService.removeById(id);
        return Result.ok();
    }

    @Operation(summary = "巡检打卡")
    @PostMapping("/checkin")
    public Result<InspectionRecord> checkIn(@RequestBody InspectionRecord record) {
        return Result.ok(inspectionService.checkIn(record));
    }

    @Operation(summary = "查询设备巡检记录")
    @GetMapping("/records/asset/{assetId}")
    public Result<List<InspectionRecord>> getByAsset(@PathVariable Long assetId) {
        return Result.ok(inspectionService.getRecordsByAsset(assetId));
    }

    @Operation(summary = "查询任务巡检记录")
    @GetMapping("/records/task/{taskId}")
    public Result<List<InspectionRecord>> getByTask(@PathVariable Long taskId) {
        return Result.ok(inspectionService.getRecordsByTask(taskId));
    }
}
