package com.company.asset.module.auth.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.company.asset.common.exception.BusinessException;
import com.company.asset.common.result.Result;
import com.company.asset.config.JwtUtil;
import com.company.asset.module.auth.dto.LoginRequest;
import com.company.asset.module.auth.entity.SysUser;
import com.company.asset.module.auth.mapper.SysUserMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "认证")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Operation(summary = "登录")
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@Valid @RequestBody LoginRequest req) {
        SysUser user = userMapper.selectOne(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, req.getUsername()));
        if (user == null || !passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            throw new BusinessException(401, "用户名或密码错误");
        }
        if (user.getStatus() == 0) {
            throw new BusinessException(403, "账号已禁用");
        }
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        return Result.ok(Map.of(
                "token", token,
                "userId", user.getId(),
                "username", user.getUsername(),
                "realName", user.getRealName() != null ? user.getRealName() : ""
        ));
    }
}
