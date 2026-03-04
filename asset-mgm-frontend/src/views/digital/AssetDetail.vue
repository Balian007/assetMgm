<template>
  <div>
    <el-page-header @back="$router.back()" :content="asset.assetName || '数字资产详情'" class="mb-4" />

    <el-row :gutter="16" v-loading="loading">
      <el-col :xl="16" :lg="16" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" header="基本信息" class="mb-4">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="资产编号">{{ asset.assetNo }}</el-descriptions-item>
            <el-descriptions-item label="资产名称">{{ asset.assetName }}</el-descriptions-item>
            <el-descriptions-item label="数据类型">
              <el-tag size="small">{{ asset.dataType === 'STRUCTURED' ? '结构化' : '非结构化' }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="数据分级">
              <el-tag :type="levelType(asset.dataLevel)" size="small">{{ levelLabel(asset.dataLevel) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="存储类型">{{ asset.storageType || '-' }}</el-descriptions-item>
            <el-descriptions-item label="存储路径">{{ asset.storagePath || '-' }}</el-descriptions-item>
            <el-descriptions-item label="数据量">{{ asset.dataSize || '-' }}</el-descriptions-item>
            <el-descriptions-item label="质量评分">
              <el-rate v-if="asset.qualityScore" :model-value="asset.qualityScore / 20" disabled show-score
                score-template="{value}" />
              <span v-else>-</span>
            </el-descriptions-item>
            <el-descriptions-item label="负责人">{{ asset.ownerName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="所属项目">{{ asset.projectName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">{{ asset.description || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>

        <el-card shadow="never" header="标签" v-if="tags.length">
          <el-tag v-for="tag in tags" :key="tag" class="mr-2 mb-2">{{ tag }}</el-tag>
        </el-card>
      </el-col>

      <el-col :xl="8" :lg="8" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" header="访问授权" class="mb-4">
          <el-empty description="暂无授权记录" :image-size="60" />
        </el-card>

        <el-card shadow="never" header="数据血缘">
          <el-empty description="暂无血缘关系" :image-size="60" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { digitalAssetApi } from '@/api/digital'

const route = useRoute()
const loading = ref(false)
const asset = ref({})

const tags = computed(() => {
  try { return JSON.parse(asset.value.tags || '[]') } catch { return [] }
})

const levelLabel = l => ({ PUBLIC: '公开', INTERNAL: '内部', CONFIDENTIAL: '机密', SECRET: '秘密' }[l] || l)
const levelType = l => ({ PUBLIC: '', INTERNAL: 'info', CONFIDENTIAL: 'warning', SECRET: 'danger' }[l] || '')

async function loadData() {
  loading.value = true
  try {
    const res = await digitalAssetApi.getById(route.params.id)
    asset.value = res.data || {}
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
@media (max-width: 760px) {
  :deep(.el-page-header__content) {
    font-size: 14px;
  }

  :deep(.el-descriptions__label),
  :deep(.el-descriptions__content) {
    font-size: 12px;
  }
}
</style>
