<template>
  <div>
    <el-page-header @back="$router.back()" :content="asset.assetName || '资产详情'" class="mb-4" />

    <el-row :gutter="16" v-loading="loading">
      <el-col :xl="16" :lg="16" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" header="基本信息" class="mb-4">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="资产编号">{{ asset.assetNo || '-' }}</el-descriptions-item>
            <el-descriptions-item label="资产名称">{{ asset.assetName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="所属项目">{{ projectInfo.projectName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="项目编号">{{ projectInfo.projectNo || '-' }}</el-descriptions-item>
            <el-descriptions-item label="品牌">{{ asset.brand || '-' }}</el-descriptions-item>
            <el-descriptions-item label="型号">{{ asset.model || '-' }}</el-descriptions-item>
            <el-descriptions-item label="序列号">{{ asset.serialNo || '-' }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="statusType(asset.status)" size="small">{{ statusLabel(asset.status) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="采购日期">{{ asset.purchaseDate || '-' }}</el-descriptions-item>
            <el-descriptions-item label="采购价格">{{ asset.purchasePrice != null ? '¥' + asset.purchasePrice : '-' }}</el-descriptions-item>
            <el-descriptions-item label="保修到期">{{ asset.warrantyExpire || '-' }}</el-descriptions-item>
            <el-descriptions-item label="IP地址">{{ asset.ipAddress || '-' }}</el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">{{ asset.remark || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>

        <el-card shadow="never" header="巡检记录">
          <el-table :data="inspections" border size="small" max-height="300">
            <el-table-column prop="checkTime" label="打卡时间" width="160" />
            <el-table-column label="结果" width="90">
              <template #default="{ row }">
                <el-tag :type="row.result === 'NORMAL' ? 'success' : 'danger'" size="small">
                  {{ { NORMAL: '正常', ABNORMAL: '异常', NEED_REPAIR: '需维修' }[row.result] || row.result }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="locationDesc" label="位置" show-overflow-tooltip />
            <el-table-column prop="description" label="备注" show-overflow-tooltip />
          </el-table>
        </el-card>
      </el-col>

      <el-col :xl="8" :lg="8" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" header="设备二维码" class="mb-4">
          <div v-if="qrImage" class="qr-section">
            <img :src="qrImage" alt="asset-qr" class="qr-image" />
            <div class="qr-text">{{ qrContent }}</div>
            <el-button type="primary" size="small" @click="downloadQr">导出二维码</el-button>
          </div>
          <el-empty v-else description="暂无二维码" :image-size="80" />
        </el-card>

        <el-card shadow="never" header="状态变更" class="mb-4">
          <el-form label-width="80px">
            <el-form-item label="新状态">
              <el-select v-model="statusForm.status" style="width:100%">
                <el-option label="使用中" value="IN_USE" />
                <el-option label="闲置" value="IDLE" />
                <el-option label="维修中" value="MAINTENANCE" />
                <el-option label="已报废" value="SCRAPPED" />
                <el-option label="已调拨" value="TRANSFERRED" />
              </el-select>
            </el-form-item>
            <el-form-item label="原因">
              <el-input v-model="statusForm.reason" type="textarea" :rows="2" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="updateStatus">更新状态</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never" header="折旧信息">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="使用年限">{{ asset.usefulLife ? asset.usefulLife + ' 年' : '-' }}</el-descriptions-item>
            <el-descriptions-item label="残值率">{{ asset.residualRate != null ? (asset.residualRate * 100).toFixed(0) + '%' : '-' }}</el-descriptions-item>
            <el-descriptions-item label="当前净值">
              <span class="font-bold text-primary">{{ currentValue }}</span>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import QRCode from 'qrcode'
import { physicalAssetApi, inspectionApi } from '@/api/physical'
import { projectApi } from '@/api/system'
import { buildAssetQrContent } from '@/utils/assetQr'

const route = useRoute()
const loading = ref(false)
const asset = ref({})
const inspections = ref([])
const projectInfo = ref({})
const qrContent = ref('')
const qrImage = ref('')
const statusForm = reactive({ status: '', reason: '' })

const statusLabel = (s) => ({
  IN_USE: '使用中',
  IDLE: '闲置',
  MAINTENANCE: '维修中',
  SCRAPPED: '已报废',
  TRANSFERRED: '已调拨'
}[s] || s)

const statusType = (s) => ({
  IN_USE: 'success',
  IDLE: 'info',
  MAINTENANCE: 'warning',
  SCRAPPED: 'danger',
  TRANSFERRED: ''
}[s] || '')

const currentValue = computed(() => {
  const a = asset.value
  if (!a.purchasePrice || !a.purchaseDate || !a.usefulLife) return '-'
  const years = (Date.now() - new Date(a.purchaseDate).getTime()) / (1000 * 60 * 60 * 24 * 365)
  const residual = a.residualRate ?? 0.05
  const annual = (a.purchasePrice * (1 - residual)) / a.usefulLife
  const val = Math.max(a.purchasePrice * residual, a.purchasePrice - annual * years)
  return '¥' + val.toFixed(2)
})

async function buildQrImage() {
  const content = asset.value.qrCode || buildAssetQrContent(asset.value.id)
  qrContent.value = content || ''
  if (!content) {
    qrImage.value = ''
    return
  }
  try {
    qrImage.value = await QRCode.toDataURL(content, {
      width: 240,
      margin: 1,
      errorCorrectionLevel: 'M'
    })
  } catch {
    qrImage.value = ''
  }
}

async function loadData() {
  loading.value = true
  try {
    const [assetRes, inspRes] = await Promise.all([
      physicalAssetApi.getById(route.params.id),
      inspectionApi.getByAsset(route.params.id)
    ])

    asset.value = assetRes.data || {}
    inspections.value = inspRes.data || []
    statusForm.status = asset.value.status || ''
    statusForm.reason = ''
    await buildQrImage()

    if (asset.value.projectId) {
      try {
        const projectRes = await projectApi.getById(asset.value.projectId)
        projectInfo.value = projectRes.data || {}
      } catch {
        projectInfo.value = {}
      }
    } else {
      projectInfo.value = {}
    }
  } finally {
    loading.value = false
  }
}

function downloadQr() {
  if (!qrImage.value) {
    ElMessage.warning('暂无可导出的二维码')
    return
  }
  const a = document.createElement('a')
  const suffix = asset.value.assetNo || `asset-${asset.value.id || 'unknown'}`
  a.href = qrImage.value
  a.download = `${suffix}-qrcode.png`
  a.click()
}

async function updateStatus() {
  await physicalAssetApi.updateStatus(route.params.id, statusForm.status, statusForm.reason)
  ElMessage.success('状态已更新')
  await loadData()
}

onMounted(loadData)
</script>

<style scoped>
.qr-section {
  display: grid;
  justify-items: center;
  gap: 10px;
}

.qr-image {
  width: 220px;
  height: 220px;
  border: 1px solid var(--el-border-color-light);
  border-radius: 8px;
  background: #fff;
  padding: 6px;
}

.qr-text {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  word-break: break-all;
  text-align: center;
}

@media (max-width: 760px) {
  :deep(.el-page-header__content) {
    font-size: 14px;
  }

  :deep(.el-descriptions__label),
  :deep(.el-descriptions__content) {
    font-size: 12px;
  }
}
</style>
