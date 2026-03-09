<template>
  <div class="qr-bind">
    <div class="scan-section">
      <el-button type="primary" size="large" @click="qrScannerVisible = true">扫描二维码</el-button>
      <el-input v-model="qrCode" placeholder="或手动输入二维码" style="margin-top: 10px" />
    </div>

    <div v-if="qrInfo" class="info-section">
      <el-card>
        <h3>二维码信息</h3>
        <p>编号：{{ qrInfo.qrCode }}</p>
        <p>状态：<el-tag :type="qrInfo.status === 'AVAILABLE' ? 'success' : 'info'">{{ qrInfo.status === 'AVAILABLE' ? '可用' : '已使用' }}</el-tag></p>
      </el-card>
    </div>

    <div v-if="qrInfo?.status === 'AVAILABLE'" class="asset-section">
      <el-button @click="assetScannerVisible = true">扫描资产</el-button>
      <el-input v-model="assetNo" placeholder="或输入资产编号" style="margin-top: 10px" />
    </div>

    <div v-if="assetInfo" class="info-section">
      <el-card>
        <h3>资产信息</h3>
        <p>编号：{{ assetInfo.assetNo }}</p>
        <p>名称：{{ assetInfo.assetName }}</p>
      </el-card>
      <el-button type="primary" size="large" @click="handleBind" style="margin-top: 20px; width: 100%">确认绑定</el-button>
    </div>

    <QrScannerDialog v-model="qrScannerVisible" @scanned="handleQrScanned" />
    <QrScannerDialog v-model="assetScannerVisible" @scanned="handleAssetScanned" />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { qrPoolApi, physicalAssetApi } from '@/api/physical'
import QrScannerDialog from '@/components/QrScannerDialog.vue'

const qrCode = ref('')
const assetNo = ref('')
const qrInfo = ref(null)
const assetInfo = ref(null)
const qrScannerVisible = ref(false)
const assetScannerVisible = ref(false)

const handleQrScanned = (code) => {
  qrCode.value = code
  qrScannerVisible.value = false
}

const handleAssetScanned = (code) => {
  assetNo.value = code
  assetScannerVisible.value = false
}

watch(qrCode, async (val) => {
  if (!val) return
  try {
    const res = await qrPoolApi.getByCode(val)
    qrInfo.value = res.data || res
  } catch (error) {
    ElMessage.error('查询二维码失败')
  }
})

watch(assetNo, async (val) => {
  if (!val) return
  try {
    const res = await physicalAssetApi.page({ assetNo: val })
    const pageData = res.data || res
    if (pageData.records?.length) assetInfo.value = pageData.records[0]
  } catch (error) {
    ElMessage.error('查询资产失败')
  }
})

const handleBind = async () => {
  try {
    await qrPoolApi.bind(qrCode.value, assetInfo.value.id)
    ElMessage.success('绑定成功')
    qrCode.value = ''
    assetNo.value = ''
    qrInfo.value = null
    assetInfo.value = null
  } catch (error) {
    ElMessage.error('绑定失败')
  }
}
</script>

<style scoped>
.qr-bind { padding: 20px; }
.scan-section, .asset-section, .info-section { margin-bottom: 20px; }
</style>
