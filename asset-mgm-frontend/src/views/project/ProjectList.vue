<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">项目管理</h2>
      <el-button type="primary" @click="openForm()">
        <el-icon><Plus /></el-icon>
        新增项目
      </el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form :model="query" inline>
        <el-form-item label="项目名称">
          <el-input v-model="query.projectName" placeholder="搜索项目" clearable style="width: 200px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width: 120px">
            <el-option label="规划中" value="PLANNING" />
            <el-option label="进行中" value="ACTIVE" />
            <el-option label="已完成" value="COMPLETED" />
            <el-option label="已归档" value="ARCHIVED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="projectNo" label="项目编号" width="150" />
        <el-table-column prop="projectName" label="项目名称" min-width="180" />
        <el-table-column prop="location" label="项目地点" width="150" />
        <el-table-column prop="startDate" label="开始日期" width="110" />
        <el-table-column prop="endDate" label="结束日期" width="110" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{ row }">
            <el-tag size="small" :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="170" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push(`/projects/${row.id}`)">详情</el-button>
            <el-button link type="primary" @click="openForm(row)">编辑</el-button>
            <el-popconfirm title="确认删除？" @confirm="deleteRow(row.id)">
              <template #reference>
                <el-button link type="danger">删除</el-button>
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
        style="margin-top: 16px; justify-content: flex-end"
        @change="loadData"
      />
    </el-card>

    <el-dialog v-model="dialogVisible" :title="editRow ? '编辑项目' : '新增项目'" width="560px">
      <el-form :model="formData" label-width="90px" ref="formRef">
        <el-form-item label="项目编号" prop="projectNo" :rules="[{ required: true, message: '必填' }]">
          <el-input v-model="formData.projectNo" />
        </el-form-item>
        <el-form-item label="项目名称" prop="projectName" :rules="[{ required: true, message: '必填' }]">
          <el-input v-model="formData.projectName" />
        </el-form-item>
        <el-form-item label="项目地点">
          <el-input v-model="formData.location" />
        </el-form-item>
        <el-row :gutter="16">
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="开始日期">
              <el-date-picker v-model="formData.startDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="结束日期">
              <el-date-picker v-model="formData.endDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="状态">
          <el-select v-model="formData.status" placeholder="请选择" style="width: 100%">
            <el-option label="规划中" value="PLANNING" />
            <el-option label="进行中" value="ACTIVE" />
            <el-option label="已完成" value="COMPLETED" />
            <el-option label="已归档" value="ARCHIVED" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="formData.description" type="textarea" :rows="3" />
        </el-form-item>
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
import { projectApi } from '@/api/system/index'

const loading = ref(false)
const submitting = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const editRow = ref(null)
const formRef = ref()
const formData = ref({})
const query = reactive({ pageNum: 1, pageSize: 20, projectName: '', status: '' })

const statusMap = {
  PLANNING: { label: '规划中', type: 'info' },
  ACTIVE: { label: '进行中', type: 'success' },
  COMPLETED: { label: '已完成', type: '' },
  ARCHIVED: { label: '已归档', type: 'warning' }
}
const statusLabel = (status) => statusMap[status]?.label || status
const statusType = (status) => statusMap[status]?.type || ''

async function loadData() {
  loading.value = true
  try {
    const res = await projectApi.page(query)
    tableData.value = res.data?.records || []
    total.value = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

function resetQuery() {
  Object.assign(query, { pageNum: 1, projectName: '', status: '' })
  loadData()
}

function openForm(row = null) {
  editRow.value = row
  formData.value = row ? { ...row } : { status: 'PLANNING' }
  dialogVisible.value = true
}

async function submitForm() {
  await formRef.value.validate()
  submitting.value = true
  try {
    if (editRow.value) {
      await projectApi.update(editRow.value.id, formData.value)
    } else {
      await projectApi.create(formData.value)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

async function deleteRow(id) {
  await projectApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>
