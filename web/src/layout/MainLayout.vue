<template>
  <div class="layout">
    <div v-if="isMobile && mobileMenuOpen" class="mobile-mask" @click="mobileMenuOpen = false"></div>

    <aside class="sidebar" :class="{ collapsed: collapsed && !isMobile, 'mobile-open': isMobile && mobileMenuOpen }">
      <div class="logo">
        <BrandLogo
          :mode="collapsed && !isMobile ? 'symbol' : 'full'"
          :symbol-size="collapsed && !isMobile ? 34 : 36"
        />
      </div>
      <el-scrollbar>
        <el-menu
          :default-active="activeMenu"
          :collapse="collapsed && !isMobile"
          router
          background-color="#ffffff"
          text-color="#606266"
          active-text-color="#1677ff"
          @select="onMenuSelect"
        >
          <el-menu-item index="/dashboard">
            <el-icon><Monitor /></el-icon>
            <template #title>系统概况</template>
          </el-menu-item>

          <el-sub-menu index="network-settings">
            <template #title><el-icon><Connection /></el-icon><span>网络设置</span></template>
            <el-menu-item index="/network/quick-setup">内外网设置</el-menu-item>
            <el-menu-item index="/multiwan/dial-instances">宽带线路</el-menu-item>
            <el-menu-item index="/network/lan">局域网设置</el-menu-item>
            <el-menu-item index="/network/dhcp-dns">DHCP/DNS</el-menu-item>
          </el-sub-menu>

          <el-sub-menu index="traffic-control">
            <template #title><el-icon><Share /></el-icon><span>流控分流</span></template>
            <el-menu-item index="/multiwan/aggregation-groups">双栈线路汇聚</el-menu-item>
            <el-menu-item index="/multiwan/adaptive-scheduling">智能线路调度</el-menu-item>
            <el-menu-item index="/multiwan/line-status">线路监控</el-menu-item>
          </el-sub-menu>

          <el-menu-item index="/traffic/overview">
            <el-icon><TrendCharts /></el-icon>
            <template #title>流量分析</template>
          </el-menu-item>

          <el-sub-menu index="security-settings">
            <template #title><el-icon><Lock /></el-icon><span>安全设置</span></template>
            <el-menu-item index="/firewall/port-forward">端口映射</el-menu-item>
            <el-menu-item index="/firewall/dmz">DMZ</el-menu-item>
            <el-menu-item index="/services/upnp">UPnP</el-menu-item>
            <el-menu-item index="/firewall/zones">防火墙</el-menu-item>
          </el-sub-menu>

          <el-menu-item index="/system/settings">
            <el-icon><Setting /></el-icon>
            <template #title>系统设置</template>
          </el-menu-item>

          <el-sub-menu index="advanced-settings">
            <template #title><el-icon><Tools /></el-icon><span>高级设置</span></template>
            <el-menu-item index="/network/physical-ports">物理网口</el-menu-item>
            <el-menu-item index="/network/devices">网络设备</el-menu-item>
            <el-menu-item index="/network/interfaces">网络接口</el-menu-item>
            <el-menu-item index="/network/wan">WAN管理</el-menu-item>
            <el-menu-item index="/network/ipv6">IPv6管理</el-menu-item>
            <el-menu-item index="/network/static-routes">静态路由</el-menu-item>
            <el-menu-item index="/network/routing-rules">路由规则</el-menu-item>
            <el-menu-item index="/multiwan/lines">线路管理</el-menu-item>
            <el-menu-item index="/multiwan/load-balance">负载均衡</el-menu-item>
            <el-menu-item index="/multiwan/health-check">健康检查</el-menu-item>
            <el-menu-item index="/multiwan/failover">故障切换</el-menu-item>
          </el-sub-menu>
        </el-menu>
      </el-scrollbar>
    </aside>

    <div class="main-area">
      <header class="topbar">
        <div class="topbar-left">
          <el-icon class="collapse-btn" @click="isMobile ? (mobileMenuOpen = !mobileMenuOpen) : (collapsed = !collapsed)">
            <Fold v-if="!collapsed && !mobileMenuOpen" /><Expand v-else />
          </el-icon>
          <el-breadcrumb separator="/" v-if="!isMobile">
            <el-breadcrumb-item>{{ currentGroup }}</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentName }}</el-breadcrumb-item>
          </el-breadcrumb>
          <span v-else class="mobile-title">{{ currentName }}</span>
        </div>
        <div class="topbar-right">
          <el-tag type="success" size="small">演示模式</el-tag>
          <el-tag type="info" size="small" v-if="!isMobile">OpenWrt x86_64</el-tag>
          <span class="hostname" v-if="!isMobile">{{ BRAND.gatewayName }}</span>
        </div>
      </header>
      <AppContent>
        <router-view />
      </AppContent>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import AppContent from '../components/AppContent.vue'
import BrandLogo from '../components/brand/BrandLogo.vue'
import BRAND from '../config/brand.js'

const route = useRoute()
const collapsed = ref(false)
const isMobile = ref(false)
const mobileMenuOpen = ref(false)

function checkMobile() {
  isMobile.value = window.innerWidth < 768
  if (!isMobile.value) mobileMenuOpen.value = false
}
onMounted(() => { checkMobile(); window.addEventListener('resize', checkMobile) })
onUnmounted(() => window.removeEventListener('resize', checkMobile))

const activeMenu = computed(() => route.path)
const currentName = computed(() => route.name || '')

const groupByPath = {
  '/dashboard': '系统概况',
  '/network/quick-setup': '网络设置',
  '/multiwan/dial-instances': '网络设置',
  '/network/lan': '网络设置',
  '/network/dhcp-dns': '网络设置',
  '/multiwan/aggregation-groups': '流控分流',
  '/multiwan/adaptive-scheduling': '流控分流',
  '/multiwan/policy-routing': '流控分流',
  '/multiwan/line-status': '流控分流',
  '/traffic/overview': '流量分析',
  '/firewall/port-forward': '安全设置',
  '/firewall/dmz': '安全设置',
  '/services/upnp': '安全设置',
  '/firewall/zones': '安全设置',
  '/system/settings': '系统设置',
}
const currentGroup = computed(() => {
  if (groupByPath[route.path]) return groupByPath[route.path]
  const seg = route.path.split('/')[1]
  if (seg === 'traffic') return '流量分析'
  if (['firewall', 'services'].includes(seg)) return '安全设置'
  if (seg === 'system') return '系统设置'
  return '高级设置'
})

function onMenuSelect() {
  if (isMobile.value) mobileMenuOpen.value = false
}
</script>

<style scoped>
.layout { display: flex; width: 100%; min-width: 0; height: 100vh; height: 100dvh; overflow: hidden; }
.sidebar {
  width: var(--layout-sidebar-width); background: #fff; border-right: 1px solid var(--lh-border);
  display: flex; flex-direction: column; transition: width 0.2s, transform 0.25s; flex-shrink: 0; z-index: 100;
}
.sidebar.collapsed { width: 64px; }
.logo {
  height: var(--layout-header-height); display: flex; align-items: center; justify-content: center;
  padding: 0 14px; border-bottom: 1px solid var(--lh-border); flex-shrink: 0; overflow: hidden;
}
.sidebar.collapsed .logo { padding: 0; }
.logo :deep(.brand-logo) { max-width: 100%; }
.main-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; min-width: 0; }
.topbar {
  height: var(--layout-header-height); background: #fff; border-bottom: 1px solid var(--lh-border);
  display: flex; align-items: center; justify-content: space-between; padding: 0 20px; flex-shrink: 0;
}
.topbar-left { display: flex; align-items: center; gap: 16px; min-width: 0; }
.topbar-right { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.collapse-btn { cursor: pointer; font-size: 18px; flex-shrink: 0; }
.mobile-title { font-size: 15px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.hostname { font-size: 13px; color: var(--lh-text-secondary); }
.mobile-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.4); z-index: 99; }
@media (max-width: 767px) {
  .sidebar {
    position: fixed; top: 0; left: 0; bottom: 0; width: 260px;
    transform: translateX(-100%); box-shadow: 2px 0 12px rgba(0,0,0,0.15);
  }
  .sidebar.mobile-open { transform: translateX(0); }
  .topbar { padding: 0 12px; }
}
</style>
