<template>
  <div class="app-layout">
    <div v-if="isMobile && !collapsed" class="sidebar-mask" @click="closeSidebar"></div>

    <!-- 娓氀嗙珶閺?-->
    <aside class="sidebar" :class="{ collapsed }">
      <!-- Logo -->
      <div class="sidebar-logo">
        <div class="logo-mark">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <rect x="2" y="2" width="9" height="9" rx="2" fill="white" fill-opacity="0.9"/>
            <rect x="13" y="2" width="9" height="9" rx="2" fill="white" fill-opacity="0.5"/>
            <rect x="2" y="13" width="9" height="9" rx="2" fill="white" fill-opacity="0.5"/>
            <rect x="13" y="13" width="9" height="9" rx="2" fill="white" fill-opacity="0.9"/>
          </svg>
        </div>
        <transition name="fade">
          <span v-if="!collapsed" class="logo-title">资产管理系统</span>
        </transition>
      </div>

      <!-- 鐎佃壈鍩呴懣婊冨礋 -->
      <nav class="sidebar-nav">
        <!-- 閹槒顫?-->
        <router-link to="/dashboard" class="nav-item" :class="{ active: isActive('/dashboard') }" @click="handleNavClick">
          <span class="nav-icon"><IconDashboard /></span>
          <transition name="fade"><span v-if="!collapsed" class="nav-label">总览</span></transition>
          <span v-if="isActive('/dashboard')" class="active-bar"></span>
        </router-link>

        <!-- 鐎圭偟澧跨挧鍕獓 -->
        <div class="nav-group">
          <transition name="fade">
            <div v-if="!collapsed" class="nav-group-label">实物资产</div>
          </transition>
          <router-link v-for="item in physicalItems" :key="item.path"
            :to="item.path" class="nav-item" :class="{ active: isActive(item.path) }" @click="handleNavClick">
            <span class="nav-icon"><component :is="item.icon" /></span>
            <transition name="fade"><span v-if="!collapsed" class="nav-label">{{ item.label }}</span></transition>
            <span v-if="isActive(item.path)" class="active-bar"></span>
          </router-link>
        </div>

        <!-- 閺佹澘鐡х挧鍕獓 -->
        <div class="nav-group">
          <transition name="fade">
            <div v-if="!collapsed" class="nav-group-label">数字资产</div>
          </transition>
          <router-link to="/digital/assets" class="nav-item" :class="{ active: isActive('/digital/assets') }" @click="handleNavClick">
            <span class="nav-icon"><IconFiles /></span>
            <transition name="fade"><span v-if="!collapsed" class="nav-label">资产目录</span></transition>
            <span v-if="isActive('/digital/assets')" class="active-bar"></span>
          </router-link>
        </div>

        <!-- 缁狅紕鎮?-->
        <div class="nav-group">
          <transition name="fade">
            <div v-if="!collapsed" class="nav-group-label">管理</div>
          </transition>
          <router-link v-for="item in mgmtItems" :key="item.path"
            :to="item.path" class="nav-item" :class="{ active: isActive(item.path) }" @click="handleNavClick">
            <span class="nav-icon"><component :is="item.icon" /></span>
            <transition name="fade"><span v-if="!collapsed" class="nav-label">{{ item.label }}</span></transition>
            <span v-if="isActive(item.path)" class="active-bar"></span>
          </router-link>
        </div>

        <!-- 缁崵绮?-->
        <div class="nav-group">
          <transition name="fade">
            <div v-if="!collapsed" class="nav-group-label">系统</div>
          </transition>
          <router-link v-for="item in systemItems" :key="item.path"
            :to="item.path" class="nav-item" :class="{ active: isActive(item.path) }" @click="handleNavClick">
            <span class="nav-icon"><component :is="item.icon" /></span>
            <transition name="fade"><span v-if="!collapsed" class="nav-label">{{ item.label }}</span></transition>
            <span v-if="isActive(item.path)" class="active-bar"></span>
          </router-link>
        </div>
      </nav>

      <!-- 閹舵ê褰旈幐澶愭尦 -->
      <button class="collapse-btn" @click="collapsed = !collapsed" :title="collapsed ? '展开' : '收起'">
        <IconChevron :class="{ rotated: collapsed }" />
      </button>
    </aside>

    <!-- 娑撹灏崺?-->
    <div class="main-wrapper">
      <!-- 妞ゅ爼鍎?Header -->
      <header class="topbar">
        <div class="topbar-left">
          <button v-if="isMobile" class="mobile-menu-btn" @click="openSidebar" aria-label="打开菜单">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
          </button>
          <el-breadcrumb v-if="!isMobile" separator="/">
            <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="currentTitle">{{ currentTitle }}</el-breadcrumb-item>
          </el-breadcrumb>
          <span v-else class="mobile-title">{{ currentTitle || '首页' }}</span>
        </div>
        <div class="topbar-right">
          <el-dropdown @command="handleCommand" trigger="click">
            <div class="user-pill">
              <div class="user-avatar">{{ avatarText }}</div>
              <span class="user-name">{{ displayName }}</span>
              <svg class="chevron-icon" width="12" height="12" viewBox="0 0 12 12" fill="none">
                <path d="M2 4l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">
                  <el-icon><SwitchButton /></el-icon> 退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- 閸愬懎顔愰崠?-->
      <main class="page-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, defineComponent, h, watch, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { SwitchButton } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const collapsed = ref(false)
const isMobile = ref(false)

const IconDashboard = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('rect', { x: 3, y: 3, width: 7, height: 7, rx: 1.5, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('rect', { x: 14, y: 3, width: 7, height: 7, rx: 1.5, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('rect', { x: 3, y: 14, width: 7, height: 7, rx: 1.5, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('rect', { x: 14, y: 14, width: 7, height: 7, rx: 1.5, stroke: 'currentColor', 'stroke-width': 1.8 }),
]) })

const IconMonitor = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('rect', { x: 2, y: 3, width: 20, height: 14, rx: 2, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('path', { d: 'M8 21h8M12 17v4', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
]) })

const IconSearch = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('circle', { cx: 11, cy: 11, r: 7, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('path', { d: 'M16.5 16.5L21 21', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
]) })

const IconWrench = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
]) })

const IconClipboard = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
  h('rect', { x: 9, y: 3, width: 6, height: 4, rx: 1, stroke: 'currentColor', 'stroke-width': 1.8 }),
]) })

const IconFiles = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linejoin': 'round' }),
  h('path', { d: 'M13 2v7h7', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
]) })

const IconBriefcase = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('rect', { x: 2, y: 7, width: 20, height: 14, rx: 2, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('path', { d: 'M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
]) })

const IconChart = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M3 3v18h18', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
  h('path', { d: 'M7 16l4-4 4 4 4-6', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
]) })

const IconUsers = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
  h('circle', { cx: 9, cy: 7, r: 4, stroke: 'currentColor', 'stroke-width': 1.8 }),
  h('path', { d: 'M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round' }),
]) })

const IconShield = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
]) })

const IconMapPin = defineComponent({ render: () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none' }, [
  h('path', { d: 'M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z', stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
  h('circle', { cx: 12, cy: 10, r: 3, stroke: 'currentColor', 'stroke-width': 1.8 }),
]) })

const IconChevron = defineComponent({
  render: () => h('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none' }, [
    h('path', { d: 'M15 18l-6-6 6-6', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
  ])
})

const physicalItems = [
  { path: '/physical/assets', label: '设备台账', icon: IconMonitor },
  { path: '/physical/inspections', label: '巡检管理', icon: IconSearch },
  { path: '/physical/maintenance', label: '维修工单', icon: IconWrench },
  { path: '/physical/inventory', label: '资产盘点', icon: IconClipboard },
]

const mgmtItems = [
  { path: '/projects', label: '项目管理', icon: IconBriefcase },
  { path: '/report', label: '统计报表', icon: IconChart },
]

const systemItems = [
  { path: '/system/users', label: '用户管理', icon: IconUsers },
  { path: '/system/roles', label: '角色管理', icon: IconShield },
  { path: '/system/locations', label: '位置管理', icon: IconMapPin },
]

const routeTitleMap = {
  '/dashboard': '总览',
  '/physical/assets': '设备台账',
  '/physical/inspections': '巡检管理',
  '/physical/maintenance': '维修工单',
  '/physical/inventory': '资产盘点',
  '/digital/assets': '资产目录',
  '/projects': '项目管理',
  '/report': '统计报表',
  '/system/users': '用户管理',
  '/system/roles': '角色管理',
  '/system/locations': '位置管理',
}

const currentTitle = computed(() => route.meta?.title || routeTitleMap[route.path] || '')
const displayName = computed(() => {
  const username = userStore.userInfo.username || ''
  if (typeof username === 'string' && username) return username

  const raw = userStore.userInfo.realName || ''
  if (typeof raw !== 'string') return ''

  const suspicious = /[ÃÂ]/.test(raw)
  if (!suspicious) return raw

  try {
    const decoded = decodeURIComponent(escape(raw))
    if (decoded) return decoded
  } catch {
    // keep fallback
  }

  return raw
})

const avatarText = computed(() => {
  const name = displayName.value || ''
  return name.charAt(0).toUpperCase()
})

function handleCommand(cmd) {
  if (cmd === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}

function isActive(path) {
  return route.path === path || route.path.startsWith(`${path}/`)
}

function syncViewport() {
  const mobile = window.innerWidth <= 760
  isMobile.value = mobile
  if (mobile) {
    collapsed.value = true
  }
}

function openSidebar() {
  if (isMobile.value) {
    collapsed.value = false
  }
}

function closeSidebar() {
  if (isMobile.value) {
    collapsed.value = true
  }
}

function handleNavClick() {
  if (isMobile.value) {
    collapsed.value = true
  }
}

watch(
  () => route.path,
  () => {
    if (isMobile.value) {
      collapsed.value = true
    }
  }
)

onMounted(() => {
  syncViewport()
  window.addEventListener('resize', syncViewport)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', syncViewport)
})
</script>

<style scoped>
.app-layout {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background:
    radial-gradient(900px 420px at -12% -6%, rgba(63, 132, 255, 0.18), transparent 62%),
    radial-gradient(900px 520px at 110% 112%, rgba(27, 86, 202, 0.2), transparent 64%),
    var(--bg);
}

.sidebar-mask {
  position: fixed;
  inset: 0;
  background: rgba(8, 18, 34, 0.35);
  backdrop-filter: blur(2px);
  z-index: 35;
}

.sidebar {
  width: 220px;
  min-width: 220px;
  margin: 12px 0 12px 12px;
  border-radius: 12px;
  background: linear-gradient(180deg, #0f1c34, #0b1529 70%, #081122);
  border: 1px solid rgba(127, 157, 215, 0.2);
  box-shadow: 0 18px 36px rgba(2, 8, 21, 0.45);
  display: flex;
  flex-direction: column;
  transition: width .22s cubic-bezier(.4,0,.2,1), min-width .22s cubic-bezier(.4,0,.2,1);
  overflow: hidden;
  position: relative;
  z-index: 10;
}

.sidebar.collapsed {
  width: 60px;
  min-width: 60px;
}

.sidebar-logo {
  height: 56px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 16px;
  flex-shrink: 0;
  border-bottom: 1px solid rgba(127, 157, 215, 0.22);
}

.logo-mark {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: linear-gradient(135deg, #4d9cff, var(--primary));
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.logo-title {
  font-size: 13px;
  font-weight: 800;
  color: #d9e5fb;
  letter-spacing: .2px;
}

.sidebar-nav {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 8px 0;
}

.sidebar-nav::-webkit-scrollbar {
  width: 4px;
}

.sidebar-nav::-webkit-scrollbar-thumb {
  background: rgba(111, 137, 182, 0.44);
  border-radius: 999px;
}

.nav-group {
  margin-top: 4px;
}

.nav-group-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .35px;
  text-transform: uppercase;
  color: #7f94ba;
  padding: 10px 16px 4px;
  white-space: nowrap;
  overflow: hidden;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  padding: 0 12px;
  margin: 2px 10px;
  border-radius: 8px;
  text-decoration: none;
  color: #9eb2d2;
  font-size: 13px;
  font-weight: 600;
  position: relative;
  transition: color .15s, background .15s, transform .15s;
  white-space: nowrap;
  overflow: hidden;
}

.nav-item:hover {
  color: #d9e8ff;
  background: rgba(79, 125, 218, 0.22);
}

.nav-item.active {
  color: #fff !important;
  background: linear-gradient(135deg, #3f95ff, #2f7cf6);
  box-shadow: 0 8px 18px rgba(18, 95, 234, 0.45);
}

.nav-item.active .nav-label {
  color: #fff !important;
}

.nav-item.active .nav-icon {
  color: #fff;
}

.nav-icon {
  width: 15px;
  height: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #9eb2d2;
  transition: color .15s;
}

.nav-label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
}

.active-bar {
  position: absolute;
  right: 6px;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 14px;
  background: rgba(255, 255, 255, 0.88);
  border-radius: 999px;
}

.collapse-btn {
  height: 44px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: none;
  border: none;
  border-top: 1px solid rgba(127, 157, 215, 0.2);
  color: #8ea5cb;
  cursor: pointer;
  transition: color .15s, background .15s;
  flex-shrink: 0;
}

.collapse-btn:hover {
  color: #d9e8ff;
  background: rgba(79, 125, 218, 0.2);
}

.collapse-btn svg {
  transition: transform .22s cubic-bezier(.4,0,.2,1);
}

.collapse-btn svg.rotated {
  transform: rotate(180deg);
}

.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
}

.topbar {
  height: 56px;
  margin: 12px 12px 0 12px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.98);
  border: 1px solid rgba(196, 209, 231, 0.8);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 18px;
  flex-shrink: 0;
  box-shadow: 0 6px 18px rgba(18, 33, 63, 0.12);
  backdrop-filter: blur(6px);
}

.topbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
}

.mobile-menu-btn {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  border: 1px solid var(--line);
  color: #4f6a94;
  background: #f5f9ff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.mobile-title {
  font-size: 14px;
  font-weight: 700;
  color: #35537d;
}

.topbar-right {
  display: flex;
  align-items: center;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 5px 10px 5px 5px;
  border-radius: 999px;
  cursor: pointer;
  border: 1px solid var(--line);
  background: #f8fbff;
  transition: border-color .15s, background .15s;
}

.user-pill:hover {
  border-color: #bdd1f5;
  background: #f2f8ff;
}

.user-avatar {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3f8cff, var(--primary));
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.user-name {
  font-size: 12px;
  font-weight: 600;
  color: #476084;
}

.chevron-icon {
  color: #8da0bf;
}

.page-content {
  flex: 1;
  overflow: auto;
  margin: 12px;
  border-radius: 10px;
  padding: 16px;
  background: linear-gradient(180deg, #f8fbff, #eef4ff);
  border: 1px solid rgba(199, 212, 235, 0.86);
  box-shadow: 0 10px 24px rgba(18, 33, 63, 0.14);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity .15s, transform .15s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateX(-4px);
}

@media (max-width: 960px) {
  .sidebar {
    margin: 10px 0 10px 10px;
  }

  .topbar {
    margin: 10px 10px 0 10px;
  }

  .page-content {
    margin: 10px;
    padding: 14px;
  }
}

@media (max-width: 760px) {
  .sidebar {
    position: fixed;
    left: 10px;
    top: 10px;
    bottom: 10px;
    z-index: 40;
    margin: 0;
    width: 220px;
    min-width: 220px;
    transition: transform .2s ease;
  }

  .sidebar.collapsed {
    width: 220px;
    min-width: 220px;
    transform: translateX(calc(-100% - 12px));
  }

  .sidebar:not(.collapsed) {
    width: 220px;
    min-width: 220px;
    transform: translateX(0);
  }

  .main-wrapper {
    margin-left: 0;
  }

  .collapse-btn {
    display: none;
  }

  .topbar {
    height: 52px;
    padding: 0 12px;
  }

  .user-name {
    display: none;
  }
}

@media (max-width: 480px) {
  .topbar {
    margin: 8px 8px 0 8px;
    padding: 0 10px;
  }

  .mobile-title {
    max-width: 180px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .page-content {
    margin: 8px;
    padding: 10px;
  }
}
</style>
