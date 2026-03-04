package com.company.asset.module.system.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.exception.BusinessException;
import com.company.asset.common.result.PageResult;
import com.company.asset.common.result.Result;
import com.company.asset.module.auth.entity.SysUser;
import com.company.asset.module.auth.mapper.SysUserMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "用户管理")
@RestController
@RequestMapping("/api/system/users")
@RequiredArgsConstructor
public class UserController {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Operation(summary = "分页查询")
    @GetMapping
    public Result<?> page(@RequestParam(defaultValue = "1") int pageNum,
                          @RequestParam(defaultValue = "20") int pageSize,
                          @RequestParam(required = false) String username,
                          @RequestParam(required = false) String realName,
                          @RequestParam(required = false) Integer status) {
        Page<SysUser> p = new Page<>(pageNum, pageSize);
        userMapper.selectPage(p, new LambdaQueryWrapper<SysUser>()
                .like(StringUtils.hasText(username), SysUser::getUsername, username)
                .like(StringUtils.hasText(realName), SysUser::getRealName, realName)
                .eq(status != null, SysUser::getStatus, status)
                .orderByDesc(SysUser::getCreatedAt));
        // 清除密码字段
        p.getRecords().forEach(u -> u.setPassword(null));
        return PageResult.page(p.getRecords(), p.getTotal());
    }

    @Operation(summary = "查询所有用户（下拉用）")
    @GetMapping("/all")
    public Result<List<SysUser>> all() {
        List<SysUser> list = userMapper.selectList(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getStatus, 1));
        list.forEach(u -> u.setPassword(null));
        return Result.ok(list);
    }

    @Operation(summary = "新增用户")
    @PostMapping
    public Result<SysUser> create(@RequestBody SysUser user) {
        if (!StringUtils.hasText(user.getPassword())) {
            throw new BusinessException("密码不能为空");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setStatus(1);
        userMapper.insert(user);
        user.setPassword(null);
        return Result.ok(user);
    }

    @Operation(summary = "更新用户")
    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id, @RequestBody SysUser user) {
        user.setId(id);
        if (StringUtils.hasText(user.getPassword())) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        } else {
            user.setPassword(null);
        }
        userMapper.updateById(user);
        return Result.ok();
    }

    @Operation(summary = "启用/禁用用户")
    @PutMapping("/{id}/status")
    public Result<?> toggleStatus(@PathVariable Long id, @RequestParam Integer status) {
        SysUser user = new SysUser();
        user.setId(id);
        user.setStatus(status);
        userMapper.updateById(user);
        return Result.ok();
    }

    @Operation(summary = "删除用户")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        userMapper.deleteById(id);
        return Result.ok();
    }
}
