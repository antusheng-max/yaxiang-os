/**
 * 系统API - Mock数据提供
 */

export function getMockSystemInfo() {
  return {
    hostname: 'yaxiang-gateway',
    kernel: '6.12.0',
    system: 'OpenWrt 25.12.5',
    model: 'x86_64',
    firmware: 'Yaxiang OS V0.2-dev',
    uptime: 86400,
    memory: { total: 4096, free: 2048, cached: 1024 },
  }
}

export function getMockUptime() {
  return { uptime: 86400, localtime: Date.now() }
}

export function getMockServices() {
  return [
    { name: 'yaxiang-web', running: true, enabled: true },
    { name: 'yaxiang-backend', running: false, enabled: true, note: '尚未接入系统后端' },
    { name: 'netifd', running: true, enabled: true },
    { name: 'dnsmasq', running: true, enabled: true },
    { name: 'firewall4', running: true, enabled: true },
  ]
}
