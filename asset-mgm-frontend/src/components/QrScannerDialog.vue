<template>
  <el-dialog
    :model-value="modelValue"
    title="手机扫码识别"
    width="420px"
    destroy-on-close
    @close="closeDialog"
  >
    <div class="scanner-wrap">
      <div :id="scannerElementId" class="scanner-region"></div>
      <p class="scanner-tip">将设备二维码放入取景框，识别后自动回填。</p>
      <el-alert
        v-if="errorText"
        :title="errorText"
        type="warning"
        :closable="false"
        show-icon
      />
      <el-input
        v-model="manualText"
        placeholder="摄像头不可用时可手动输入二维码内容"
        clearable
      >
        <template #append>
          <el-button @click="submitManual">使用</el-button>
        </template>
      </el-input>
    </div>
    <template #footer>
      <el-button @click="closeDialog">取消</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { Html5Qrcode } from 'html5-qrcode'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'scanned'])

const scannerElementId = `asset-qr-scanner-${Math.random().toString(36).slice(2, 8)}`
const scannerInstance = ref(null)
const scanning = ref(false)
const manualText = ref('')
const errorText = ref('')

watch(
  () => props.modelValue,
  async (visible) => {
    if (visible) {
      await startScanner()
    } else {
      await stopScanner()
    }
  }
)

async function startScanner() {
  await nextTick()
  errorText.value = ''

  try {
    scannerInstance.value = new Html5Qrcode(scannerElementId)

    const config = {
      fps: 10,
      qrbox: { width: 220, height: 220 },
      aspectRatio: 1.0
    }

    await scannerInstance.value.start(
      { facingMode: "environment" },
      config,
      async (decodedText) => {
        emit('scanned', decodedText)
        await closeDialog()
      },
      () => {}
    )
    scanning.value = true
  } catch (err) {
    console.error('Scanner error:', err)
    errorText.value = '摄像头启动失败。请确保：1) 使用HTTPS访问 2) 已授权摄像头权限 3) 或手动输入二维码'
    await stopScanner()
  }
}

async function stopScanner() {
  if (!scannerInstance.value) return

  try {
    if (scanning.value) {
      await scannerInstance.value.stop()
    }
  } catch {
    // ignore
  }

  try {
    await scannerInstance.value.clear()
  } catch {
    // ignore
  }

  scannerInstance.value = null
  scanning.value = false
}

async function closeDialog() {
  await stopScanner()
  emit('update:modelValue', false)
}

function submitManual() {
  const text = manualText.value.trim()
  if (!text) return
  emit('scanned', text)
  closeDialog()
}

onBeforeUnmount(() => {
  stopScanner()
})
</script>

<style scoped>
.scanner-wrap {
  display: grid;
  gap: 12px;
}

.scanner-region {
  width: 100%;
  min-height: 280px;
  border: 1px dashed var(--el-border-color);
  border-radius: 8px;
  overflow: hidden;
}

.scanner-tip {
  margin: 0;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
</style>
