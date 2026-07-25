import { createRouter, createWebHashHistory } from 'vue-router'
import BRAND from '../config/brand.js'

const routes = [
  {
    path: '/installer-preview',
    name: `${BRAND.installerName}预览`,
    component: () => import('../views/installer/InstallerPreview.vue'),
  },
  {
    path: '/',
    component: () => import('../layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      // ===== 运行状态 =====
      { path: '/dashboard', name: '系统概览', component: () => import('../views/monitor/Overview.vue') },
      { path: '/status/lines', name: '线路概览', component: () => import('../views/status/LineOverview.vue') },
      { path: '/status/aggregation-groups', name: '汇聚组状态', component: () => import('../views/status/GroupStatus.vue') },
      { path: '/monitor/realtime', name: '实时流量', component: () => import('../views/monitor/Realtime.vue') },
      { path: '/monitor/syslog', name: '系统日志', component: () => import('../views/monitor/Syslog.vue') },
      { path: '/traffic/overview', name: '流量总览', component: () => import('../views/traffic/Overview.vue') },
      { path: '/traffic/geo', name: '地域分析', component: () => import('../views/traffic/GeoAnalysis.vue') },
      { path: '/traffic/carriers', name: '运营商分析', component: () => import('../views/traffic/CarrierAnalysis.vue') },
      { path: '/traffic/lines', name: '线路利用率', component: () => import('../views/traffic/LineUtilization.vue') },
      { path: '/traffic/connections', name: '活跃连接', component: () => import('../views/traffic/ActiveConnections.vue') },
      { path: '/traffic/history', name: '历史趋势', component: () => import('../views/traffic/HistoryTrends.vue') },

      // ===== 接入配置 =====
      { path: '/network/quick-setup', name: '快速上网', component: () => import('../views/network/QuickSetup.vue') },
      { path: '/network/physical-ports', name: '物理端口', component: () => import('../views/network/Physical.vue') },
      { path: '/network/access-channels', name: '接入通道', component: () => import('../views/network/AccessChannels.vue') },
      { path: '/network/vlans', name: 'VLAN管理', component: () => import('../views/network/Vlans.vue') },
      { path: '/network/devices', name: '网络设备', component: () => import('../views/network/Devices.vue') },
      { path: '/network/interfaces', name: '网络接口', component: () => import('../views/network/Interfaces.vue') },
      { path: '/network/lan', name: 'LAN管理', component: () => import('../views/network/Lan.vue') },
      { path: '/network/dhcp-dns', name: 'DHCP/DNS', component: () => import('../views/network/DhcpDns.vue') },
      { path: '/network/topology', name: '网络拓扑', component: () => import('../views/network/Topology.vue') },
      { path: '/network/link-aggregation', name: '链路聚合Bond/LACP', component: () => import('../views/network/LinkAggregation.vue') },

      // ===== 多拨与汇聚 =====
      { path: '/multiwan/dial-instances', name: '宽带线路', component: () => import('../views/multiwan/DialInstances.vue') },
      { path: '/multiwan/batch-import', name: '批量导入', component: () => import('../views/multiwan/BatchImport.vue') },
      { path: '/multiwan/line-status', name: '线路状态', component: () => import('../views/multiwan/LineStatus.vue') },
      { path: '/multiwan/aggregation-groups', name: '双栈线路汇聚', component: () => import('../views/multiwan/AggregationGroups.vue') },
      { path: '/multiwan/policies', name: '调度策略', component: () => import('../views/multiwan/Policies.vue') },
      { path: '/multiwan/health-check', name: '健康检测', component: () => import('../views/multiwan/HealthCheck.vue') },
      { path: '/multiwan/statistics', name: '汇聚统计', component: () => import('../views/multiwan/Statistics.vue') },
      { path: '/multiwan/adaptive-scheduling', name: '智能线路调度', component: () => import('../views/multiwan/AdaptiveScheduling.vue') },

      // ===== IPv6 管理 =====
      { path: '/ipv6/settings', name: 'IPv6全局设置', component: () => import('../views/ipv6/Settings.vue') },
      { path: '/ipv6/addresses', name: 'IPv6地址状态', component: () => import('../views/ipv6/Addresses.vue') },
      { path: '/ipv6/prefix-delegation', name: 'PD前缀管理', component: () => import('../views/ipv6/PrefixDelegation.vue') },
      { path: '/ipv6/lan-prefixes', name: 'LAN前缀管理', component: () => import('../views/ipv6/LanPrefixes.vue') },
      { path: '/ipv6/translation', name: 'NPTv6/NAT66', component: () => import('../views/ipv6/Translation.vue') },
      { path: '/ipv6/routes', name: 'IPv6路由', component: () => import('../views/ipv6/Routes.vue') },
      { path: '/ipv6/diagnostics', name: 'IPv6诊断', component: () => import('../views/ipv6/Diagnostics.vue') },
      // ===== 路由管理 =====
      { path: '/network/static-routes', name: '静态路由', component: () => import('../views/network/StaticRoutes.vue') },
      { path: '/multiwan/policy-routing', name: '策略路由', component: () => import('../views/multiwan/PolicyRouting.vue') },
      { path: '/network/routing-rules', name: '路由规则', component: () => import('../views/network/RoutingRules.vue') },
      { path: '/network/diagnostics', name: '路由表', component: () => import('../views/network/Diagnostics.vue') },

      // ===== 防火墙 =====
      { path: '/firewall/zones', name: '防火墙区域', component: () => import('../views/firewall/Zones.vue') },
      { path: '/firewall/forwarding', name: '通信规则', component: () => import('../views/firewall/Forwarding.vue') },
      { path: '/firewall/nat', name: 'NAT', component: () => import('../views/firewall/Nat.vue') },
      { path: '/firewall/port-forward', name: '端口转发', component: () => import('../views/firewall/PortForward.vue') },
      { path: '/firewall/dmz', name: 'DMZ', component: () => import('../views/firewall/PortForward.vue') },
      { path: '/firewall/traffic-rules', name: '流量规则', component: () => import('../views/firewall/TrafficRules.vue') },
      { path: '/services/upnp', name: 'UPnP', component: () => import('../views/services/Upnp.vue') },
      { path: '/firewall/ipv6-firewall', name: 'IPv6防火墙', component: () => import('../views/firewall/TrafficRules.vue') },
      { path: '/firewall/ipsets', name: 'IP集合', component: () => import('../views/firewall/Ipsets.vue') },

      // ===== VPN =====
      { path: '/vpn/wireguard', name: 'WireGuard', component: () => import('../views/vpn/Wireguard.vue') },
      { path: '/vpn/openvpn', name: 'OpenVPN', component: () => import('../views/vpn/Openvpn.vue') },
      { path: '/vpn/tunnels', name: '隧道管理', component: () => import('../views/vpn/Tunnels.vue') },

      // ===== 服务 =====
      { path: '/services/ddns', name: '动态DNS', component: () => import('../views/services/Ddns.vue') },
      { path: '/services/qos', name: 'QoS/SQM', component: () => import('../views/services/Qos.vue') },
      { path: '/services/wol', name: 'Wake on LAN', component: () => import('../views/services/Wol.vue') },
      { path: '/services/service-manager', name: '服务管理', component: () => import('../views/services/ServiceManager.vue') },

      // ===== 系统管理 =====
      { path: '/system/settings', name: '系统设置', component: () => import('../views/system/Settings.vue') },
      { path: '/system/users', name: '用户权限', component: () => import('../views/system/Users.vue') },
      { path: '/system/ssh', name: 'SSH管理', component: () => import('../views/system/Ssh.vue') },
      { path: '/system/packages', name: '软件包', component: () => import('../views/system/Packages.vue') },
      { path: '/system/startup', name: '启动项', component: () => import('../views/system/Startup.vue') },
      { path: '/system/crontab', name: '定时任务', component: () => import('../views/system/Crontab.vue') },
      { path: '/system/mounts', name: '挂载管理', component: () => import('../views/system/Mounts.vue') },
      { path: '/system/backup', name: '备份恢复', component: () => import('../views/system/Backup.vue') },
      { path: '/system/firmware', name: '固件升级', component: () => import('../views/system/Firmware.vue') },
      { path: '/system/reboot', name: '重启关机', component: () => import('../views/system/Reboot.vue') },

      // ===== 配置中心 =====
      { path: '/config/pending', name: '待应用修改', component: () => import('../views/config/Pending.vue') },
      { path: '/config/apply', name: '应用配置', component: () => import('../views/config/Apply.vue') },
      { path: '/config/rollback', name: '回滚', component: () => import('../views/config/Rollback.vue') },
      { path: '/config/snapshots', name: '配置快照', component: () => import('../views/config/Snapshots.vue') },

      // ===== 插件中心 =====
      { path: '/plugins/manager', name: '插件管理', component: () => import('../views/plugins/Manager.vue') },

      // ===== 旧路由兼容重定向 =====
      { path: '/monitor/overview', redirect: '/dashboard' },
      { path: '/monitor/network-status', redirect: '/status/lines' },
      { path: '/monitor/interface-status', redirect: '/network/interfaces' },
      { path: '/monitor/pppoe-status', redirect: '/multiwan/line-status' },
      { path: '/monitor/dhcp-leases', redirect: '/network/dhcp-dns' },
      { path: '/network/physical', redirect: '/network/physical-ports' },
      { path: '/network/wan', redirect: '/multiwan/dial-instances' },
      { path: '/network/ipv6', redirect: '/ipv6/settings' },
      { path: '/network/port-aggregation', redirect: '/multiwan/aggregation-groups' },
      { path: '/multiwan/lines', redirect: '/multiwan/dial-instances' },
      { path: '/multiwan/load-balance', redirect: '/multiwan/policies' },
      { path: '/multiwan/failover', redirect: '/multiwan/aggregation-groups' },
      { path: '/config/diff', redirect: '/config/pending' },
      { path: '/linehub/:pathMatch(.*)*', redirect: '/multiwan/aggregation-groups' },
    ]
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior() { return { top: 0 } }
})

export default router
