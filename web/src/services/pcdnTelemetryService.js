/**
 * PCDN 遥测服务
 * 模拟每秒更新线路状态
 */

// 生产安全: 不静态导入dev-mock
const mockPcdnLines = []
import { IP_FAMILY, PCDN_LINE_STATUS } from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

let lines = clone(mockPcdnLines)
let tickCount = 0

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function response(data) {
  return Promise.resolve({
    data: clone(data),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

function randomVariance(base, percent) {
  const variance = base * percent * (Math.random() - 0.5) * 2
  return Math.max(0, base + variance)
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value))
}

function simulateTick(line) {
  if (line.healthStatus === PCDN_LINE_STATUS.OFFLINE || line.healthStatus === PCDN_LINE_STATUS.FAULT) {
    return {
      ...line,
      physicalUploadMbps: 0,
      effectiveUploadMbps: 0,
      activeConnections: 0,
      newConnectionsPerSecond: 0,
      updatedAt: new Date().toISOString(),
    }
  }

  const targetPhysical = line.safeCapacityMbps * (line.targetUtilizationPercent / 100)
  const currentPhysical = randomVariance(targetPhysical, 0.08)
  const effectiveRatio = 0.85 + Math.random() * 0.1
  const currentEffective = currentPhysical * effectiveRatio

  const retransmissionRatio = line.tcpRetransmissionPercent / 100
  const currentRetransmission = currentPhysical * retransmissionRatio * randomVariance(1, 0.15)

  const overheadRatio = line.protocolOverheadMbps / (line.physicalUploadMbps || 1)
  const currentOverhead = currentPhysical * overheadRatio

  const failedRatio = line.failedUploadMbps / (line.physicalUploadMbps || 1)
  const currentFailed = currentPhysical * failedRatio

  const queueDelay = randomVariance(line.queueDelayMs, 0.15)
  const latency = randomVariance(line.latencyMs, 0.1)
  const jitter = randomVariance(line.jitterMs, 0.2)

  const connections = Math.round(randomVariance(line.activeConnections, 0.1))
  const newConnections = Math.round(randomVariance(line.newConnectionsPerSecond, 0.2))

  const remaining = Math.max(0, line.safeCapacityMbps - currentEffective)

  return {
    ...line,
    physicalUploadMbps: Math.round(currentPhysical * 10) / 10,
    effectiveUploadMbps: Math.round(currentEffective * 10) / 10,
    retransmissionMbps: Math.round(currentRetransmission * 10) / 10,
    protocolOverheadMbps: Math.round(currentOverhead * 10) / 10,
    failedUploadMbps: Math.round(currentFailed * 10) / 10,
    queueDelayMs: Math.round(queueDelay * 10) / 10,
    latencyMs: Math.round(latency * 10) / 10,
    jitterMs: Math.round(jitter * 10) / 10,
    activeConnections: connections,
    newConnectionsPerSecond: newConnections,
    remainingEffectiveCapacityMbps: Math.round(remaining * 10) / 10,
    updatedAt: new Date().toISOString(),
  }
}

export const pcdnTelemetryService = {
  /**
   * 模拟一次遥测更新（前端定时调用）
   */
  tick() {
    tickCount += 1
    lines = lines.map(simulateTick)
    return response({ tick: tickCount, lines: lines.map(l => ({
      ...l,
      healthStatusLabel: l.healthStatus,
      ipFamilyLabel: l.ipFamily === IP_FAMILY.IPV4 ? 'IPv4' : 'IPv6',
    })) })
  },

  /**
   * 获取当前遥测快照
   */
  getSnapshot() {
    return response({ tick: tickCount, lines: lines.map(l => ({
      ...l,
      healthStatusLabel: l.healthStatus,
      ipFamilyLabel: l.ipFamily === IP_FAMILY.IPV4 ? 'IPv4' : 'IPv6',
    })) })
  },

  /**
   * 重置遥测数据
   */
  reset() {
    tickCount = 0
    lines = clone(mockPcdnLines)
    return response({ tick: tickCount, lines })
  },
}
