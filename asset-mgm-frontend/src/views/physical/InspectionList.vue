<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">巡检管理</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建任务</el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form inline>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px">
            <el-option label="待执行" value="PENDING" />
            <el-option label="进行中" value="IN_PROGRESS" />
            <el-option label="已完成" value="COMPLETED" />
            <el-option label="已逾期" value="OVERDUE" />
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
            <el-button link type="primary" @click="viewRecords(row)">打卡记录</el-button>
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="mt-4" background layout="total, prev, pager, next"
        :total="total" :page-size="query.pageSize" v-model:current-page="query.pageNum"
        @current-change="loadData" />
    </el-card>

    <el-dialog v-model="taskDialog" :title="form.id ? '编辑任务' : '新建巡检任务'" width="500px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" />
        </el-form-item>
        <el-form-item label="计划日期" prop="planDate">
          <el-date-picker v-model="form.planDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="taskDialog = false">取消</el-button>
        <el-button type="primary" @click="submitTask">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="recordDialog" title="巡检打卡记录" width="700px">
      <div class="mb-3">
        <el-button type="primary" size="small" @click="openCheckin">新增打卡</el-button>
      </div>
      <el-table :data="records" border size="small" v-loading="loadingRecords">
        <el-table-column prop="checkTime" label="打卡时间" width="160" />
        <el-table-column label="结果" width="90">
          <template #default="{ row }">
            <el-tag :type="row.result === 'NORMAL' ? 'success' : row.result === 'ABNORMAL' ? 'warning' : 'danger'" size="small">
              {{ { NORMAL: '正常', ABNORMAL: '异常', NEED_REPAIR: '需维修' }[row.result] || row.result }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="locationDesc" label="位置描述" show-overflow-tooltip />
        <el-table-column prop="description" label="备注" show-overflow-tooltip />
      </el-table>
    </el-dialog>

    <el-dialog v-model="checkinDialog" title="巡检打卡" width="520px">
      <el-form :model="checkinForm" ref="checkinRef" label-width="95px">
        <el-form-item label="设备二维码">
          <el-input v-model="checkinForm.qrContent" placeholder="手动输入或点击扫码" clearable>
            <template #append>
              <el-button @click="resolveCheckinAssetByQr">识别</el-button>
            </template>
          </el-input>
          <div class="action-row">
            <el-button type="primary" link @click="scannerVisible = true">手机摄像头扫码</el-button>
          </div>
        </el-form-item>
        <el-form-item label="识别设备" v-if="selectedAsset">
          <el-alert
            :title="`${selectedAsset.assetName || '-'}（${selectedAsset.assetNo || '无编号'}）`"
            :description="`资产ID: ${selectedAsset.id}，状态: ${selectedAsset.status || '-'}`"
            type="success"
            :closable="false"
            show-icon
          />
        </el-form-item>
        <el-form-item label="资产ID">
          <el-input-number v-model="checkinForm.assetId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="巡检结果" prop="result">
          <el-select v-model="checkinForm.result" style="width:100%">
            <el-option label="正常" value="NORMAL" />
            <el-option label="异常" value="ABNORMAL" />
            <el-option label="需维修" value="NEED_REPAIR" />
          </el-select>
        </el-form-item>
        <el-form-item label="位置描述">
          <el-input v-model="checkinForm.locationDesc" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="checkinForm.description" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="checkinDialog = false">取消</el-button>
        <el-button type="primary" @click="submitCheckin">提交</el-button>
      </template>
    </el-dialog>

    <QrScannerDialog v-model="scannerVisible" @scanned="handleQrScanned" />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { inspectionApi, physicalAssetApi } from '@/api/physical'
import { extractAssetNoFromQr, normalizeQrText, parseAssetIdFromQr } from '@/utils/assetQr'
import QrScannerDialog from '@/components/QrScannerDialog.vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

const loading = ref(false)
const loadingRecords = ref(false)
const list = ref([])
const total = ref(0)
const query = reactive({ pageNum: 1, pageSize: 20, status: '' })

const taskDialog = ref(false)
const recordDialog = ref(false)
const checkinDialog = ref(false)
const scannerVisible = ref(false)
const formRef = ref()
const checkinRef = ref()
const form = reactive({ id: null, taskName: '', planDate: '' })
const checkinForm = reactive({
  taskId: null,
  assetId: null,
  qrContent: '',
  result: 'NORMAL',
  locationDesc: '',
  description: ''
})
const selectedAsset = ref(null)
const records = ref([])
const currentTask = ref(null)

const rules = {
  taskName: [{ required: true, message: '请输入任务名称' }],
  planDate: [{ required: true, message: '请选择计划日期' }]
}

const statusLabel = s => ({ PENDING: '待执行', IN_PROGRESS: '进行中', COMPLETED: '已完成', OVERDUE: '已逾期' }[s] || s)
const statusType = s => ({ PENDING: 'info', IN_PROGRESS: 'primary', COMPLETED: 'success', OVERDUE: 'danger' }[s] || '')

async function loadData() {
  loading.value = true
  try {
    const res = await inspectionApi.pageTasks(query)
    list.value = res.data?.records || []
    total.value = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, taskName: '', planDate: '' })
  taskDialog.value = true
}

function openEdit(row) {
  Object.assign(form, { id: row.id, taskName: row.taskName, planDate: row.planDate })
  taskDialog.value = true
}

async function submitTask() {
  await formRef.value.validate()
  if (form.id) {
    await inspectionApi.updateTask(form.id, form)
  } else {
    await inspectionApi.createTask(form)
  }
  ElMessage.success('保存成功')
  taskDialog.value = false
  loadData()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该巡检任务？', '提示', { type: 'warning' })
  await inspectionApi.deleteTask(id)
  ElMessage.success('删除成功')
  loadData()
}

async function viewRecords(row) {
  currentTask.value = row
  await loadTaskRecords(row.id)
  recordDialog.value = true
}

function openCheckin() {
  Object.assign(checkinForm, {
    taskId: currentTask.value?.id,
    assetId: null,
    qrContent: '',
    result: 'NORMAL',
    locationDesc: '',
    description: ''
  })
  selectedAsset.value = null
  checkinDialog.value = true
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

async function fetchAssetsByProject(projectId) {
  const pageSize = 200
  let pageNum = 1
  let totalCount = 0
  const all = []

  do {
    const res = await physicalAssetApi.page({
      pageNum,
      pageSize,
      projectId: projectId || undefined
    })
    const rows = (res.data?.records || []).map(toCamelRow)
    totalCount = Number(res.data?.total || 0)
    all.push(...rows)
    pageNum += 1
  } while (all.length < totalCount)

  return all
}

async function findAssetByQrContent(qrContent) {
  const normalizedQr = normalizeQrText(qrContent)
  if (!normalizedQr) return null

  const maybeAssetNo = extractAssetNoFromQr(normalizedQr)
  const assets = await fetchAssetsByProject(currentTask.value?.projectId)

  const matched = assets.find((row) => {
    const rowQr = readField(row, 'qrCode', 'qr_code')
    const rowAssetNo = readField(row, 'assetNo', 'asset_no')
    return sameText(rowQr, normalizedQr) ||
      sameText(rowAssetNo, normalizedQr) ||
      (maybeAssetNo && sameText(rowAssetNo, maybeAssetNo))
  })

  return matched || null
}

async function resolveCheckinAssetByQr() {
  const qrText = (checkinForm.qrContent || '').trim()
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

  checkinForm.assetId = asset.id
  selectedAsset.value = asset
  if (!checkinForm.locationDesc && asset.locationId) {
    checkinForm.locationDesc = `位置ID:${asset.locationId}`
  }
  ElMessage.success('设备识别成功')
}

function resolveInspectorId() {
  const fromStore = Number(userStore.userInfo?.userId)
  if (Number.isFinite(fromStore) && fromStore > 0) return fromStore

  try {
    const local = JSON.parse(localStorage.getItem('userInfo') || '{}')
    const fromLocal = Number(local.userId)
    if (Number.isFinite(fromLocal) && fromLocal > 0) return fromLocal
  } catch {
    // ignore
  }

  return null
}

async function submitCheckin() {
  if (!checkinForm.assetId) {
    ElMessage.warning('请先扫描或填写资产ID')
    return
  }

  const inspectorId = resolveInspectorId()
  if (!inspectorId) {
    ElMessage.warning('未获取到当前登录用户信息，请重新登录后再试')
    return
  }

  await inspectionApi.checkIn({
    taskId: checkinForm.taskId,
    assetId: checkinForm.assetId,
    inspectorId,
    result: checkinForm.result,
    locationDesc: checkinForm.locationDesc,
    description: checkinForm.description
  })
  ElMessage.success('打卡成功')
  checkinDialog.value = false
  await loadTaskRecords(currentTask.value.id)
}

function handleQrScanned(text) {
  checkinForm.qrContent = text
  resolveCheckinAssetByQr()
}

async function loadTaskRecords(taskId) {
  loadingRecords.value = true
  try {
    const assets = await fetchAssetsByProject(currentTask.value?.projectId)
    const merged = []

    for (const assetItem of assets) {
      try {
        const res = await inspectionApi.getByAsset(assetItem.id)
        const arr = res.data || []
        for (const rec of arr) {
          if (Number(rec.taskId) === Number(taskId)) {
            merged.push(rec)
          }
        }
      } catch {
        // ignore single asset failure
      }
    }

    merged.sort((a, b) => new Date(b.checkTime).getTime() - new Date(a.checkTime).getTime())
    records.value = merged
  } finally {
    loadingRecords.value = false
  }
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
