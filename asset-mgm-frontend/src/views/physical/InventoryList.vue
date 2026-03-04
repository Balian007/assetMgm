<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">资产盘点</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建盘点</el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form inline>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px">
            <el-option label="草稿" value="DRAFT" />
            <el-option label="进行中" value="IN_PROGRESS" />
            <el-option label="已完成" value="COMPLETED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="query.status = ''; loadData()">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="taskNo" label="任务编号" width="160" />
        <el-table-column prop="taskName" label="任务名称" />
        <el-table-column prop="planDate" label="计划日期" width="120" />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewDetails(row)">盘点明细</el-button>
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="mt-4" background layout="total, prev, pager, next"
        :total="total" :page-size="query.pageSize" v-model:current-page="query.pageNum"
        @current-change="loadData" />
    </el-card>

    <el-dialog v-model="dialog" :title="form.id ? '编辑盘点任务' : '新建盘点任务'" width="500px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" />
        </el-form-item>
        <el-form-item label="计划日期" prop="planDate">
          <el-date-picker v-model="form.planDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">取消</el-button>
        <el-button type="primary" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="detailDialog" title="盘点明细" width="800px">
      <div class="mb-3">
        <el-button type="primary" size="small" @click="openSubmitDetail">录入明细</el-button>
      </div>
      <el-table :data="details" border size="small">
        <el-table-column prop="assetId" label="资产ID" width="90" />
        <el-table-column prop="expectedLocationId" label="预期位置ID" />
        <el-table-column prop="actualLocationId" label="实际位置ID" />
        <el-table-column label="盘点结果" width="110">
          <template #default="{ row }">
            <el-tag :type="detailResultType(row.result)" size="small">{{ detailResultLabel(row.result) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" show-overflow-tooltip />
      </el-table>
    </el-dialog>

    <el-dialog v-model="submitDetailDialog" title="录入盘点明细" width="540px">
      <el-form :model="detailForm" label-width="100px">
        <el-form-item label="设备二维码">
          <el-input v-model="detailForm.qrContent" placeholder="手动输入或点击扫码" clearable>
            <template #append>
              <el-button @click="resolveDetailAssetByQr">识别</el-button>
            </template>
          </el-input>
          <div class="action-row">
            <el-button type="primary" link @click="scannerVisible = true">手机摄像头扫码</el-button>
          </div>
        </el-form-item>
        <el-form-item label="识别设备" v-if="selectedAsset">
          <el-alert
            :title="`${selectedAsset.assetName || '-'}（${selectedAsset.assetNo || '无编号'}）`"
            :description="`资产ID: ${selectedAsset.id}`"
            type="success"
            :closable="false"
            show-icon
          />
        </el-form-item>
        <el-form-item label="资产ID">
          <el-input-number v-model="detailForm.assetId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="实际位置ID">
          <el-input-number v-model="detailForm.actualLocationId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="盘点结果">
          <el-select v-model="detailForm.result" style="width:100%">
            <el-option label="正常" value="NORMAL" />
            <el-option label="盘盈" value="SURPLUS" />
            <el-option label="盘亏" value="DEFICIT" />
            <el-option label="位置不符" value="LOCATION_DIFF" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="detailForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="submitDetailDialog = false">取消</el-button>
        <el-button type="primary" @click="submitDetail">提交</el-button>
      </template>
    </el-dialog>

    <QrScannerDialog v-model="scannerVisible" @scanned="handleQrScanned" />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { inventoryApi, physicalAssetApi } from '@/api/physical'
import { extractAssetNoFromQr, normalizeQrText, parseAssetIdFromQr } from '@/utils/assetQr'
import QrScannerDialog from '@/components/QrScannerDialog.vue'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const query = reactive({ pageNum: 1, pageSize: 20, status: '' })
const dialog = ref(false)
const detailDialog = ref(false)
const submitDetailDialog = ref(false)
const scannerVisible = ref(false)
const formRef = ref()
const form = reactive({ id: null, taskName: '', planDate: '' })
const details = ref([])
const currentTaskId = ref(null)
const selectedAsset = ref(null)
const detailForm = reactive({ assetId: null, qrContent: '', actualLocationId: null, result: 'NORMAL', remark: '' })

const rules = {
  taskName: [{ required: true, message: '请输入任务名称' }],
  planDate: [{ required: true, message: '请选择计划日期' }]
}
const statusLabel = s => ({ DRAFT: '草稿', IN_PROGRESS: '进行中', COMPLETED: '已完成' }[s] || s)
const statusType = s => ({ DRAFT: 'info', IN_PROGRESS: 'primary', COMPLETED: 'success' }[s] || '')
const detailResultLabel = r => ({ NORMAL: '正常', SURPLUS: '盘盈', DEFICIT: '盘亏', LOCATION_DIFF: '位置不符' }[r] || r)
const detailResultType = r => ({ NORMAL: 'success', SURPLUS: 'warning', DEFICIT: 'danger', LOCATION_DIFF: 'warning' }[r] || '')

async function loadData() {
  loading.value = true
  try {
    const res = await inventoryApi.page(query)
    list.value = res.data?.records || []
    total.value = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, taskName: '', planDate: '' })
  dialog.value = true
}

function openEdit(row) {
  Object.assign(form, { id: row.id, taskName: row.taskName, planDate: row.planDate })
  dialog.value = true
}

async function submitForm() {
  await formRef.value.validate()
  if (form.id) {
    await inventoryApi.update(form.id, form)
  } else {
    await inventoryApi.create(form)
  }
  ElMessage.success('保存成功')
  dialog.value = false
  loadData()
}

async function viewDetails(row) {
  currentTaskId.value = row.id
  const res = await inventoryApi.getDetails(row.id)
  details.value = res.data || []
  detailDialog.value = true
}

function openSubmitDetail() {
  Object.assign(detailForm, { assetId: null, qrContent: '', actualLocationId: null, result: 'NORMAL', remark: '' })
  selectedAsset.value = null
  submitDetailDialog.value = true
}

function toCamelRow(row) {
  const result = {}
  for (const [key, value] of Object.entries(row || {})) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
    result[camelKey] = value
  }
  return result
}

function readField(row, camelKey, snakeKey) {
  return row?.[camelKey] ?? row?.[snakeKey]
}

function sameText(a, b) {
  return normalizeQrText(a) === normalizeQrText(b)
}

async function findAssetByQrContent(qrContent) {
  const normalizedQr = normalizeQrText(qrContent)
  if (!normalizedQr) return null

  const maybeAssetNo = extractAssetNoFromQr(normalizedQr)
  const pageSize = 200
  let pageNum = 1

  while (true) {
    const res = await physicalAssetApi.page({ pageNum, pageSize })
    const records = res.data?.records || []

    const matched = records.find((row) => {
      const rowQr = readField(row, 'qrCode', 'qr_code')
      const rowAssetNo = readField(row, 'assetNo', 'asset_no')
      return sameText(rowQr, normalizedQr) ||
        sameText(rowAssetNo, normalizedQr) ||
        (maybeAssetNo && sameText(rowAssetNo, maybeAssetNo))
    })

    if (matched) return toCamelRow(matched)
    if (records.length < pageSize) break
    pageNum += 1
  }

  return null
}

async function resolveDetailAssetByQr() {
  const qrText = (detailForm.qrContent || '').trim()
  if (!qrText) {
    ElMessage.warning('请先输入或扫描二维码')
    return
  }

  let asset = null

  const assetId = parseAssetIdFromQr(qrText)
  if (assetId) {
    try {
      const res = await physicalAssetApi.getById(assetId)
      asset = res.data || null
    } catch {
      asset = null
    }
  }

  if (!asset?.id) {
    asset = await findAssetByQrContent(qrText)
  }

  if (!asset?.id) {
    ElMessage.warning('未找到对应设备，请确认二维码是否为本系统设备标签')
    return
  }

  detailForm.assetId = asset.id
  selectedAsset.value = asset
  ElMessage.success('设备识别成功')
}

async function submitDetail() {
  if (!detailForm.assetId) {
    ElMessage.warning('请先扫描或填写资产ID')
    return
  }

  await inventoryApi.submitDetail(currentTaskId.value, {
    assetId: detailForm.assetId,
    actualLocationId: detailForm.actualLocationId,
    result: detailForm.result,
    remark: detailForm.remark
  })
  ElMessage.success('录入成功')
  submitDetailDialog.value = false
  const res = await inventoryApi.getDetails(currentTaskId.value)
  details.value = res.data || []
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该盘点任务？', '提示', { type: 'warning' })
  await inventoryApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

function handleQrScanned(text) {
  detailForm.qrContent = text
  resolveDetailAssetByQr()
}

onMounted(loadData)
</script>

<style scoped>
.action-row {
  width: 100%;
  display: flex;
  justify-content: flex-end;
  margin-top: 4px;
}
</style>
