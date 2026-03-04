<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">用户管理</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建用户</el-button>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form inline>
        <el-form-item label="用户名">
          <el-input v-model="query.username" clearable placeholder="搜索用户名" style="width:160px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="Object.assign(query,{username:'',status:null}); loadData()">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="username" label="用户名" width="130" />
        <el-table-column prop="realName" label="姓名" width="110" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="email" label="邮箱" show-overflow-tooltip />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link :type="row.status === 1 ? 'warning' : 'success'" @click="toggleStatus(row)">
              {{ row.status === 1 ? '禁用' : '启用' }}
            </el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="mt-4" background layout="total, prev, pager, next"
        :total="total" :page-size="query.pageSize" v-model:current-page="query.pageNum"
        @current-change="loadData" />
    </el-card>

    <el-dialog v-model="dialog" :title="form.id ? '编辑用户' : '新建用户'" width="480px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="80px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" :disabled="!!form.id" />
        </el-form-item>
        <el-form-item v-if="!form.id" label="密码" prop="password">
          <el-input v-model="form.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="form.realName" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="form.phone" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">取消</el-button>
        <el-button type="primary" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { userApi } from '@/api/system'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const query = reactive({ pageNum: 1, pageSize: 20, username: '', status: null })
const dialog = ref(false)
const formRef = ref()
const form = reactive({ id: null, username: '', password: '', realName: '', phone: '', email: '' })

const rules = {
  username: [{ required: true, message: '请输入用户名' }],
  password: [{ required: true, message: '请输入密码' }]
}

async function loadData() {
  loading.value = true
  try {
    const res = await userApi.page(query)
    list.value = res.data?.records || []
    total.value = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, username: '', password: '', realName: '', phone: '', email: '' })
  dialog.value = true
}

function openEdit(row) {
  Object.assign(form, { id: row.id, username: row.username, password: '', realName: row.realName, phone: row.phone, email: row.email })
  dialog.value = true
}

async function submitForm() {
  await formRef.value.validate()
  if (form.id) {
    await userApi.update(form.id, form)
  } else {
    await userApi.create(form)
  }
  ElMessage.success('保存成功')
  dialog.value = false
  loadData()
}

async function toggleStatus(row) {
  const newStatus = row.status === 1 ? 0 : 1
  await userApi.toggleStatus(row.id, newStatus)
  ElMessage.success('状态已更新')
  loadData()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该用户？', '提示', { type: 'warning' })
  await userApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>
