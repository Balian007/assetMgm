<template>
  <div class="ops-home">
    <div class="ops-card">
      <h1>移动作业入口</h1>
      <p class="subtitle">登录后请选择作业类型，再进行扫码操作</p>

      <div class="actions">
        <el-button type="primary" size="large" class="action-btn" @click="$router.push('/m/ops/inspection')">
          巡检打卡
        </el-button>
        <el-button size="large" class="action-btn" @click="$router.push('/m/ops/inventory')">
          盘点录入
        </el-button>
      </div>

      <div class="footer-row">
        <span>{{ welcomeText }}</span>
        <el-button link type="danger" @click="logout">退出登录</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

function decodeName(raw) {
  if (typeof raw !== 'string' || !raw) return ''
  const suspicious = /[ÃÂ脙脗]/.test(raw)
  if (!suspicious) return raw
  try {
    const decoded = decodeURIComponent(escape(raw))
    if (decoded) return decoded
  } catch {
    // fallback to raw text when decode fails
  }
  return raw
}

const welcomeText = computed(() => {
  const username = decodeName(userStore.userInfo?.username || '')
  const realName = decodeName(userStore.userInfo?.realName || '')
  const name = username || realName || '运维人员'
  return `当前用户名：${name}`
})

function logout() {
  userStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.ops-home {
  min-height: 100svh;
  display: grid;
  place-items: center;
  padding: 20px;
  background: linear-gradient(180deg, #f3f7ff, #e8effc);
}

.ops-card {
  width: min(100%, 420px);
  background: #fff;
  border: 1px solid #d6e3fa;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 12px 28px rgba(20, 40, 75, 0.12);
}

h1 {
  margin: 0;
  font-size: 22px;
  color: #1d3557;
}

.subtitle {
  margin: 8px 0 24px;
  color: #5d7397;
  font-size: 13px;
}

.actions {
  display: grid;
  gap: 16px;
}

.action-btn {
  margin-left: 0 !important;
  width: 100%;
  height: 48px;
  font-size: 16px;
  border-radius: 10px;
}

.actions :deep(.el-button + .el-button) {
  margin-left: 0;
}

.footer-row {
  margin-top: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: #6e83a7;
  font-size: 12px;
}
</style>
