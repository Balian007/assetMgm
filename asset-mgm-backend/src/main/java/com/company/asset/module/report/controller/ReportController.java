package com.company.asset.module.report.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.company.asset.common.result.Result;
import com.company.asset.module.digital.entity.DigitalAsset;
import com.company.asset.module.digital.mapper.DigitalAssetMapper;
import com.company.asset.module.physical.entity.InspectionTask;
import com.company.asset.module.physical.entity.MaintenanceOrder;
import com.company.asset.module.physical.entity.PhysicalAsset;
import com.company.asset.module.physical.mapper.InspectionTaskMapper;
import com.company.asset.module.physical.mapper.MaintenanceOrderMapper;
import com.company.asset.module.physical.mapper.PhysicalAssetMapper;
import com.company.asset.module.project.entity.Project;
import com.company.asset.module.project.mapper.ProjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Tag(name = "统计报表")
@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {

    private final PhysicalAssetMapper physicalAssetMapper;
    private final DigitalAssetMapper digitalAssetMapper;
    private final ProjectMapper projectMapper;
    private final InspectionTaskMapper inspectionTaskMapper;
    private final MaintenanceOrderMapper maintenanceOrderMapper;

    @Operation(summary = "首页统计数据")
    @GetMapping("/dashboard")
    public Result<Map<String, Object>> dashboard() {
        Map<String, Object> data = new HashMap<>();

        // 实物资产统计
        long physicalTotal = physicalAssetMapper.selectCount(
                new LambdaQueryWrapper<PhysicalAsset>().eq(PhysicalAsset::getDeleted, 0));
        data.put("physicalTotal", physicalTotal);

        // 按状态分组统计
        List<PhysicalAsset> assets = physicalAssetMapper.selectList(
                new LambdaQueryWrapper<PhysicalAsset>().eq(PhysicalAsset::getDeleted, 0)
                        .select(PhysicalAsset::getStatus));
        Map<String, Long> statusCount = assets.stream()
                .collect(Collectors.groupingBy(a -> a.getStatus() != null ? a.getStatus() : "UNKNOWN",
                        Collectors.counting()));
        data.put("physicalByStatus", statusCount);

        // 数字资产统计
        long digitalTotal = digitalAssetMapper.selectCount(
                new LambdaQueryWrapper<DigitalAsset>().eq(DigitalAsset::getDeleted, 0));
        data.put("digitalTotal", digitalTotal);

        // 进行中项目
        long activeProjects = projectMapper.selectCount(
                new LambdaQueryWrapper<Project>()
                        .eq(Project::getStatus, "ACTIVE")
                        .eq(Project::getDeleted, 0));
        data.put("activeProjects", activeProjects);

        // 待处理巡检任务
        long pendingInspections = inspectionTaskMapper.selectCount(
                new LambdaQueryWrapper<InspectionTask>().eq(InspectionTask::getStatus, "PENDING"));
        data.put("pendingInspections", pendingInspections);

        // 待处理维修工单
        long pendingMaintenance = maintenanceOrderMapper.selectCount(
                new LambdaQueryWrapper<MaintenanceOrder>().eq(MaintenanceOrder::getStatus, "PENDING"));
        data.put("pendingMaintenance", pendingMaintenance);

        // 保修即将到期（30天内）
        java.time.LocalDate soon = java.time.LocalDate.now().plusDays(30);
        long warrantyExpiringSoon = physicalAssetMapper.selectCount(
                new LambdaQueryWrapper<PhysicalAsset>()
                        .eq(PhysicalAsset::getDeleted, 0)
                        .le(PhysicalAsset::getWarrantyExpire, soon)
                        .ge(PhysicalAsset::getWarrantyExpire, java.time.LocalDate.now()));
        data.put("warrantyExpiringSoon", warrantyExpiringSoon);

        return Result.ok(data);
    }

    @Operation(summary = "实物资产分类统计")
    @GetMapping("/physical/by-category")
    public Result<List<Map<String, Object>>> physicalByCategory() {
        // 用原生查询统计各分类数量
        List<Map<String, Object>> result = physicalAssetMapper.selectMaps(
                new LambdaQueryWrapper<PhysicalAsset>()
                        .eq(PhysicalAsset::getDeleted, 0)
                        .select(PhysicalAsset::getCategoryId, PhysicalAsset::getStatus)
                        .groupBy(PhysicalAsset::getCategoryId));
        return Result.ok(result);
    }
}
