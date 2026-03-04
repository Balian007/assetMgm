package com.company.asset.module.project.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.project.entity.Project;
import com.company.asset.module.project.mapper.ProjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

@Tag(name = "项目管理")
@RestController
@RequestMapping("/api/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectMapper projectMapper;

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) String projectName,
                          @RequestParam(required = false) String status) {
        Page<Project> p = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<Project> w = new LambdaQueryWrapper<Project>()
                .like(StringUtils.hasText(projectName), Project::getProjectName, projectName)
                .eq(StringUtils.hasText(status), Project::getStatus, status)
                .orderByDesc(Project::getCreatedAt);
        projectMapper.selectPage(p, w);
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "查询详情")
    @GetMapping("/{id}")
    public Result<Project> getById(@PathVariable Long id) {
        return Result.ok(projectMapper.selectById(id));
    }

    @Operation(summary = "新增项目")
    @PostMapping
    public Result<Project> create(@RequestBody Project project) {
        projectMapper.insert(project);
        return Result.ok(project);
    }

    @Operation(summary = "更新项目")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody Project project) {
        project.setId(id);
        projectMapper.updateById(project);
        return Result.ok();
    }

    @Operation(summary = "删除项目")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        projectMapper.deleteById(id);
        return Result.ok();
    }
}
