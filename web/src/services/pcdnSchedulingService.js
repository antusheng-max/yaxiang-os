/**
 * PCDN 调度服务
 * 评分模型 + 自动调节逻辑
 * 每 10 秒重新计算权重
 */

// 生产安全: 不静态导入dev-mock
const mockPcdnLines = []
import {
  DEFAULT_SCORING_WEIGHTS,
  DEFAULT_TUNING_PARAMS,
  IP_FAMILY,
  PCDN_LINE_STATUS,
  PCDN_LINE_STATUS_LABEL,
} from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function response(data) {
  return Promise.resolve({
    data: JSON.parse(JSON.stringify(data)),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

/**
 * 计算单条线路评分
 * 权重：剩余有效上行 35% / 有效吞吐 20% / 丢包重传 20% / 利用率 10% / 稳定性 10% / 延迟抖动 5%
 */
function computeScore(line, weights) {
  const w = weights || DEFAULT_SCORING_WEIGHTS

  // 1. 剩余有效上行能力（剩余容量越大，分数越高）
  const maxCapacity = 600
  const remainingScore = Math.min(100, (line.remainingEffectiveCapacityMbps / maxCapacity) * 100)

  // 2. 有效业务吞吐（有效上传越高越好，但不高于安全容量）
  const safeCapacity = line.safeCapacityMbps || 1
  const effectiveRatio = line.effectiveUploadMbps / safeCapacity
  const throughputScore = Math.min(100, effectiveRatio * 100)

  // 3. 丢包和 TCP 重传（越低越好）
  const lossPenalty = Math.min(100, line.packetLossPercent * 20)
  const retransPenalty = Math.min(100, line.tcpRetransmissionPercent * 5)
  const lossScore = Math.max(0, 100 - lossPenalty - retransPenalty)

  // 4. 当前利用率（接近目标为佳）
  const utilizationRatio = line.physicalUploadMbps / (line.safeCapacityMbps || 1)
  const targetRatio = line.targetUtilizationPercent / 100
  const utilDiff = Math.abs(utilizationRatio - targetRatio)
  const utilizationScore = Math.max(0, 100 - utilDiff * 200)

  // 5. 稳定性（低抖动 = 高稳定性）
  const stabilityScore = Math.max(0, 100 - (line.jitterMs || 0) * 3)

  // 6. 延迟与抖动
  const latencyScore = Math.max(0, 100 - (line.latencyMs || 0) * 0.5)

  const totalScore =
    remainingScore * w.remainingCapacity +
    throughputScore * w.effectiveThroughput +
    lossScore * w.lossAndRetransmission +
    utilizationScore * w.currentUtilization +
    stabilityScore * w.stability +
    latencyScore * w.latencyAndJitter

  return {
    totalScore: Math.round(totalScore * 100) / 100,
    components: {
      remainingCapacity: Math.round(remainingScore * 100) / 100,
      effectiveThroughput: Math.round(throughputScore * 100) / 100,
      lossAndRetransmission: Math.round(lossScore * 100) / 100,
      currentUtilization: Math.round(utilizationScore * 100) / 100,
      stability: Math.round(stabilityScore * 100) / 100,
      latencyAndJitter: Math.round(latencyScore * 100) / 100,
    },
  }
}

/**
 * 自动调节逻辑
 */
function computeRecommendedWeight(line, score, params) {
  const p = params || DEFAULT_TUNING_PARAMS

  // 故障或离线线路：立即停止
  if (line.healthStatus === PCDN_LINE_STATUS.FAULT || line.healthStatus === PCDN_LINE_STATUS.OFFLINE) {
    return { weight: 0, reason: '故障或离线，停止分配新连接' }
  }

  // 丢包或重传快速升高时降权
  if (line.tcpRetransmissionPercent > 10 || line.packetLossPercent > 3) {
    return { weight: Math.max(1, Math.round(score / 20)), reason: '丢包或TCP重传过高，降权保护' }
  }

  // 接近目标利用率且队列延迟增加时停止升权
  const currentUtil = line.safeCapacityMbps > 0 ? (line.physicalUploadMbps / line.safeCapacityMbps) * 100 : 0
  if (currentUtil >= p.targetPhysicalUtilization && line.queueDelayMs > 30) {
    return { weight: Math.max(1, Math.round(score / 15)), reason: '接近目标利用率且队列延迟增加，停止升权' }
  }

  // 超过目标利用率时降权
  if (currentUtil > p.autoAdjustMax) {
    return { weight: Math.max(1, Math.round(score / 25)), reason: '超过目标利用率，平滑降权' }
  }

  // 健康且有较大剩余上行：升权
  if (line.remainingEffectiveCapacityMbps > line.safeCapacityMbps * 0.2 && line.healthStatus === PCDN_LINE_STATUS.HEALTHY) {
    return { weight: Math.max(5, Math.round(score / 3)), reason: '健康且有较大剩余上行，升权' }
  }

  // 默认：根据评分计算
  return { weight: Math.max(1, Math.round(score / 5)), reason: '根据综合评分调整' }
}

export const pcdnSchedulingService = {
  /**
   * 获取所有线路评分和推荐权重
   */
  getScores() {
    const results = mockPcdnLines.map(line => {
      const score = computeScore(line)
      const recommended = computeRecommendedWeight(line, score.totalScore)
      return {
        lineId: line.lineId,
        lineName: line.lineName,
        ipFamily: line.ipFamily,
        ipFamilyLabel: line.ipFamily === IP_FAMILY.IPV4 ? 'IPv4' : 'IPv6',
        healthStatus: line.healthStatus,
        healthStatusLabel: PCDN_LINE_STATUS_LABEL[line.healthStatus] || line.healthStatus,
        currentWeight: line.currentWeight,
        recommendedWeight: recommended.weight,
        score: score.totalScore,
        scoreComponents: score.components,
        schedulingEligible: line.schedulingEligible,
        adjustmentReason: recommended.reason,
        remainingEffectiveCapacityMbps: line.remainingEffectiveCapacityMbps,
        effectiveUploadMbps: line.effectiveUploadMbps,
        tcpRetransmissionPercent: line.tcpRetransmissionPercent,
        packetLossPercent: line.packetLossPercent,
        physicalUtilizationPercent: line.safeCapacityMbps > 0
          ? Math.round((line.physicalUploadMbps / line.safeCapacityMbps) * 10000) / 100
          : 0,
      }
    })
    return response(results)
  },

  /**
   * 获取评分权重配置
   */
  getWeights() {
    return response(DEFAULT_SCORING_WEIGHTS)
  },

  /**
   * 获取 IPv4 / IPv6 独立调度结果
   */
  getDualStackScheduling() {
    const ipv4 = mockPcdnLines.filter(l => l.ipFamily === IP_FAMILY.IPV4)
    const ipv6 = mockPcdnLines.filter(l => l.ipFamily === IP_FAMILY.IPV6)

    const processGroup = (group) => group.map(line => {
      const score = computeScore(line)
      const recommended = computeRecommendedWeight(line, score.totalScore)
      return {
        lineId: line.lineId,
        lineName: line.lineName,
        ipFamily: line.ipFamily,
        ipFamilyLabel: line.ipFamily === IP_FAMILY.IPV4 ? 'IPv4' : 'IPv6',
        healthStatus: line.healthStatus,
        healthStatusLabel: PCDN_LINE_STATUS_LABEL[line.healthStatus] || line.healthStatus,
        currentWeight: line.currentWeight,
        recommendedWeight: recommended.weight,
        score: score.totalScore,
        scoreComponents: score.components,
        schedulingEligible: line.schedulingEligible,
        cdnInboundEligible: line.cdnInboundEligible,
        cdnOutboundEligible: line.cdnOutboundEligible,
        adjustmentReason: recommended.reason,
      }
    })

    return response({
      ipv4: processGroup(ipv4),
      ipv6: processGroup(ipv6),
      notice: 'IPv4 和 IPv6 权重独立计算，不互相复制。',
    })
  },

  /**
   * 获取自动调节参数
   */
  getTuningParams() {
    return response(DEFAULT_TUNING_PARAMS)
  },
}
