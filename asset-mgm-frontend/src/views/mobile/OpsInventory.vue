<template>
  <div class="mobile-page">
    <div class="topbar">
      <el-button link @click="$router.push('/m/ops')">返回</el-button>
      <h2>盘点扫码录入</h2>
      <el-button link @click="loadTasks">刷新</el-button>
    </div>

    <el-card shadow="never" class="main-card">
      <el-form label-position="top">
        <el-form-item label="盘点任务">
          <el-select v-model="form.taskId" placeholder="请选择任务" style="width: 100%" filterable>
            <el-option
              v-for="t in taskOptions"
              :key="t.id"
              :label="`${t.taskName || '未命名任务'}（${t.taskNo || t.id}）`"
              :value="t.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="设备二维码">
          <el-input v-model="form.qrContent" placeholder="点击扫码或手动输入二维码内容" clearable>
            <template #append>
              <el-button @click="resolveAssetByQr">识别</el-button>
            </template>
          </el-input>
          <div class="row-actions">
            <el-button type="primary" @click="scannerVisible = true">开始扫码</el-button>
            <el-switch v-model="continuous" active-text="连续扫码" />
          </div>
        </el-form-item>

        <el-alert
          v-if="selectedAsset"
          type="success"
          :closable="false"
          show-icon
          :title="`${selectedAsset.assetName || '-'}（${selectedAsset.assetNo || '无编号'}）`"
          :description="`资产ID: ${selectedAsset.id}`"
        />

        <el-form-item label="实际位置ID" style="margin-top: 12px;">
          <el-input-number v-model="form.actualLocationId" :min="1" style="width: 100%" />
        </el-form-item>

        <el-form-item label="盘点结果">
          <el-select v-model="form.result" style="width: 100%">
            <el-option label="正常" value="NORMAL" />
            <el-option label="盘盈" value="SURPLUS" />
            <el-option label="盘亏" value="DEFICIT" />
            <el-option label="位置不符" value="LOCATION_DIFF" />
          </el-select>
        </el-form-item>

        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>

        <el-button type="primary" :loading="submitting" class="submit-btn" @click="submitDetail">
          提交盘点明细
        </el-button>
      </el-form>
    </el-card>

    <QrScannerDialog v-model="scannerVisible" @scanned="handleScanned" />
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { inventoryApi, physicalAssetApi, qrPoolApi } from '@/api/physical'
import { extractAssetNoFromQr, normalizeQrText, parseAssetIdFromQr, isQrPoolFormat } from '@/utils/assetQr'
import QrScannerDialog from '@/components/QrScannerDialog.vue'

const taskOptions = ref([])
const scannerVisible = ref(false)
const submitting = ref(false)
const selectedAsset = ref(null)
const continuous = ref(true)

const form = reactive({
  taskId: null,
  qrContent: '',
  assetId: null,
  actualLocationId: null,
  result: 'NORMAL',
  remark: ''
})

function toCamelRow(row) {
  const result = {}
  for (const [key, value] of Object.entries(row || {})) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
    result[camelKey] = value
  }
  return result
}

function sameText(a, b) {
  return normalizeQrText(a) === normalizeQrText(b)
}

async function loadTasks() {
  const res = await inventoryApi.page({ pageNum: 1, pageSize: 200 })
  const all = res.data?.records || []
  taskOptions.value = all.filter((t) => ['DRAFT', 'IN_PROGRESS'].includes(t.status))
  if (!form.taskId && taskOptions.value.length) {
    form.taskId = taskOptions.value[0].id
  }
}

async function fetchAllAssets() {
  const pageSize = 200
  let pageNum = 1
  let total = 0
  const all = []

  do {
    const res = await physicalAssetApi.page({ pageNum, pageSize })
    const rows = (res.data?.records || []).map(toCamelRow)
    total = Number(res.data?.total || 0)
    all.push(...rows)
    pageNum += 1
  } while (all.length < total)

  return all
}

async function findAssetByQrContent(qrText) {
  const normalized = normalizeQrText(qrText)
  if (!normalized) return null

  const maybeAssetNo = extractAssetNoFromQr(normalized)
  const assets = await fetchAllAssets()

  return assets.find((a) => {
    return sameText(a.qrCode, normalized) ||
      sameText(a.assetNo, normalized) ||
      (maybeAssetNo && sameText(a.assetNo, maybeAssetNo))
  }) || null
}

async function resolveAssetByQr() {
  const qrText = String(form.qrContent || '').trim()
  if (!qrText) {
    ElMessage.warning('请先扫码或输入二维码')
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

  if (!asset?.id && isQrPoolFormat(qrText)) {
    try {
      const poolEntry = await qrPoolApi.getByCode(qrText)
      if (poolEntry?.assetId) {
        const res = await physicalAssetApi.getById(poolEntry.assetId)
        asset = res.data || null
      }
    } catch {
      asset = null
    }
  }

  if (!asset?.id) {
    ElMessage.warning('未识别到设备，请确认二维码是否正确')
    return
  }

  form.assetId = asset.id
  selectedAsset.value = asset
  ElMessage.success('设备识别成功')
}

async function submitDetail() {
  if (!form.taskId) {
    ElMessage.warning('请先选择盘点任务')
    return
  }
  if (!form.assetId) {
    ElMessage.warning('请先识别设备')
    return
  }

  submitting.value = true
  try {
    await inventoryApi.submitDetail(form.taskId, {
      assetId: form.assetId,
      actualLocationId: form.actualLocationId,
      result: form.result,
      remark: form.remark
    })
    ElMessage.success('盘点明细提交成功')

    form.qrContent = ''
    form.assetId = null
    form.actualLocationId = null
    form.result = 'NORMAL'
    form.remark = ''
    selectedAsset.value = null

    if (continuous.value) {
      setTimeout(() => {
        scannerVisible.value = true
      }, 200)
    }
  } finally {
    submitting.value = false
  }
}

function handleScanned(text) {
  form.qrContent = text
  resolveAssetByQr()
}

onMounted(loadTasks)
</script>

<style scoped>
.mobile-page {
  min-height: 100svh;
  background: #f3f7ff;
  padding: 16px;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  gap: 12px;
}

.topbar h2 {
  margin: 0;
  font-size: 18px;
  color: #1d3557;
}

.main-card {
  border-radius: 12px;
}

.row-actions {
  margin-top: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.submit-btn {
  width: 100%;
  height: 48px;
  margin-top: 16px;
}
</style>
