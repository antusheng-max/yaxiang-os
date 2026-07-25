/**
 * 调度API - Mock数据提供
 */

export function getMockSchedulingOverview() {
  return {
    totalLines: 3,
    activeLines: 3,
    totalBandwidth: '3000Mbps',
    currentLoad: '45%',
    schedulingMode: '智能调度',
    healthScore: 92,
  }
}

export function getMockLineRanking() {
  return [
    { rank: 1, name: '电信千兆A', score: 95, bandwidth: '1000Mbps', latency: '8ms', packetLoss: '0.01%' },
    { rank: 2, name: '联通千兆B', score: 88, bandwidth: '1000Mbps', latency: '12ms', packetLoss: '0.02%' },
    { rank: 3, name: '移动宽带C', score: 75, bandwidth: '1000Mbps', latency: '18ms', packetLoss: '0.05%' },
  ]
}

export function getMockHitRecords() {
  return [
    { time: '2026-07-24 10:30:00', line: '电信千兆A', reason: '延迟最低', bytes: '1.2GB' },
    { time: '2026-07-24 10:29:55', line: '联通千兆B', reason: '负载均衡', bytes: '800MB' },
  ]
}

export function getMockAdvancedParams() {
  return {
    probeInterval: 5,
    failoverThreshold: 3,
    weightAlgorithm: 'dynamic',
    maxRetransmitRate: 0.05,
    effectiveUplinkRatio: 0.95,
  }
}
