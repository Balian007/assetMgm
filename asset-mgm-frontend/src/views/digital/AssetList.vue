<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">数字资产目录</h2>
      <el-button type="primary" @click="openForm()"><el-icon><Plus /></el-icon> 新增资产</el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form :model="query" inline>
        <el-form-item label="资产名称">
          <el-input v-model="query.assetName" placeholder="搜索资产名称" clearable style="width:200px" />
        </el-form-item>
        <el-form-item label="数据级别">
          <el-select v-model="query.dataLevel" placeholder="全部" clearable style="width:120px">
            <el-option label="公开" value="PUBLIC" />
            <el-option label="内部" value="INTERNAL" />
            <el-option label="机密" value="CONFIDENTIAL" />
            <el-option label="秘密" value="SECRET" />
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
        <el-table-column prop="assetNo" label="资产编号" width="180" />
        <el-table-column prop="assetName" label="资产名称" min-width="160" />
        <el-table-column label="所属项目" width="160">
          <template #default="{ row }">
            {{ projectNameById(row.projectId) }}
          </template>
        </el-table-column>
        <el-table-column prop="dataType" label="数据类型" width="100">
          <template #default="{ row }">
            <el-tag size="small" :type="row.dataType === 'STRUCTURED' ? '' : 'warning'">
              {{ row.dataType === 'STRUCTURED' ? '结构化' : '非结构化' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="dataLevel" label="数据级别" width="90">
          <template #default="{ row }">
            <el-tag size="small" :type="levelTagType(row.dataLevel)">{{ levelLabel(row.dataLevel) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="storageType" label="存储类型" width="100" />
        <el-table-column prop="status" label="状态" width="90">
          <template #default="{ row }">
            <el-tag size="small" :type="row.status === 'ACTIVE' ? 'success' : 'info'">
              {{ { ACTIVE: '活跃', DEPRECATED: '已废弃', ARCHIVED: '已归档' }[row.status] || row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="version" label="版本" width="80" />
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push(`/digital/assets/${row.id}`)">详情</el-button>
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
        style="margin-top:16px;justify-content:flex-end"
        @change="loadData"
      />
    </el-card>

    <el-dialog v-model="dialogVisible" :title="editRow ? '编辑数字资产' : '新增数字资产'" width="600px">
      <el-form :model="formData" label-width="90px" ref="formRef">
        <el-row :gutter="16">
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="分类ID" prop="categoryId" :rules="[{required:true,message:'必填'}]">
              <el-input-number v-model="formData.categoryId" :min="1" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="资产名称" prop="assetName" :rules="[{required:true,message:'必填'}]">
              <el-input v-model="formData.assetName" />
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="所属项目" prop="projectId" :rules="[{ required: true, message: '必须选择项目' }]">
              <el-select v-model="formData.projectId" placeholder="请选择" style="width:100%">
                <el-option v-for="p in projects" :key="p.id" :label="p.projectName" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="数据类型">
              <el-select v-model="formData.dataType" style="width:100%">
                <el-option label="结构化" value="STRUCTURED" />
                <el-option label="非结构化" value="UNSTRUCTURED" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="数据级别">
              <el-select v-model="formData.dataLevel" style="width:100%">
                <el-option label="公开" value="PUBLIC" />
                <el-option label="内部" value="INTERNAL" />
                <el-option label="机密" value="CONFIDENTIAL" />
                <el-option label="秘密" value="SECRET" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="存储类型">
              <el-select v-model="formData.storageType" style="width:100%">
                <el-option label="MySQL" value="MYSQL" />
                <el-option label="Oracle" value="ORACLE" />
                <el-option label="MinIO" value="MINIO" />
                <el-option label="NFS" value="NFS" />
                <el-option label="HTTP" value="HTTP" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xl="12" :lg="12" :md="12" :sm="24" :xs="24">
            <el-form-item label="版本">
              <el-input v-model="formData.version" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="存储路径">
              <el-input v-model="formData.storagePath" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="描述">
              <el-input v-model="formData.description" type="textarea" :rows="2" />
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { digitalAssetApi } from '@/api/digital/index'
import { projectApi } from '@/api/system/index'

const loading = ref(false)
const submitting = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const editRow = ref(null)
const formRef = ref()
const formData = ref({})
const projects = ref([])

const query = reactive({ pageNum: 1, pageSize: 20, assetName: '', dataLevel: '' })

const levelMap = { PUBLIC: { label: '公开', type: 'success' }, INTERNAL: { label: '内部', type: '' }, CONFIDENTIAL: { label: '机密', type: 'warning' }, SECRET: { label: '秘密', type: 'danger' } }
const levelLabel = (l) => levelMap[l]?.label || l
const levelTagType = (l) => levelMap[l]?.type || ''

const projectMap = computed(() => {
  const map = new Map()
  for (const p of projects.value) {
    map.set(p.id, p.projectName)
  }
  return map
})

const projectNameById = (id) => projectMap.value.get(id) || '-'

async function loadProjects() {
  const res = await projectApi.page({ pageNum: 1, pageSize: 500 })
  projects.value = res.data?.records || []
}

async function loadData() {
  loading.value = true
  try {
    const res = await digitalAssetApi.page(query)
    tableData.value = res.data.records
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

function resetQuery() {
  Object.assign(query, { pageNum: 1, assetName: '', dataLevel: '' })
  loadData()
}

function openForm(row = null) {
  editRow.value = row
  formData.value = row
    ? { ...row }
    : { categoryId: null, projectId: null, dataLevel: 'INTERNAL', dataType: 'STRUCTURED' }
  dialogVisible.value = true
}

async function submitForm() {
  await formRef.value.validate()
  submitting.value = true
  try {
    if (editRow.value) {
      await digitalAssetApi.update(editRow.value.id, formData.value)
    } else {
      await digitalAssetApi.create(formData.value)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

async function deleteRow(id) {
  await digitalAssetApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(async () => {
  await Promise.all([loadData(), loadProjects()])
})
</script>
