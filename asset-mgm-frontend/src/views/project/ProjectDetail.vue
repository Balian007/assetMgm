<template>
  <div>
    <el-page-header @back="$router.back()" :content="project.projectName || '项目详情'" class="mb-4" />

    <el-row :gutter="16" v-loading="loadingProject || loadingAssets || exporting">
      <el-col :xl="10" :lg="10" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" header="项目信息" class="mb-4">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="项目编号">{{ project.projectNo || '-' }}</el-descriptions-item>
            <el-descriptions-item label="项目名称">{{ project.projectName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="项目状态">
              <el-tag size="small" :type="statusType(project.status)">{{ statusLabel(project.status) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="项目地点">{{ project.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="开始日期">{{ project.startDate || '-' }}</el-descriptions-item>
            <el-descriptions-item label="结束日期">{{ project.endDate || '-' }}</el-descriptions-item>
            <el-descriptions-item label="项目描述">{{ project.description || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>

      <el-col :xl="14" :lg="14" :md="24" :sm="24" :xs="24">
        <el-card shadow="never">
          <template #header>
            <div class="card-header">
              <span>所属设备资产</span>
              <el-button type="primary" size="small" :loading="exporting" @click="exportLabels">
                批量导出二维码标签
              </el-button>
            </div>
          </template>
          <el-table :data="assets" border stripe>
            <el-table-column prop="assetNo" label="资产编号" min-width="150" />
            <el-table-column prop="assetName" label="设备名称" min-width="150" />
            <el-table-column prop="categoryName" label="分类" width="90" />
            <el-table-column prop="locationName" label="位置" width="120" />
            <el-table-column prop="status" label="状态" width="90">
              <template #default="{ row }">
                <el-tag size="small" :type="assetStatusType(row.status)">
                  {{ assetStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" size="small" @click="$router.push(`/physical/assets/${row.id}`)">
                  详情
                </el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination
            v-model:current-page="assetQuery.pageNum"
            v-model:page-size="assetQuery.pageSize"
            :total="assetTotal"
            layout="total, prev, pager, next"
            style="margin-top:16px; justify-content:flex-end"
            @change="loadAssets"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import QRCode from 'qrcode'
import { projectApi } from '@/api/system'
import { physicalAssetApi } from '@/api/physical'
import { buildAssetQrContent } from '@/utils/assetQr'

const route = useRoute()
const projectId = Number(route.params.id)

const loadingProject = ref(false)
const loadingAssets = ref(false)
const exporting = ref(false)

const project = ref({})
const assets = ref([])
const assetTotal = ref(0)
const assetQuery = reactive({
  pageNum: 1,
  pageSize: 10
})

const projectStatusMap = {
  PLANNING: { label: '规划中', type: 'info' },
  ACTIVE: { label: '进行中', type: 'success' },
  COMPLETED: { label: '已完成', type: '' },
  ARCHIVED: { label: '已归档', type: 'warning' }
}
const statusLabel = (status) => projectStatusMap[status]?.label || status || '-'
const statusType = (status) => projectStatusMap[status]?.type || ''

const assetStatusMap = {
  IN_USE: { label: '在用', type: 'success' },
  IDLE: { label: '闲置', type: 'info' },
  MAINTENANCE: { label: '维修中', type: 'warning' },
  SCRAPPED: { label: '已报废', type: 'danger' },
  TRANSFERRED: { label: '已调拨', type: '' }
}
const assetStatusLabel = (status) => assetStatusMap[status]?.label || status || '-'
const assetStatusType = (status) => assetStatusMap[status]?.type || ''

function toCamelRow(row) {
  const result = {}
  for (const [key, value] of Object.entries(row || {})) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
    result[camelKey] = value
  }
  return result
}

async function loadProject() {
  loadingProject.value = true
  try {
    const res = await projectApi.getById(projectId)
    project.value = res.data || {}
  } finally {
    loadingProject.value = false
  }
}

async function loadAssets() {
  loadingAssets.value = true
  try {
    const res = await physicalAssetApi.page({
      pageNum: assetQuery.pageNum,
      pageSize: assetQuery.pageSize,
      projectId
    })
    const records = res.data?.records || []
    assets.value = records.map(toCamelRow)
    assetTotal.value = res.data?.total || 0
  } finally {
    loadingAssets.value = false
  }
}

async function fetchAllProjectAssets() {
  const pageSize = 200
  let pageNum = 1
  let total = 0
  const all = []

  do {
    const res = await physicalAssetApi.page({ pageNum, pageSize, projectId })
    const chunk = (res.data?.records || []).map(toCamelRow)
    total = Number(res.data?.total || 0)
    all.push(...chunk)
    pageNum += 1
  } while (all.length < total)

  return all
}

async function exportLabels() {
  exporting.value = true
  try {
    const allAssets = await fetchAllProjectAssets()
    if (!allAssets.length) {
      ElMessage.warning('该项目下暂无设备资产可导出')
      return
    }

    const labels = await Promise.all(
      allAssets.map(async (asset) => {
        const qrContent = buildAssetQrContent(asset.id) || asset.qrCode || ''
        const qrImage = await QRCode.toDataURL(qrContent, {
          width: 220,
          margin: 1,
          errorCorrectionLevel: 'M'
        })

        return {
          assetNo: asset.assetNo || '-',
          assetName: asset.assetName || '-',
          projectName: project.value.projectName || '-',
          qrContent,
          qrImage
        }
      })
    )

    const html = buildPrintHtml(labels)
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    const filePart = project.value.projectNo || `project-${projectId}`
    a.href = url
    a.download = `${filePart}-device-qr-labels.html`
    a.click()
    URL.revokeObjectURL(url)

    ElMessage.success(`已导出 ${labels.length} 个设备二维码标签`) 
  } catch {
    ElMessage.error('导出二维码标签失败')
  } finally {
    exporting.value = false
  }
}

function buildPrintHtml(labels) {
  const cards = labels
    .map((item) => {
      return `
        <div class="label-card">
          <div class="meta-row"><span class="meta-key">项目</span><span class="meta-val">${escapeHtml(item.projectName)}</span></div>
          <div class="meta-row"><span class="meta-key">资产号</span><span class="meta-val">${escapeHtml(item.assetNo)}</span></div>
          <div class="meta-row"><span class="meta-key">设备</span><span class="meta-val">${escapeHtml(item.assetName)}</span></div>
          <img class="qr-img" src="${item.qrImage}" alt="${escapeHtml(item.assetNo)}" />
          <div class="qr-text">${escapeHtml(item.qrContent)}</div>
        </div>
      `
    })
    .join('')

  return `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>设备二维码标签</title>
<style>
  body { margin: 12px; font-family: "Microsoft YaHei", sans-serif; color: #111827; }
  .toolbar { margin-bottom: 12px; }
  .tips { margin: 0; font-size: 12px; color: #6b7280; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 10px; }
  .label-card { border: 1px solid #d1d5db; border-radius: 8px; padding: 8px; break-inside: avoid; }
  .meta-row { display: flex; gap: 6px; font-size: 12px; line-height: 1.5; }
  .meta-key { min-width: 40px; color: #6b7280; }
  .meta-val { flex: 1; font-weight: 600; word-break: break-all; }
  .qr-img { width: 160px; height: 160px; display: block; margin: 8px auto 4px; }
  .qr-text { text-align: center; font-size: 11px; color: #4b5563; word-break: break-all; }
  @media print {
    .toolbar { display: none; }
    body { margin: 0; }
    .grid { gap: 6px; }
    .label-card { border-color: #9ca3af; }
  }
</style>
</head>
<body>
  <div class="toolbar">
    <p class="tips">导出后可直接浏览器打印（建议 A4，边距窄，100% 缩放）。</p>
  </div>
  <div class="grid">${cards}</div>
</body>
</html>`
}

function escapeHtml(input) {
  return String(input || '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

onMounted(async () => {
  await Promise.all([loadProject(), loadAssets()])
})
</script>

<style scoped>
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

@media (max-width: 760px) {
  :deep(.el-page-header__content) {
    font-size: 14px;
  }

  :deep(.el-descriptions__label),
  :deep(.el-descriptions__content) {
    font-size: 12px;
  }

  .card-header {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>

