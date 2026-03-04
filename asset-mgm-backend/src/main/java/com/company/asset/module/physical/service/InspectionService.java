package com.company.asset.module.physical.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.company.asset.common.exception.BusinessException;
import com.company.asset.module.auth.entity.SysUser;
import com.company.asset.module.auth.mapper.SysUserMapper;
import com.company.asset.module.physical.entity.InspectionRecord;
import com.company.asset.module.physical.entity.InspectionTask;
import com.company.asset.module.physical.mapper.InspectionRecordMapper;
import com.company.asset.module.physical.mapper.InspectionTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InspectionService extends ServiceImpl<InspectionTaskMapper, InspectionTask> {

    private final InspectionRecordMapper recordMapper;
    private final SysUserMapper userMapper;

    public InspectionRecord checkIn(InspectionRecord record) {
        if (record.getInspectorId() == null) {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication != null ? authentication.getName() : null;
            if (StringUtils.hasText(username)) {
                SysUser user = userMapper.selectOne(new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, username)
                        .select(SysUser::getId));
                if (user != null) {
                    record.setInspectorId(user.getId());
                }
            }
        }
        if (record.getInspectorId() == null) {
            throw new BusinessException("缺少巡检人信息");
        }
        record.setCheckTime(LocalDateTime.now());
        recordMapper.insert(record);
        // 更新任务状态为进行中
        if (record.getTaskId() != null) {
            InspectionTask task = getById(record.getTaskId());
            if (task != null && "PENDING".equals(task.getStatus())) {
                task.setStatus("IN_PROGRESS");
                updateById(task);
            }
        }
        return record;
    }

    public List<InspectionRecord> getRecordsByAsset(Long assetId) {
        return recordMapper.selectList(
                new LambdaQueryWrapper<InspectionRecord>()
                        .eq(InspectionRecord::getAssetId, assetId)
                        .orderByDesc(InspectionRecord::getCheckTime));
    }

    public List<InspectionRecord> getRecordsByTask(Long taskId) {
        return recordMapper.selectList(
                new LambdaQueryWrapper<InspectionRecord>()
                        .eq(InspectionRecord::getTaskId, taskId)
                        .orderByDesc(InspectionRecord::getCheckTime));
    }
}
