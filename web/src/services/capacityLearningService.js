/**
 * 容量学习服务
 * 模拟动态容量学习：观察持续上传、计算可持续容量、保存历史
 */

// 生产安全: 不静态导入dev-mock
const mockPcdnLines = []
import { PCDN_LINE_STATUS } from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function response(data) {
  return Promise.resolve({
    data: JSON.parse(JSON.stringify(data)),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

// 为每条线路生成历史容量数据
function generateCapacityHistory(line) {
  const base = line.learnedCapacityMbps || line.configuredUploadMbps * 0.95
  const safe = line.safeCapacityMbps || base * 0.95

  // 1 小时数据（60个点，每分钟）
  const hourly = Array.from({ length: 60 }, (_, i) => {
    const variance = (Math.sin(i / 10) + Math.random() * 0.3 - 0.15) * 0.05
    return {
      timestamp: new Date(Date.now() - (60 - i) * 60000).toISOString(),
      physicalUploadMbps: Math.max(0, Math.round(base * (1 + variance) * 10) / 10),
      effectiveUploadMbps: Math.max(0, Math.round(base * 0.9 * (1 + variance) * 10) / 10),
      queueDelayMs: Math.max(0, Math.round((line.queueDelayMs || 10) * (1 + Math.random() * 0.2) * 10) / 10),
      packetLossPercent: Math.max(0, Math.round((line.packetLossPercent || 0.1) * (1 + Math.random() * 0.5) * 100) / 100),
      tcpRetransmissionPercent: Math.max(0, Math.round((line.tcpRetransmissionPercent || 1) * (1 + Math.random() * 0.5) * 100) / 100),
    }
  })

  // 24 小时数据（24个点，每小时）
  const daily = Array.from({ length: 24 }, (_, i) => {
    const variance = (Math.sin(i / 4) + Math.random() * 0.4 - 0.2) * 0.08
    return {
      timestamp: new Date(Date.now() - (24 - i) * 3600000).toISOString(),
      learnedCapacityMbps: Math.max(0, Math.round(base * (1 + variance) * 10) / 10),
      safeCapacityMbps: Math.max(0, Math.round(safe * (1 + variance) * 10) / 10),
      safeFactorPercent: Math.round((90 + Math.random() * 8) * 100) / 100,
    }
  })

  // 7 天数据（7个点，每天）
  const weekly = Array.from({ length: 7 }, (_, i) => {
    const variance = (Math.sin(i / 2) + Math.random() * 0.5 - 0.25) * 0.1
    return {
      date: new Date(Date.now() - (7 - i) * 86400000).toISOString().split('T')[0],
      avgLearnedCapacityMbps: Math.max(0, Math.round(base * (1 + variance) * 10) / 10),
      avgSafeCapacityMbps: Math.max(0, Math.round(safe * (1 + variance) * 10) / 10),
      peakUploadMbps: Math.max(0, Math.round(base * (1.05 + variance) * 10) / 10),
      minUploadMbps: Math.max(0, Math.round(base * (0.3 + variance) * 10) / 10),
    }
  })

  return { hourly, daily, weekly }
}

function computeSafeFactor(line) {
  // 安全系数 = 安全容量 / 学习容量
  if (!line.learnedCapacityMbps || line.learnedCapacityMbps === 0) return 0
  return Math.round((line.safeCapacityMbps / line.learnedCapacityMbps) * 10000) / 100
}

export const capacityLearningService = {
  /**
   * 获取线路容量学习详情
   */
  getCapacityDetail(lineId) {
    const line = mockPcdnLines.find(l => l.lineId === lineId)
    if (!line) return response({ error: '线路不存在' })

    const history = generateCapacityHistory(line)
    return response({
      lineId,
      lineName: line.lineName,
      ipFamily: line.ipFamily,
      configuredUploadMbps: line.configuredUploadMbps,
      learnedCapacityMbps: line.learnedCapacityMbps,
      safeCapacityMbps: line.safeCapacityMbps,
      safeFactorPercent: computeSafeFactor(line),
      currentPhysicalUploadMbps: line.physicalUploadMbps,
      currentUtilizationPercent: line.safeCapacityMbps > 0
        ? Math.round((line.physicalUploadMbps / line.safeCapacityMbps) * 10000) / 100
        : 0,
      targetUtilizationPercent: line.targetUtilizationPercent,
      remainingCapacityMbps: line.remainingEffectiveCapacityMbps,
      queueDelayMs: line.queueDelayMs,
      packetLossPercent: line.packetLossPercent,
      tcpRetransmissionPercent: line.tcpRetransmissionPercent,
      healthStatus: line.healthStatus,
      history,
      notice: '线路标称带宽不一定等于可持续业务带宽，系统将根据实际运行情况自动学习。',
    })
  },

  /**
   * 获取所有线路容量学习摘要
   */
  getAllCapacities() {
    const summaries = mockPcdnLines
      .filter(l => l.healthStatus !== PCDN_LINE_STATUS.OFFLINE)
      .map(l => ({
        lineId: l.lineId,
        lineName: l.lineName,
        ipFamily: l.ipFamily,
        configuredUploadMbps: l.configuredUploadMbps,
        learnedCapacityMbps: l.learnedCapacityMbps,
        safeCapacityMbps: l.safeCapacityMbps,
        safeFactorPercent: computeSafeFactor(l),
        currentUtilizationPercent: l.safeCapacityMbps > 0
          ? Math.round((l.physicalUploadMbps / l.safeCapacityMbps) * 10000) / 100
          : 0,
        targetUtilizationPercent: l.targetUtilizationPercent,
        remainingCapacityMbps: l.remainingEffectiveCapacityMbps,
        healthStatus: l.healthStatus,
      }))
    return response(summaries)
  },

  /**
   * 手动设置标称上行
   */
  setConfiguredUpload(lineId, uploadMbps) {
    return response({
      lineId,
      configuredUploadMbps: uploadMbps,
      message: '标称上行已更新，系统将重新观察并学习可持续容量。',
    })
  },
}
