package com.company.asset.module.system.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.company.asset.common.result.Result;
import com.company.asset.module.auth.entity.SysRole;
import com.company.asset.module.auth.mapper.SysRoleMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "角色管理")
@RestController
@RequestMapping("/api/system/roles")
@RequiredArgsConstructor
public class RoleController {

    private final SysRoleMapper roleMapper;

    @Operation(summary = "查询所有角色")
    @GetMapping
    public Result<List<SysRole>> list() {
        return Result.ok(roleMapper.selectList(new LambdaQueryWrapper<SysRole>()
                .orderByAsc(SysRole::getId)));
    }

    @Operation(summary = "新增角色")
    @PostMapping
    public Result<SysRole> create(@RequestBody SysRole role) {
        roleMapper.insert(role);
        return Result.ok(role);
    }

    @Operation(summary = "更新角色")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody SysRole role) {
        role.setId(id);
        roleMapper.updateById(role);
        return Result.ok();
    }

    @Operation(summary = "删除角色")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        roleMapper.deleteById(id);
        return Result.ok();
    }
}
