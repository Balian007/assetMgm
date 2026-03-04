<template>
  <div class="login-page">
    <div class="login-card">
      <h1>资产管理系统</h1>
      <p class="sub">登录后可进入移动作业入口进行巡检或盘点扫码。</p>

      <el-form :model="form" :rules="rules" ref="formRef" @submit.prevent="handleLogin">
        <el-form-item prop="username">
          <el-input
            v-model="form.username"
            placeholder="用户名"
            size="large"
            :prefix-icon="User"
          />
        </el-form-item>
        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            size="large"
            :prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        <el-button type="primary" native-type="submit" size="large" :loading="loading" class="login-btn">
          登录
        </el-button>
      </el-form>

      <div class="hint">默认账号：admin / Admin@123</div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { authApi } from '@/api/system/index'
import { User, Lock } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const formRef = ref()
const loading = ref(false)
const form = ref({ username: '', password: '' })

const rules = {
  username: [{ required: true, message: '请输入用户名' }],
  password: [{ required: true, message: '请输入密码' }]
}

async function handleLogin() {
  await formRef.value.validate()
  loading.value = true
  try {
    const res = await authApi.login(form.value)
    userStore.setToken(res.data.token)
    userStore.setUserInfo({ userId: res.data.userId, username: res.data.username, realName: res.data.realName })
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    router.push(redirect)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100svh;
  display: grid;
  place-items: center;
  padding: 16px;
  background: linear-gradient(180deg, #f3f8ff, #e9f0ff);
}

.login-card {
  width: min(100%, 380px);
  background: #fff;
  border: 1px solid #d7e3f8;
  border-radius: 14px;
  padding: 22px;
  box-shadow: 0 14px 30px rgba(21, 40, 73, 0.14);
}

h1 {
  margin: 0;
  font-size: 24px;
  color: #1f3556;
}

.sub {
  margin: 8px 0 18px;
  color: #6d81a4;
  font-size: 13px;
  line-height: 1.6;
}

.login-btn {
  width: 100%;
  height: 44px;
  margin-top: 4px;
  border-radius: 10px;
}

.hint {
  margin-top: 12px;
  text-align: center;
  color: #7489ad;
  font-size: 12px;
}
</style>
