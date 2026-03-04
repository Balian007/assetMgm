<template>
  <div class="bar-list">
    <div v-for="item in normalizedItems" :key="item.key" class="bar-row">
      <div class="bar-head">
        <span class="bar-label">{{ item.label }}</span>
        <span class="bar-value">{{ item.value }}</span>
      </div>
      <div class="bar-track">
        <div class="bar-fill" :style="{ width: `${item.pct}%`, background: item.color }"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  items: { type: Array, default: () => [] }
})

const maxValue = computed(() => {
  const values = (props.items || []).map(item => Number(item?.value || 0))
  const max = Math.max(...values, 0)
  return max > 0 ? max : 1
})

const normalizedItems = computed(() =>
  (props.items || []).map((item, idx) => {
    const value = Number(item?.value || 0)
    return {
      key: item?.key || item?.label || `bar-${idx}`,
      label: item?.label || '-',
      value,
      color: item?.color || '#3b82f6',
      pct: Math.round((value / maxValue.value) * 100)
    }
  })
)
</script>

<style scoped>
.bar-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.bar-row {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.bar-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.bar-label {
  font-size: 13px;
  color: #566d90;
}

.bar-value {
  font-size: 13px;
  font-weight: 700;
  color: #2f4a72;
}

.bar-track {
  height: 8px;
  border-radius: 999px;
  background: #eaf0f9;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.35s ease;
}
</style>
