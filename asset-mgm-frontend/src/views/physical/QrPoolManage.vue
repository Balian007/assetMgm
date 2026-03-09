<template>
  <div class="qr-pool-manage">
    <div class="toolbar">
      <el-button type="primary" @click="showGenerateDialog = true">生成二维码</el-button>
      <el-button @click="showExportDialog = true">导出打印</el-button>
    </div>

    <div class="filters">
      <el-select v-model="filters.status" placeholder="状态" clearable @change="loadData">
        <el-option label="可用" value="AVAILABLE" />
        <el-option label="已绑定" value="BOUND" />
        <el-option label="作废" value="INVALID" />
      </el-select>
      <el-input v-model="filters.batchNo" placeholder="批次号" clearable @change="loadData" style="width: 200px; margin-left: 10px" />
    </div>

    <el-table :data="tableData" style="margin-top: 20px">
      <el-table-column prop="qrCode" label="二维码" />
      <el-table-column prop="status" label="状态">
        <template #default="{ row }">
          <el-tag v-if="row.status === 'AVAILABLE'" type="success">可用</el-tag>
          <el-tag v-else-if="row.status === 'BOUND'">已绑定</el-tag>
          <el-tag v-else type="info">作废</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="assetId" label="绑定资产" />
      <el-table-column prop="batchNo" label="批次号" />
      <el-table-column prop="createdAt" label="创建时间" />
    </el-table>

    <el-pagination
      v-model:current-page="pagination.page"
      v-model:page-size="pagination.size"
      :total="pagination.total"
      @current-change="loadData"
      layout="total, prev, pager, next"
      style="margin-top: 20px; justify-content: center"
    />

    <el-dialog v-model="showGenerateDialog" title="生成二维码" width="400px">
      <el-form>
        <el-form-item label="数量">
          <el-input-number v-model="generateCount" :min="1" :max="1000" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showGenerateDialog = false">取消</el-button>
        <el-button type="primary" @click="handleGenerate">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showExportDialog" title="导出打印" width="400px">
      <el-form>
        <el-form-item label="批次号">
          <el-input v-model="exportBatchNo" placeholder="输入批次号" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showExportDialog = false">取消</el-button>
        <el-button type="primary" @click="handleExport">导出</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { qrPoolApi } from '@/api/physical'

const tableData = ref([])
const pagination = ref({ page: 1, size: 20, total: 0 })
const filters = ref({ status: '', batchNo: '' })
const showGenerateDialog = ref(false)
const showExportDialog = ref(false)
const generateCount = ref(50)
const exportBatchNo = ref('')

const loadData = async () => {
  try {
    const params = { page: pagination.value.page, size: pagination.value.size }
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.batchNo) params.batchNo = filters.value.batchNo

    const res = await qrPoolApi.page(params)
    const pageData = res.data || res
    tableData.value = pageData.records || []
    pagination.value.total = pageData.total || 0
  } catch (error) {
    ElMessage.error('加载数据失败')
    console.error(error)
  }
}

const handleGenerate = async () => {
  const res = await qrPoolApi.generate(generateCount.value)
  const batchNo = res.data?.batchNo || res.batchNo
  ElMessage.success(`生成成功，批次号：${batchNo}`)
  showGenerateDialog.value = false
  loadData()
}

const handleExport = async () => {
  try {
    const blob = await qrPoolApi.exportBatch(exportBatchNo.value)
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${exportBatchNo.value}.html`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    window.URL.revokeObjectURL(url)
    showExportDialog.value = false
    ElMessage.success('导出成功，请打开HTML文件打印')
  } catch (error) {
    ElMessage.error('导出失败')
  }
}

onMounted(loadData)
</script>

<style scoped>
.qr-pool-manage { padding: 20px; }
.toolbar { margin-bottom: 20px; }
.filters { display: flex; align-items: center; }
</style>
