<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">统计报表</h2>
      <el-button type="primary" plain @click="loadData">刷新数据</el-button>
    </div>

    <el-row :gutter="16" class="card-row">
      <el-col :xl="8" :lg="8" :md="12" :sm="12" :xs="24" v-for="item in statCards" :key="item.key">
        <div class="metric-card" :style="{ '--accent': item.color }">
          <div class="metric-top">
            <span class="metric-label">{{ item.label }}</span>
            <span class="metric-dot"></span>
          </div>
          <div class="metric-value">{{ stats[item.key] ?? 0 }}</div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <el-col :xl="12" :lg="12" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" class="chart-card">
          <template #header>
            <div class="card-header-row">
              <span>实物资产状态占比</span>
              <span class="card-subtitle">环图</span>
            </div>
          </template>

          <div v-if="statusChartData.length" class="status-panel">
            <SimpleDonutChart
              :items="statusDonutItems"
              :size="donutSize"
              center-label="实物资产"
            />
            <div class="status-legend">
              <div v-for="item in statusChartData" :key="item.status" class="legend-row">
                <div class="legend-left">
                  <span class="legend-dot" :style="{ background: statusColor(item.status) }"></span>
                  <span class="legend-name">{{ statusLabel(item.status) }}</span>
                </div>
                <div class="legend-right">
                  <span class="legend-count">{{ item.count }}</span>
                  <span class="legend-pct">{{ item.pct }}%</span>
                </div>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无数据" :image-size="60" />
        </el-card>
      </el-col>

      <el-col :xl="12" :lg="12" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" class="chart-card">
          <template #header>
            <div class="card-header-row">
              <span>核心指标对比</span>
              <span class="card-subtitle">柱图</span>
            </div>
          </template>
          <SimpleBarChart :items="kpiChartItems" />
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="bottom-row">
      <el-col :xl="24" :lg="24" :md="24" :sm="24" :xs="24">
        <el-card shadow="never" class="chart-card">
          <template #header>
            <div class="card-header-row">
              <span>待办事项分布</span>
              <span class="card-subtitle">任务负载图</span>
            </div>
          </template>
          <SimpleBarChart :items="todoChartItems" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { reportApi } from '@/api/system'
import SimpleDonutChart from '@/components/charts/SimpleDonutChart.vue'
import SimpleBarChart from '@/components/charts/SimpleBarChart.vue'

const stats = ref({})
const viewportWidth = ref(typeof window === 'undefined' ? 1200 : window.innerWidth)

const statCards = [
  { key: 'physicalTotal', label: '实物资产总数', color: '#4f46e5' },
  { key: 'digitalTotal', label: '数字资产总数', color: '#0891b2' },
  { key: 'activeProjects', label: '进行中项目', color: '#059669' },
  { key: 'pendingInspections', label: '待巡检任务', color: '#f59e0b' },
  { key: 'pendingMaintenance', label: '待维修工单', color: '#ef4444' },
  { key: 'warrantyExpiringSoon', label: '保修即将到期', color: '#f97316' }
]

const statusChartData = computed(() => {
  const byStatus = stats.value.physicalByStatus || {}
  const total = Object.values(byStatus).reduce((a, b) => a + b, 0)
  if (!total) return []
  return Object.entries(byStatus).map(([status, count]) => ({
    status,
    count,
    pct: Math.round((count / total) * 100)
  }))
})

const statusDonutItems = computed(() =>
  statusChartData.value.map(item => ({
    key: item.status,
    label: statusLabel(item.status),
    value: item.count,
    color: statusColor(item.status)
  }))
)

const kpiChartItems = computed(() => [
  { key: 'physicalTotal', label: '实物资产', value: Number(stats.value.physicalTotal || 0), color: '#4f46e5' },
  { key: 'digitalTotal', label: '数字资产', value: Number(stats.value.digitalTotal || 0), color: '#0891b2' },
  { key: 'activeProjects', label: '进行中项目', value: Number(stats.value.activeProjects || 0), color: '#059669' },
  { key: 'warrantyExpiringSoon', label: '保修到期', value: Number(stats.value.warrantyExpiringSoon || 0), color: '#f97316' }
])

const todoChartItems = computed(() => [
  { key: 'pendingInspections', label: '待处理巡检任务', value: Number(stats.value.pendingInspections || 0), color: '#f59e0b' },
  { key: 'pendingMaintenance', label: '待处理维修工单', value: Number(stats.value.pendingMaintenance || 0), color: '#ef4444' },
  { key: 'warrantyExpiringSoon', label: '30天内保修到期', value: Number(stats.value.warrantyExpiringSoon || 0), color: '#f97316' },
  { key: 'activeProjects', label: '进行中项目', value: Number(stats.value.activeProjects || 0), color: '#4f46e5' }
])

const donutSize = computed(() => {
  if (viewportWidth.value <= 420) return 156
  if (viewportWidth.value <= 760) return 176
  return 220
})

const statusLabel = s => ({
  IN_USE: '使用中',
  IDLE: '闲置',
  MAINTENANCE: '维修中',
  SCRAPPED: '已报废',
  TRANSFERRED: '已调拨'
}[s] || s)

const statusColor = s => ({
  IN_USE: '#67c23a',
  IDLE: '#909399',
  MAINTENANCE: '#e6a23c',
  SCRAPPED: '#f56c6c',
  TRANSFERRED: '#409eff'
}[s] || '#409eff')

async function loadData() {
  const res = await reportApi.dashboard()
  stats.value = res.data || {}
}

function syncViewport() {
  viewportWidth.value = window.innerWidth
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', syncViewport)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', syncViewport)
})
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  color: #2b4265;
  font-weight: 800;
}

.card-row {
  margin-bottom: 14px;
}

.metric-card {
  border: 1px solid #e2eaf7;
  border-radius: 12px;
  background: linear-gradient(180deg, #ffffff, #f7faff);
  padding: 14px 14px 12px;
  box-shadow: 0 4px 12px rgba(18, 53, 104, 0.07);
  margin-bottom: 12px;
}

.metric-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metric-label {
  font-size: 13px;
  color: #6f84a7;
}

.metric-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--accent);
  box-shadow: 0 0 0 4px color-mix(in srgb, var(--accent) 18%, transparent);
}

.metric-value {
  margin-top: 8px;
  font-size: 30px;
  line-height: 1;
  font-weight: 800;
  color: #2e4a73;
}

.chart-card {
  margin-bottom: 12px;
}

.bottom-row {
  margin-top: 2px;
}

.card-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-subtitle {
  font-size: 12px;
  color: #8aa0c2;
  font-weight: 500;
}

.status-panel {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: 14px;
  align-items: center;
}

.status-legend {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.legend-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 10px;
  border-radius: 8px;
  background: #f7faff;
}

.legend-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.legend-name {
  font-size: 13px;
  color: #567093;
}

.legend-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.legend-count {
  font-size: 14px;
  font-weight: 700;
  color: #304d77;
}

.legend-pct {
  min-width: 38px;
  font-size: 12px;
  color: #7b90b2;
  text-align: right;
}

@media (max-width: 980px) {
  .status-panel {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 760px) {
  .metric-card {
    padding: 12px;
  }

  .metric-value {
    font-size: 24px;
  }

  .card-header-row {
    align-items: flex-start;
    gap: 4px;
  }

  .legend-row {
    gap: 8px;
  }

  .legend-name {
    font-size: 12px;
  }

  .legend-right {
    gap: 6px;
  }
}
</style>
