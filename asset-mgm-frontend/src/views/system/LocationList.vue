<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">位置管理</h2>
      <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon> 新建位置</el-button>
    </div>

    <el-card shadow="never">
      <el-table :data="tree" v-loading="loading" stripe row-key="id" default-expand-all
        :tree-props="{ children: 'children' }">
        <el-table-column prop="locName" label="位置名称" />
        <el-table-column label="类型" width="120">
          <template #default="{ row }">
            <el-tag size="small" type="info">{{ typeLabel(row.locType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="备注" show-overflow-tooltip />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openCreateChild(row)">添加子级</el-button>
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialog" :title="form.id ? '编辑位置' : '新建位置'" width="460px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="位置名称" prop="locName">
          <el-input v-model="form.locName" />
        </el-form-item>
        <el-form-item label="位置类型" prop="locType">
          <el-select v-model="form.locType" style="width:100%">
            <el-option label="建筑/楼栋" value="BUILDING" />
            <el-option label="楼层" value="FLOOR" />
            <el-option label="机房/房间" value="ROOM" />
            <el-option label="机柜" value="CABINET" />
            <el-option label="机架" value="RACK" />
          </el-select>
        </el-form-item>
        <el-form-item label="上级位置">
          <el-tree-select v-model="form.parentId" :data="treeOptions" clearable
            :props="{ label: 'locName', value: 'id', children: 'children' }"
            placeholder="根节点" style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
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
import { locationApi } from '@/api/system'

const loading = ref(false)
const tree = ref([])
const treeOptions = ref([])
const dialog = ref(false)
const formRef = ref()
const form = reactive({ id: null, locName: '', locType: 'ROOM', parentId: null, description: '' })

const rules = {
  locName: [{ required: true, message: '请输入位置名称' }],
  locType: [{ required: true, message: '请选择位置类型' }]
}

const typeLabel = t => ({ BUILDING: '楼栋', FLOOR: '楼层', ROOM: '机房', CABINET: '机柜', RACK: '机架' }[t] || t)

async function loadData() {
  loading.value = true
  try {
    const res = await locationApi.tree()
    tree.value = res.data || []
    treeOptions.value = res.data || []
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, { id: null, locName: '', locType: 'ROOM', parentId: null, description: '' })
  dialog.value = true
}

function openCreateChild(row) {
  Object.assign(form, { id: null, locName: '', locType: 'ROOM', parentId: row.id, description: '' })
  dialog.value = true
}

function openEdit(row) {
  Object.assign(form, { id: row.id, locName: row.locName, locType: row.locType, parentId: row.parentId, description: row.description })
  dialog.value = true
}

async function submitForm() {
  await formRef.value.validate()
  if (form.id) {
    await locationApi.update(form.id, form)
  } else {
    await locationApi.create(form)
  }
  ElMessage.success('保存成功')
  dialog.value = false
  loadData()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该位置？子级位置也将被删除。', '提示', { type: 'warning' })
  await locationApi.delete(id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>
