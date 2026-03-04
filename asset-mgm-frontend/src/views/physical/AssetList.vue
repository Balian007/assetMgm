<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">设备台账</h2>
      <div class="header-actions">
        <el-button :loading="exporting" @click="exportQrLabels">批量导出二维码</el-button>
        <el-button type="primary" @click="openForm()">
          <el-icon><Plus /></el-icon> 新增设备
        </el-button>
      </div>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form :model="query" inline>
        <el-form-item label="设备名称">
          <el-input v-model="query.assetName" placeholder="搜索设备名称" clearable style="width:180px" />
        </el-form-item>
        <el-form-item label="分类ID">
          <el-input v-model="query.categoryId" placeholder="分类ID" clearable style="width:120px" />
        </el-form-item>
        <el-form-item label="品牌">
          <el-input v-model="query.brand" placeholder="品牌" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="型号">
          <el-input v-model="query.model" placeholder="型号" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:120px">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="doSearch">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <el-table :data="tableData" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="assetNo" label="资产编号" width="190" />
        <el-table-column prop="assetName" label="设备名称" min-width="160" />
        <el-table-column prop="categoryName" label="分类" width="100" />
        <el-table-column prop="brand" label="品牌" width="110" />
        <el-table-column prop="model" label="型号" width="130" />
        <el-table-column prop="locationName" label="位置" width="120" />
        <el-table-column prop="projectName" label="归属项目" width="140" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="statusTagType(row.status)" size="small" effect="light">
              {{ statusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="warrantyExpire" label="保修到期" width="110" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="$router.push(`/physical/assets/${row.id}`)">详情</el-button>
            <el-button link type="primary" size="small" @click="openForm(row)">编辑</el-button>
            <el-popconfirm title="确认删除该设备？" @confirm="deleteRow(row.id)">
              <template #reference>
                <el-button link type="danger" size="small">删除</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-model:current-page="query.pageNum"
        v-model:page-size="query.pageSize"
        :total="total"
        layout="total, prev, pager, next"
        @change="loadData"
      />
    </el-card>

    <el-dialog v-model="dialogVisible" :title="editRow ? '编辑设备' : '新增设备'" width="620px" destroy-on-close>
      <el-form :model="formData" label-width="90px" ref="formRef">
        <el-row :gutter="16">
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="设备ID">
              <el-input v-model="formData.assetNo" readonly placeholder="选择项目后自动生成" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="分类ID" prop="categoryId" :rules="[{required:true,message:'必填'}]">
              <el-input-number v-model="formData.categoryId" :min="1" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="设备名称" prop="assetName" :rules="[{required:true,message:'必填'}]">
              <el-input v-model="formData.assetName" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="品牌">
              <el-input v-model="formData.brand" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="型号">
              <el-input v-model="formData.model" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="序列号">
              <el-input v-model="formData.serialNo" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="采购日期">
              <el-date-picker v-model="formData.purchaseDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="采购金额">
              <el-input-number v-model="formData.purchasePrice" :precision="2" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="供应商">
              <el-input v-model="formData.supplier" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="保修年限">
              <el-input-number v-model="formData.warrantyYears" :min="0" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="所属项目" prop="projectId" :rules="[{ required: true, message: '必须选择项目' }]">
              <el-select v-model="formData.projectId" placeholder="请选择" style="width:100%" @change="handleProjectChange">
                <el-option v-for="p in projects" :key="p.id" :label="p.projectName" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="存放位置">
              <el-tree-select
                v-model="formData.locationId"
                :data="locationTree"
                clearable
                :props="{ label: 'locName', value: 'id', children: 'children' }"
                placeholder="请选择"
                style="width:100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="formData.remark" type="textarea" :rows="2" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitForm" :loading="submitting">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import QRCode from 'qrcode'
import { physicalAssetApi } from '@/api/physical/index'
import { projectApi, locationApi } from '@/api/system/index'
import { buildAssetQrContent } from '@/utils/assetQr'

const loading = ref(false)
const submitting = ref(false)
const exporting = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const editRow = ref(null)
const formRef = ref()
const formData = ref({})
const projects = ref([])
const locationTree = ref([])

const query = reactive({
  pageNum: 1,
  pageSize: 20,
  assetName: '',
  categoryId: '',
  brand: '',
  model: '',
  status: ''
})

const statusOptions = [
  { value: 'IN_USE', label: '在用' },
  { value: 'IDLE', label: '闲置' },
  { value: 'MAINTENANCE', label: '维修中' },
  { value: 'SCRAPPED', label: '已报废' }
]

const statusMap = {
  IN_USE: { label: '在用', type: 'success' },
  IDLE: { label: '闲置', type: 'info' },
  MAINTENANCE: { label: '维修中', type: 'warning' },
  SCRAPPED: { label: '已报废', type: 'danger' }
}
const statusLabel = (s) => statusMap[s]?.label || s
const statusTagType = (s) => statusMap[s]?.type || ''

async function loadDropdowns() {
  const [projRes, locRes] = await Promise.all([
    projectApi.page({ pageNum: 1, pageSize: 500 }),
    locationApi.tree()
  ])
  projects.value = projRes.data?.records || []
  locationTree.value = locRes.data || []
}

function parseCategoryId() {
  const v = Number(query.categoryId)
  return Number.isFinite(v) && v > 0 ? v : null
}

function containsText(source, target) {
  const s = String(source || '').toLowerCase().trim()
  const t = String(target || '').toLowerCase().trim()
  if (!t) return true
  return s.includes(t)
}

function toCamelRow(row) {
  const result = {}
  for (const [key, value] of Object.entries(row || {})) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
    result[camelKey] = value
  }
  return result
}

async function fetchAllAssets(baseParams = {}) {
  const pageSize = 200
  let pageNum = 1
  let totalCount = 0
  const all = []

  do {
    const res = await physicalAssetApi.page({
      ...baseParams,
      pageNum,
      pageSize
    })
    const records = (res.data?.records || []).map(toCamelRow)
    totalCount = Number(res.data?.total || 0)
    all.push(...records)
    pageNum += 1
  } while (all.length < totalCount)

  return all
}

async function fetchFilteredAssets() {
  const baseParams = {
    assetName: query.assetName || undefined,
    status: query.status || undefined,
    categoryId: parseCategoryId() || undefined
  }

  const all = await fetchAllAssets(baseParams)
  return all.filter((row) => {
    return containsText(row.brand, query.brand) && containsText(row.model, query.model)
  })
}

async function loadData() {
  loading.value = true
  try {
    const filtered = await fetchFilteredAssets()
    total.value = filtered.length
    const start = (query.pageNum - 1) * query.pageSize
    const end = start + query.pageSize
    tableData.value = filtered.slice(start, end)
  } finally {
    loading.value = false
  }
}

function doSearch() {
  query.pageNum = 1
  loadData()
}

function resetQuery() {
  Object.assign(query, {
    pageNum: 1,
    pageSize: 20,
    assetName: '',
    categoryId: '',
    brand: '',
    model: '',
    status: ''
  })
  loadData()
}

function openForm(row = null) {
  editRow.value = row
  if (row) {
    formData.value = { ...row }
  } else {
    formData.value = { categoryId: null, projectId: null, assetNo: '' }
  }
  dialogVisible.value = true
}

function sanitizeProjectNo(projectNo) {
  const safe = String(projectNo || '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
  return safe.slice(0, 10) || 'PRJ'
}

function buildAutoAssetNo(projectId) {
  const project = projects.value.find((p) => Number(p.id) === Number(projectId))
  const projectNoPart = sanitizeProjectNo(project?.projectNo || project?.projectName)
  const stamp = Date.now().toString().slice(-8)
  const rand = Math.floor(Math.random() * 100).toString().padStart(2, '0')
  return `PA-${projectNoPart}-${stamp}${rand}`
}

function refreshAutoAssetNo(force = false) {
  if (editRow.value) return
  if (!formData.value.projectId) {
    if (force) formData.value.assetNo = ''
    return
  }
  if (force || !formData.value.assetNo) {
    formData.value.assetNo = buildAutoAssetNo(formData.value.projectId)
  }
}

function handleProjectChange() {
  refreshAutoAssetNo(true)
}

async function submitForm() {
  await formRef.value.validate()
  submitting.value = true
  try {
    if (editRow.value) {
      await physicalAssetApi.update(editRow.value.id, formData.value)
    } else {
      refreshAutoAssetNo(false)
      const createRes = await physicalAssetApi.create(formData.value)
      const createdAsset = toCamelRow(createRes.data || {})
      if (createdAsset.id) {
        const qrCode = buildAssetQrContent(createdAsset.id)
        const assetNo = formData.value.assetNo || createdAsset.assetNo
        const payload = {
          ...createdAsset,
          projectId: createdAsset.projectId ?? formData.value.projectId,
          assetNo,
          qrCode
        }
        await physicalAssetApi.update(createdAsset.id, payload)
      }
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

async function deleteRow(id) {
  await physicalAssetApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

async function exportQrLabels() {
  exporting.value = true
  try {
    const assets = await fetchFilteredAssets()
    if (!assets.length) {
      ElMessage.warning('当前筛选条件下无设备可导出')
      return
    }

    const labels = await Promise.all(
      assets.map(async (asset) => {
        const qrContent = buildAssetQrContent(asset.id) || asset.qrCode || ''
        const qrImage = await QRCode.toDataURL(qrContent, {
          width: 220,
          margin: 1,
          errorCorrectionLevel: 'M'
        })

        return {
          assetNo: asset.assetNo || '-',
          assetName: asset.assetName || '-',
          categoryName: asset.categoryName || '-',
          brand: asset.brand || '-',
          model: asset.model || '-',
          qrContent,
          qrImage
        }
      })
    )

    const html = buildPrintHtml(labels)
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    const ts = new Date().toISOString().slice(0, 19).replaceAll(':', '').replace('T', '-')
    a.href = url
    a.download = `assets-qr-labels-${ts}.html`
    a.click()
    URL.revokeObjectURL(url)

    ElMessage.success(`已导出 ${labels.length} 个设备二维码标签`)
  } catch {
    ElMessage.error('导出失败，请稍后重试')
  } finally {
    exporting.value = false
  }
}

function buildPrintHtml(labels) {
  const cards = labels
    .map((item) => {
      return `
        <div class="label-card">
          <div class="meta-row"><span class="meta-key">资产号</span><span class="meta-val">${escapeHtml(item.assetNo)}</span></div>
          <div class="meta-row"><span class="meta-key">名称</span><span class="meta-val">${escapeHtml(item.assetName)}</span></div>
          <div class="meta-row"><span class="meta-key">分类</span><span class="meta-val">${escapeHtml(item.categoryName)}</span></div>
          <div class="meta-row"><span class="meta-key">品牌/型号</span><span class="meta-val">${escapeHtml(item.brand)} / ${escapeHtml(item.model)}</span></div>
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
  .meta-key { min-width: 54px; color: #6b7280; }
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

onMounted(() => {
  loadData()
  loadDropdowns()
})
</script>

<style scoped>
.header-actions {
  display: flex;
  gap: 8px;
}

@media (max-width: 760px) {
  .header-actions {
    width: 100%;
    justify-content: flex-end;
    flex-wrap: wrap;
  }
}
</style>
