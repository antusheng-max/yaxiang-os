/**
 * 流量API - Mock数据提供
 */

export function getMockTrafficOverview() {
  return {
    totalIn: '12.5GB',
    totalOut: '3.2GB',
    peakIn: '850Mbps',
    peakOut: '420Mbps',
    activeConnections: 1247,
  }
}

export function getMockGeoAnalysis() {
  return [
    { province: '广东', traffic: '45%', connections: 523 },
    { province: '北京', traffic: '20%', connections: 234 },
    { province: '上海', traffic: '15%', connections: 189 },
    { province: '其他', traffic: '20%', connections: 301 },
  ]
}

export function getMockCarrierAnalysis() {
  return [
    { carrier: '电信', traffic: '50%', lines: 1 },
    { carrier: '联通', traffic: '30%', lines: 1 },
    { carrier: '移动', traffic: '20%', lines: 1 },
  ]
}

export function getMockLineUtilization() {
  return [
    { name: '电信千兆A', up: '78%', down: '45%', effectiveUp: '75%' },
    { name: '联通千兆B', up: '62%', down: '38%', effectiveUp: '60%' },
    { name: '移动宽带C', up: '35%', down: '22%', effectiveUp: '33%' },
  ]
}

export function getMockActiveConnections() {
  return [
    { src: '192.168.1.100', dst: '120.232.0.1', proto: 'TCP', port: 443, bytes: '256MB' },
    { src: '192.168.1.101', dst: '180.101.0.1', proto: 'TCP', port: 80, bytes: '128MB' },
  ]
}
