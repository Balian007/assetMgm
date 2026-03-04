<template>
  <div class="donut-wrap">
    <svg :width="size" :height="size" :viewBox="`0 0 ${size} ${size}`" class="donut-svg">
      <circle
        class="donut-track"
        :cx="center"
        :cy="center"
        :r="radius"
        :stroke-width="strokeWidth"
      />
      <circle
        v-for="segment in segments"
        :key="segment.key"
        class="donut-segment"
        :cx="center"
        :cy="center"
        :r="radius"
        :stroke="segment.color"
        :stroke-width="strokeWidth"
        :stroke-dasharray="`${segment.length} ${circumference - segment.length}`"
        :stroke-dashoffset="`${-segment.offset}`"
        :transform="`rotate(-90 ${center} ${center})`"
      />
    </svg>

    <div class="donut-center">
      <div class="donut-total">{{ total }}</div>
      <div class="donut-label">{{ total > 0 ? centerLabel : emptyLabel }}</div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  items: { type: Array, default: () => [] },
  size: { type: Number, default: 220 },
  strokeWidth: { type: Number, default: 22 },
  centerLabel: { type: String, default: '总量' },
  emptyLabel: { type: String, default: '暂无数据' }
})

const center = computed(() => props.size / 2)
const radius = computed(() => (props.size - props.strokeWidth) / 2)
const circumference = computed(() => 2 * Math.PI * radius.value)

const validItems = computed(() =>
  (props.items || []).filter(item => Number(item?.value || 0) > 0)
)

const total = computed(() =>
  validItems.value.reduce((sum, item) => sum + Number(item.value || 0), 0)
)

const segments = computed(() => {
  if (!total.value) return []
  let offset = 0
  return validItems.value.map((item, idx) => {
    const value = Number(item.value || 0)
    const length = (value / total.value) * circumference.value
    const segment = {
      key: item.key || item.label || `seg-${idx}`,
      color: item.color || '#3b82f6',
      length,
      offset
    }
    offset += length
    return segment
  })
})
</script>

<style scoped>
.donut-wrap {
  position: relative;
  width: fit-content;
  margin: 0 auto;
}

.donut-svg {
  display: block;
}

.donut-track {
  fill: none;
  stroke: #e8eef8;
}

.donut-segment {
  fill: none;
  stroke-linecap: butt;
  transition: stroke-dasharray 0.35s ease;
}

.donut-center {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.donut-total {
  font-size: 30px;
  line-height: 1;
  font-weight: 800;
  color: #2b4265;
}

.donut-label {
  margin-top: 6px;
  font-size: 12px;
  color: #7b8ea9;
}
</style>
