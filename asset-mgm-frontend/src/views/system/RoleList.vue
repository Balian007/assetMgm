<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">角色管理</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建角色</el-button>
    </div>

    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="roleCode" label="角色编码" width="150" />
        <el-table-column prop="roleName" label="角色名称" width="150" />
        <el-table-column prop="description" label="描述" show-overflow-tooltip />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialog" :title="form.id ? '编辑角色' : '新建角色'" width="460px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="角色编码" prop="roleCode">
          <el-input v-model="form.roleCode" :disabled="!!form.id" placeholder="如 ADMIN / OPS" />
        </el-form-item>
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="form.roleName" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="2" />
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
import { roleApi } from '@/api/system'

const loading = ref(false)
const list = ref([])
const dialog = ref(false)
const formRef = ref()
const form = reactive({ id: null, roleCode: '', roleName: '', description: '' })

const rules = {
  roleCode: [{ required: true, message: '请输入角色编码' }],
  roleName: [{ required: true, message: '请输入角色名称' }]
}

async function loadData() {
  loading.value = true
  try {
    const res = await roleApi.list()
    list.value = res.data || []
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, roleCode: '', roleName: '', description: '' })
  dialog.value = true
}

function openEdit(row) {
  Object.assign(form, { id: row.id, roleCode: row.roleCode, roleName: row.roleName, description: row.description })
  dialog.value = true
}

async function submitForm() {
  await formRef.value.validate()
  if (form.id) {
    await roleApi.update(form.id, form)
  } else {
    await roleApi.create(form)
  }
  ElMessage.success('保存成功')
  dialog.value = false
  loadData()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该角色？', '提示', { type: 'warning' })
  await roleApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>
