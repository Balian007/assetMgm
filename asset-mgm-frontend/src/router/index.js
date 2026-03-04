import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'

const routes = [
  { path: '/login', component: () => import('@/views/Login.vue'), meta: { public: true } },

  // 移动作业专属入口
  { path: '/m/ops', component: () => import('@/views/mobile/OpsHome.vue'), meta: { title: '移动作业' } },
  { path: '/m/ops/inspection', component: () => import('@/views/mobile/OpsInspection.vue'), meta: { title: '巡检扫码打卡' } },
  { path: '/m/ops/inventory', component: () => import('@/views/mobile/OpsInventory.vue'), meta: { title: '盘点扫码录入' } },

  {
    path: '/',
    component: () => import('@/components/Layout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('@/views/dashboard/Index.vue'), meta: { title: '总览' } },
      // 实物资产
      { path: 'physical/assets', component: () => import('@/views/physical/AssetList.vue'), meta: { title: '设备台账' } },
      { path: 'physical/assets/:id', component: () => import('@/views/physical/AssetDetail.vue'), meta: { title: '设备详情' } },
      { path: 'physical/inspections', component: () => import('@/views/physical/InspectionList.vue'), meta: { title: '巡检管理' } },
      { path: 'physical/maintenance', component: () => import('@/views/physical/MaintenanceList.vue'), meta: { title: '维修工单' } },
      { path: 'physical/inventory', component: () => import('@/views/physical/InventoryList.vue'), meta: { title: '资产盘点' } },
      // 数字资产
      { path: 'digital/assets', component: () => import('@/views/digital/AssetList.vue'), meta: { title: '数字资产' } },
      { path: 'digital/assets/:id', component: () => import('@/views/digital/AssetDetail.vue'), meta: { title: '资产详情' } },
      // 项目管理
      { path: 'projects', component: () => import('@/views/project/ProjectList.vue'), meta: { title: '项目管理' } },
      { path: 'projects/:id', component: () => import('@/views/project/ProjectDetail.vue'), meta: { title: '项目详情' } },
      // 报表
      { path: 'report', component: () => import('@/views/report/Index.vue'), meta: { title: '统计报表' } },
      // 系统管理
      { path: 'system/users', component: () => import('@/views/system/UserList.vue'), meta: { title: '用户管理' } },
      { path: 'system/roles', component: () => import('@/views/system/RoleList.vue'), meta: { title: '角色管理' } },
      { path: 'system/locations', component: () => import('@/views/system/LocationList.vue'), meta: { title: '位置管理' } }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const userStore = useUserStore()
  if (!to.meta.public && !userStore.token) {
    return `/login?redirect=${encodeURIComponent(to.fullPath)}`
  }
})

export default router
