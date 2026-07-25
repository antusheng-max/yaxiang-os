/**
 * Real Adapter - OpenWrt真实系统后端适配器
 *
 * 生产环境使用，通过UCI/ubus/rpcd与OpenWrt系统交互
 * 尚未实现的接口返回 implemented: false
 */

const NOT_IMPLEMENTED = {
  implemented: false,
  source: 'unavailable',
  reason: '尚未接入真实系统后端'
}

/**
 * 通过ubus调用OpenWrt系统接口
 */
async function ubusCall(object, method, params = {}) {
  try {
    const res = await fetch('/ubus', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ jsonrpc: '2.0', id: Date.now(), method: 'call', params: ['00000000000000000000000000000000', object, method, params] })
    })
    const data = await res.json()
    if (data.result && data.result[0] === 0) {
      return { implemented: true, source: 'ubus', data: data.result[1] }
    }
    return { ...NOT_IMPLEMENTED, reason: `ubus调用失败: ${object}.${method}` }
  } catch (e) {
    return { ...NOT_IMPLEMENTED, reason: `ubus不可用: ${e.message}` }
  }
}

export function createRealAdapter() {
  return {
    mode: 'real',

    checkImplementation(feature) {
      return {
        implemented: true,
        source: 'openwrt-ubus',
        feature
      }
    },

    // 系统
    system: {
      getInfo: () => ubusCall('yaxiang_system2', 'sys.info'),
      getUptime: () => ubusCall('yaxiang_monitor', 'mon.uptime'),
      getServices: () => ubusCall('yaxiang_system2', 'sys.services'),
      serviceAction: (name, action) => ubusCall('yaxiang_system2', 'sys.service_action', { name, action }),
      getHostname: () => ubusCall('yaxiang_system2', 'sys.hostname_get'),
      setHostname: (hostname) => ubusCall('yaxiang_system2', 'sys.hostname_set', { hostname }),
      getTimezone: () => ubusCall('yaxiang_system2', 'sys.timezone_get'),
      setTimezone: (timezone) => ubusCall('yaxiang_system2', 'sys.timezone_set', { timezone }),
      getNtp: () => ubusCall('yaxiang_system2', 'sys.ntp_get'),
      setNtp: (servers) => ubusCall('yaxiang_system2', 'sys.ntp_set', { servers }),
      getLog: (lines) => ubusCall('yaxiang_system2', 'sys.log', { lines: String(lines || 100) }),
      backup: () => ubusCall('yaxiang_system2', 'sys.backup'),
      reboot: () => ubusCall('yaxiang_system2', 'sys.reboot'),
      setPassword: (old, newPass) => ubusCall('yaxiang_system2', 'sys.password_set', { old, new: newPass }),
      getPackages: () => ubusCall('yaxiang_system2', 'sys.packages'),
      getVersion: () => ubusCall('yaxiang_system2', 'sys.version'),
    },

    // 网络
    network: {
      getInterfaces: () => ubusCall('network.interface', 'dump'),
      getWanList: () => ubusCall('yaxiang_lanwan', 'wan.list'),
      getLanList: () => ubusCall('yaxiang_lanwan', 'lan.list'),
      getVlans: async () => NOT_IMPLEMENTED,
      getDhcpLeases: (name) => ubusCall('yaxiang_lanwan', 'lan.leases', { name: name || 'lan' }),
      // 物理网卡
      getPhysicalDevices: () => ubusCall('yaxiang_network', 'network.physical_devices'),
      getDeviceInfo: (iface) => ubusCall('yaxiang_network', 'network.device_info', { interface: iface }),
      getInterfaceConfig: (iface) => ubusCall('yaxiang_network', 'network.interface_config', { interface: iface }),
      getInterfaceIpv4: (iface) => ubusCall('yaxiang_network', 'network.interface_ipv4', { interface: iface }),
      getInterfaceIpv6: (iface) => ubusCall('yaxiang_network', 'network.interface_ipv6', { interface: iface }),
      getLinkStatus: () => ubusCall('yaxiang_network', 'network.link_status'),
      setMtu: (iface, mtu) => ubusCall('yaxiang_network', 'network.set_mtu', { interface: iface, mtu: String(mtu) }),
      setDescription: (iface, desc) => ubusCall('yaxiang_network', 'network.set_description', { interface: iface, description: desc }),
      setLinkState: (iface, state) => ubusCall('yaxiang_network', 'network.set_link_state', { interface: iface, state }),
      // LAN管理
      lanGet: (name) => ubusCall('yaxiang_lanwan', 'lan.get', { name }),
      lanCreate: (data) => ubusCall('yaxiang_lanwan', 'lan.create', data),
      lanDelete: (name) => ubusCall('yaxiang_lanwan', 'lan.delete', { name }),
      lanSetIpaddr: (name, ipaddr) => ubusCall('yaxiang_lanwan', 'lan.set_ipaddr', { name, ipaddr }),
      lanSetNetmask: (name, netmask) => ubusCall('yaxiang_lanwan', 'lan.set_netmask', { name, netmask }),
      lanSetMtu: (name, mtu) => ubusCall('yaxiang_lanwan', 'lan.set_mtu', { name, mtu: String(mtu) }),
      lanSetDevice: (name, device) => ubusCall('yaxiang_lanwan', 'lan.set_device', { name, device }),
      lanSetEnabled: (name, enabled) => ubusCall('yaxiang_lanwan', 'lan.set_enabled', { name, enabled: enabled ? '1' : '0' }),
      lanSetDhcp: (data) => ubusCall('yaxiang_lanwan', 'lan.set_dhcp', data),
      // WAN管理
      wanGet: (name) => ubusCall('yaxiang_lanwan', 'wan.get', { name }),
      wanCreate: (data) => ubusCall('yaxiang_lanwan', 'wan.create', data),
      wanDelete: (name) => ubusCall('yaxiang_lanwan', 'wan.delete', { name }),
      wanSetProto: (name, proto) => ubusCall('yaxiang_lanwan', 'wan.set_proto', { name, proto }),
      wanSetStatic: (data) => ubusCall('yaxiang_lanwan', 'wan.set_static', data),
      wanSetPppoe: (data) => ubusCall('yaxiang_lanwan', 'wan.set_pppoe', data),
      wanSetEnabled: (name, enabled) => ubusCall('yaxiang_lanwan', 'wan.set_enabled', { name, enabled: enabled ? '1' : '0' }),
      wanSetDevice: (name, device) => ubusCall('yaxiang_lanwan', 'wan.set_device', { name, device }),
      wanSetMtu: (name, mtu) => ubusCall('yaxiang_lanwan', 'wan.set_mtu', { name, mtu: String(mtu) }),
      wanConnect: (name) => ubusCall('yaxiang_lanwan', 'wan.connect', { name }),
      wanDisconnect: (name) => ubusCall('yaxiang_lanwan', 'wan.disconnect', { name }),
      wanReconnect: (name) => ubusCall('yaxiang_lanwan', 'wan.reconnect', { name }),
      wanStatus: (name) => ubusCall('yaxiang_lanwan', 'wan.status', { name }),
    },

    // 防火墙
    firewall: {
      getZones: () => ubusCall('yaxiang_firewall', 'fw.zones'),
      getForwards: () => ubusCall('yaxiang_firewall', 'fw.forwards'),
      getRedirects: () => ubusCall('yaxiang_firewall', 'fw.redirects'),
      addRedirect: (data) => ubusCall('yaxiang_firewall', 'fw.add_redirect', data),
      delRedirect: (name) => ubusCall('yaxiang_firewall', 'fw.del_redirect', { name }),
      getConnections: () => ubusCall('yaxiang_firewall', 'fw.connections'),
      getUpnpStatus: () => ubusCall('yaxiang_firewall', 'fw.upnp_status'),
      setUpnp: (enabled) => ubusCall('yaxiang_firewall', 'fw.upnp_set', { enabled: enabled ? '1' : '0' }),
      reload: () => ubusCall('yaxiang_firewall', 'fw.reload'),
    },

    // 监控
    monitor: {
      getCpu: () => ubusCall('yaxiang_monitor', 'mon.cpu'),
      getMemory: () => ubusCall('yaxiang_monitor', 'mon.memory'),
      getDisk: () => ubusCall('yaxiang_monitor', 'mon.disk'),
      getLoad: () => ubusCall('yaxiang_monitor', 'mon.load'),
      getTemperature: () => ubusCall('yaxiang_monitor', 'mon.temperature'),
      getInterfaces: () => ubusCall('yaxiang_monitor', 'mon.interfaces'),
      getTraffic: () => ubusCall('yaxiang_monitor', 'mon.traffic'),
      getConnections: () => ubusCall('yaxiang_monitor', 'mon.connections'),
      getUptime: () => ubusCall('yaxiang_monitor', 'mon.uptime'),
    },

    // VLAN/PPPoE
    vlan: {
      list: () => ubusCall('yaxiang_vlan_pppoe', 'vlan.list'),
      create: (device, vid) => ubusCall('yaxiang_vlan_pppoe', 'vlan.create', { device, vid: String(vid) }),
      delete: (device, vid) => ubusCall('yaxiang_vlan_pppoe', 'vlan.delete', { device, vid: String(vid) }),
      validate: (vid) => ubusCall('yaxiang_vlan_pppoe', 'vlan.validate', { vid: String(vid) }),
    },
    pppoe: {
      list: () => ubusCall('yaxiang_vlan_pppoe', 'pppoe.list'),
      add: (data) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.add', data),
      delete: (name) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.delete', { name }),
      batchAdd: (data) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.batch_add', data),
      setEnabled: (name, enabled) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.set_enabled', { name, enabled: enabled ? '1' : '0' }),
      batchSetEnabled: (names, enabled) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.batch_set_enabled', { names, enabled: enabled ? '1' : '0' }),
      reconnect: (name) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.reconnect', { name }),
      status: (name) => ubusCall('yaxiang_vlan_pppoe', 'pppoe.status', { name }),
      statusAll: () => ubusCall('yaxiang_vlan_pppoe', 'pppoe.status_all'),
    },

    // 多WAN
    mwan: {
      getStatus: () => ubusCall('yaxiang_advanced', 'mwan.status'),
      getPolicies: () => ubusCall('yaxiang_advanced', 'mwan.policies'),
      setMode: (mode) => ubusCall('yaxiang_advanced', 'mwan.set_mode', { mode }),
      setWeight: (iface, weight) => ubusCall('yaxiang_advanced', 'mwan.set_weight', { interface: iface, weight: String(weight) }),
      setEnabled: (iface, enabled) => ubusCall('yaxiang_advanced', 'mwan.set_enabled', { interface: iface, enabled: enabled ? '1' : '0' }),
      forceRoute: (iface, dest) => ubusCall('yaxiang_advanced', 'mwan.force_route', { interface: iface, dest }),
      getRules: () => ubusCall('yaxiang_advanced', 'mwan.rules'),
      addRule: (data) => ubusCall('yaxiang_advanced', 'mwan.add_rule', data),
      delRule: (name) => ubusCall('yaxiang_advanced', 'mwan.del_rule', { name }),
      getHits: () => ubusCall('yaxiang_advanced', 'mwan.hits'),
    },

    // 健康检查
    healthCheck: {
      getStatus: () => ubusCall('yaxiang_advanced', 'hc.status'),
      getStatusOne: (iface) => ubusCall('yaxiang_advanced', 'hc.status_one', { interface: iface }),
      configure: (data) => ubusCall('yaxiang_advanced', 'hc.configure', data),
      injectFault: (iface, type) => ubusCall('yaxiang_advanced', 'hc.inject_fault', { interface: iface, type }),
      clearFault: (iface) => ubusCall('yaxiang_advanced', 'hc.clear_fault', { interface: iface }),
    },

    // 流控
    trafficControl: {
      getStatus: () => ubusCall('yaxiang_advanced', 'tc.status'),
      setLimit: (data) => ubusCall('yaxiang_advanced', 'tc.set_limit', data),
      setDeviceLimit: (ip, rate) => ubusCall('yaxiang_advanced', 'tc.set_device_limit', { ip, rate }),
      clear: (iface) => ubusCall('yaxiang_advanced', 'tc.clear', { interface: iface }),
      getStats: (iface) => ubusCall('yaxiang_advanced', 'tc.stats', { interface: iface }),
    },

    // 调度
    scheduler: {
      getOverview: () => ubusCall('yaxiang_advanced', 'sched.overview'),
      getLineRanking: () => ubusCall('yaxiang_advanced', 'sched.ranking'),
      setPriority: (iface, priority) => ubusCall('yaxiang_advanced', 'sched.set_priority', { interface: iface, priority: String(priority) }),
      setCost: (iface, cost) => ubusCall('yaxiang_advanced', 'sched.set_cost', { interface: iface, cost: String(cost) }),
      getHitRecords: () => ubusCall('yaxiang_advanced', 'sched.hits'),
      getAdvancedParams: () => ubusCall('yaxiang_advanced', 'sched.params'),
      setParams: (data) => ubusCall('yaxiang_advanced', 'sched.set_params', data),
    },

    // 带宽探测
    bandwidth: {
      getStatus: () => ubusCall('yaxiang_advanced', 'bw.status'),
      startProbe: (iface, nominal) => ubusCall('yaxiang_advanced', 'bw.start_probe', { interface: iface, nominal_up: String(nominal) }),
      stopProbe: (iface) => ubusCall('yaxiang_advanced', 'bw.stop_probe', { interface: iface }),
      setLimit: (iface, maxUp) => ubusCall('yaxiang_advanced', 'bw.set_limit', { interface: iface, max_up: String(maxUp) }),
      getHistory: (iface) => ubusCall('yaxiang_advanced', 'bw.history', { interface: iface }),
    },

    // 运营商/省份识别
    carrier: {
      lookup: (ip) => ubusCall('yaxiang_advanced', 'carrier.lookup', { ip }),
      getStats: () => ubusCall('yaxiang_advanced', 'carrier.stats'),
      getImportStatus: () => ubusCall('yaxiang_advanced', 'carrier.import_status'),
    },

    // 流量
    traffic: {
      getOverview: () => ubusCall('yaxiang_monitor', 'mon.traffic'),
      getGeoAnalysis: () => ubusCall('yaxiang_advanced', 'carrier.stats'),
      getCarrierAnalysis: () => ubusCall('yaxiang_advanced', 'carrier.stats'),
      getLineUtilization: () => ubusCall('yaxiang_monitor', 'mon.interfaces'),
      getActiveConnections: () => ubusCall('yaxiang_firewall', 'fw.connections'),
    },

    notImplemented: () => NOT_IMPLEMENTED,
  }
}
