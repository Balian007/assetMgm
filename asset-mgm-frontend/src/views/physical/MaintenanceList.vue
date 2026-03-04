<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">维修工单</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建工单</el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form inline>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px">
            <el-option label="待处理" value="PENDING" />
            <el-option label="处理中" value="IN_PROGRESS" />
            <el-option label="已完成" value="COMPLETED" />
            <el-option label="已取消" value="CANCELLED" />
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
        <el-table-column prop="orderNo" label="工单编号" width="160" />
        <el-table-column prop="faultDesc" label="故障描述" show-overflow-tooltip />
        <el-table-column prop="reportTime" label="报修时间" width="160" />
        <el-table-column prop="finishTime" label="完成时间" width="160" />
        <el-table-column prop="cost" label="维修费用" width="100">
          <template #default="{ row }">{{ row.cost != null ? '¥' + row.cost : '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="row.status !== 'COMPLETED'" link type="success" @click="openComplete(row)">完成</el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="mt-4" background layout="total, prev, pager, next"
        :total="total" :page-size="query.pageSize" v-model:current-page="query.pageNum"
        @current-change="loadData" />
    </el-card>

    <!-- 新建/编辑 -->
    <el-dialog v-model="dialog" :title="form.id ? '编辑工单' : '新建维修工单'" width="500px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="资产ID" prop="assetId">
          <el-input-number v-model="form.assetId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="故障描述" prop="faultDesc">
          <el-input v-model="form.faultDesc" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="处理人ID">
          <el-input-number v-model="form.assigneeId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="处理结果">
          <el-input v-model="form.result" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">取消</el-button>
        <el-button type="primary" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>

    <!-- 完成工单 -->
    <el-dialog v-model="completeDialog" title="完成维修工单" width="460px">
      <el-form :model="completeForm" label-width="90px">
        <el-form-item label="维修结果">
          <el-input v-model="completeForm.result" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="维修费用">
          <el-input-number v-model="completeForm.cost" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="completeDialog = false">取消</el-button>
        <el-button type="success" @click="submitComplete">确认完成</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { maintenanceApi } from '@/api/physical'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const query = reactive({ pageNum: 1, pageSize: 20, status: '' })
const dialog = ref(false)
const completeDialog = ref(false)
const formRef = ref()
const form = reactive({ id: null, assetId: null, faultDesc: '', assigneeId: null, result: '' })
const completeForm = reactive({ id: null, result: '', cost: 0 })

const rules = {
  assetId: [{ required: true, message: '请输入资产ID' }],
  faultDesc: [{ required: true, message: '请描述故障情况' }]
}
const statusLabel = s => ({ PENDING: '待处理', IN_PROGRESS: '处理中', COMPLETED: '已完成', CANCELLED: '已取消' }[s] || s)
const statusType = s => ({ PENDING: 'warning', IN_PROGRESS: 'primary', COMPLETED: 'success', CANCELLED: 'info' }[s] || '')

async function loadData() {
  loading.value = true
  try {
    const res = await maintenanceApi.page(query)
    list.value = res.data?.records || []
    total.value = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, assetId: null, faultDesc: '', assigneeId: null, result: '' })
  dialog.value = true
}

function openEdit(row) {
  Object.assign(form, {
    id: row.id,
    assetId: row.assetId,
    faultDesc: row.faultDesc,
    assigneeId: row.assigneeId,
    result: row.result || ''
  })
  dialog.value = true
}

async function submitForm() {
  await formRef.value.validate()
  if (form.id) {
    await maintenanceApi.update(form.id, form)
  } else {
    await maintenanceApi.create(form)
  }
  ElMessage.success('保存成功')
  dialog.value = false
  loadData()
}

function openComplete(row) {
  Object.assign(completeForm, { id: row.id, result: row.result || '', cost: row.cost || 0 })
  completeDialog.value = true
}

async function submitComplete() {
  await maintenanceApi.complete(completeForm.id, completeForm)
  ElMessage.success('工单已完成')
  completeDialog.value = false
  loadData()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该维修工单？', '提示', { type: 'warning' })
  await maintenanceApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>
