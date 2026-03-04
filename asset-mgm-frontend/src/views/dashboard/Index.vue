<template>
  <div>
    <div class="page-header">
      <h2 class="page-title">总览</h2>
      <span class="page-date">{{ today }}</span>
    </div>

    <el-row :gutter="16" class="stat-row">
      <el-col :xl="6" :lg="6" :md="12" :sm="12" :xs="24" v-for="item in statCards" :key="item.key">
        <div class="stat-card" :style="{ '--accent': item.color }">
          <div class="stat-icon">
            <el-icon :size="22"><component :is="item.icon" /></el-icon>
          </div>
          <div class="stat-body">
            <div class="stat-value">{{ stats[item.key] ?? 0 }}</div>
            <div class="stat-label">{{ item.label }}</div>
          </div>
          <div class="stat-bg-icon">
            <el-icon :size="64"><component :is="item.icon" /></el-icon>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <el-col :xl="14" :lg="14" :md="24" :sm="24" :xs="24">
        <el-card shadow="never">
          <template #header>
            <div class="card-header-row">
              <span>实物资产状态分布</span>
              <span class="card-subtitle">环形占比图</span>
            </div>
          </template>
          <div v-if="statusChartData.length" class="status-panel">
            <SimpleDonutChart
              :items="statusDonutItems"
              :size="donutSize"
              center-label="资产总量"
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

      <el-col :xl="10" :lg="10" :md="24" :sm="24" :xs="24">
        <el-card shadow="never">
          <template #header>
            <div class="card-header-row">
              <span>待办负载分布</span>
              <span class="card-subtitle">任务对比图</span>
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

const today = new Date().toLocaleDateString('zh-CN', {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
  weekday: 'long'
})

const statCards = [
  { key: 'physicalTotal', label: '实物资产总数', icon: 'Monitor', color: '#4f46e5' },
  { key: 'digitalTotal', label: '数字资产总数', icon: 'Files', color: '#0891b2' },
  { key: 'activeProjects', label: '进行中项目', icon: 'Briefcase', color: '#059669' },
  { key: 'pendingMaintenance', label: '待处理工单', icon: 'Warning', color: '#dc2626' },
]

const todoItems = [
  { key: 'pendingInspections', label: '待处理巡检任务', color: '#f59e0b' },
  { key: 'pendingMaintenance', label: '待处理维修工单', color: '#ef4444' },
  { key: 'warrantyExpiringSoon', label: '30天内保修到期', color: '#f97316' },
  { key: 'activeProjects', label: '进行中项目', color: '#4f46e5' },
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

const todoChartItems = computed(() =>
  todoItems.map(item => ({
    key: item.key,
    label: item.label,
    value: Number(stats.value[item.key] || 0),
    color: item.color
  }))
)

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
  IN_USE: '#10b981',
  IDLE: '#6366f1',
  MAINTENANCE: '#f59e0b',
  SCRAPPED: '#ef4444',
  TRANSFERRED: '#3b82f6'
}[s] || '#6366f1')

async function loadData() {
  try {
    const res = await reportApi.dashboard()
    stats.value = res.data || {}
  } catch {}
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
  margin-bottom: 18px;
}

.page-title {
  font-size: 22px;
  font-weight: 800;
  color: #2c4468;
  margin: 0;
}

.page-date {
  font-size: 13px;
  color: #7a8ca9;
}

.stat-row {
  margin-bottom: 20px;
}

.stat-card {
  background: #fff;
  border: 1px solid #e5ebf5;
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  position: relative;
  overflow: hidden;
  box-shadow: 0 4px 14px rgba(29, 67, 124, 0.07);
  transition: transform .2s, box-shadow .2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 22px rgba(29, 67, 124, 0.12);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--accent) 16%, #fff);
  color: var(--accent);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-body {
  flex: 1;
}

.stat-value {
  font-size: 30px;
  font-weight: 800;
  color: #2a4367;
  line-height: 1;
  letter-spacing: .3px;
}

.stat-label {
  font-size: 12px;
  color: #7b8da9;
  margin-top: 5px;
}

.stat-bg-icon {
  position: absolute;
  right: -8px;
  bottom: -8px;
  color: color-mix(in srgb, var(--accent) 10%, transparent);
  pointer-events: none;
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
  :deep(.el-col) {
    margin-bottom: 12px;
  }

  .status-panel {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 760px) {
  .page-date {
    width: 100%;
    font-size: 12px;
  }

  .stat-card {
    padding: 14px;
    gap: 12px;
  }

  .stat-value {
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
