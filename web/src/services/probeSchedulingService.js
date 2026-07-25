/**
 * 极限探测服务
 * 探测算法 + 网络优化/次网络优化逻辑 + 评分模型
 */

// 生产安全: 不静态导入dev-mock
const mockProbeLines = []
import {
  PROBE_STAGE, PROBE_STAGE_LABEL, PROBE_DIRECTION, PROBE_DIRECTION_LABEL,
  OPTIMIZATION_MODE, DEFAULT_PROBE_PARAMS, BREAKTHROUGH_SCORING_WEIGHTS,
  calcBreakthroughPercent, calcMaxUtilizationPercent,
} from '../models/probeLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function clone(v) { return JSON.parse(JSON.stringify(v)) }
function response(data) {
  return Promise.resolve({ data: clone(data), meta: { ...DEMO_META, generatedAt: new Date().toISOString() } })
}
function sumBy(arr, key) { return arr.reduce((s, i) => s + (i[key] || 0), 0) }

/**
 * 探测算法模拟 — 单次 tick
 */
function simulateProbeTick(line, mode) {
  if (line.probeStage === PROBE_STAGE.FAULT || line.probeStage === PROBE_STAGE.WAITING) {
    return { ...line, updatedAt: new Date().toISOString() }
  }

  const advertised = line.advertisedUploadMbps
  const maxMultiplier = line.maximumProbeMultiplier / 100
  const hardLimit = advertised * maxMultiplier
  const isSubNetwork = mode === OPTIMIZATION_MODE.SUB_NETWORK
  const stepPercent = isSubNetwork ? DEFAULT_PROBE_PARAMS.stepMaxPercent : DEFAULT_PROBE_PARAMS.stepMinPercent
  const stepMbps = Math.round(advertised * stepPercent / 100)

  let target = line.currentProbeTargetMbps
  let direction = line.probeDirection
  let stage = line.probeStage
  let effective = line.currentEffectiveUploadMbps
  let raw = line.currentRawUploadMbps
  let retransmission = line.retransmissionMbps
  let failed = line.failedUploadMbps
  let sustained = line.sustainedMaximumMbps
  let burst = line.burstMaximumMbps
  let lastSuccess = line.lastSuccessfulTargetMbps
  let lastFail = line.lastFailedTargetMbps
  let reason = line.adjustmentReason

  // 模拟自然波动
  const variance = 0.05
  const noise = () => 1 + (Math.random() - 0.5) * 2 * variance

  if (direction === PROBE_DIRECTION.UP) {
    // 加压中
    target += stepMbps
    if (target > hardLimit) {
      target = hardLimit
      direction = PROBE_DIRECTION.HOLD
      stage = PROBE_STAGE.STAGNATION
      reason = '已到达最大探测倍率'
    } else {
      // 模拟有效上传增长
      const expectedEffective = target * 0.96 * noise()
      const newRetrans = Math.max(0, target * 0.02 + (target - advertised) * 0.03) * noise()
      const newFailed = Math.max(0, target * 0.01 + (target - advertised) * 0.02) * noise()

      effective = Math.round(expectedEffective * 10) / 10
      raw = Math.round(target * noise() * 10) / 10
      retransmission = Math.round(newRetrans * 10) / 10
      failed = Math.round(newFailed * 10) / 10

      // 检查有效上传是否仍在增长
      if (effective > line.currentEffectiveUploadMbps) {
        lastSuccess = target
        if (effective > sustained) sustained = effective
        if (effective > burst) burst = effective
        reason = `加压中，目标${target}Mbps，有效上传${effective}Mbps`

        // 快速突破阶段判断
        if (stage === PROBE_STAGE.FAST_BREAKTHROUGH && target > advertised * 1.1) {
          stage = PROBE_STAGE.STEPPING
          reason = `已突破标称10%，转入逐级加压`
        }
      } else {
        // 有效上传不增长
        direction = PROBE_DIRECTION.DOWN
        stage = PROBE_STAGE.CONGESTION_BACKOFF
        lastFail = target
        reason = '有效上传停止增长，开始回退'
      }

      // 重传过高时降速
      const retransRatio = raw > 0 ? retransmission / raw : 0
      if (retransRatio > 0.08 && !isSubNetwork) {
        direction = PROBE_DIRECTION.DOWN
        stage = PROBE_STAGE.CONGESTION_BACKOFF
        reason = `重传率${Math.round(retransRatio * 100)}%过高，回退`
      }
    }
  } else if (direction === PROBE_DIRECTION.DOWN) {
    // 回退
    target -= stepMbps
    if (target <= lastSuccess) {
      target = lastSuccess
      direction = PROBE_DIRECTION.HOLD
      stage = PROBE_STAGE.LOCKED
      sustained = Math.round(effective * 10) / 10
      reason = `极限已锁定${sustained}Mbps`
    } else {
      effective = Math.round(target * 0.96 * noise() * 10) / 10
      raw = Math.round(target * noise() * 10) / 10
      retransmission = Math.max(0, Math.round(target * 0.02 * noise() * 10) / 10)
      failed = Math.max(0, Math.round(target * 0.01 * noise() * 10) / 10)
      reason = `回退中，目标${target}Mbps`
    }
  } else {
    // 保持
    effective = Math.round(line.currentEffectiveUploadMbps * noise() * 10) / 10
    raw = Math.round(line.currentRawUploadMbps * noise() * 10) / 10
    reason = `保持目标${target}Mbps`
  }

  return {
    ...line,
    currentProbeTargetMbps: Math.round(target * 10) / 10,
    currentEffectiveUploadMbps: effective,
    currentRawUploadMbps: raw,
    retransmissionMbps: retransmission,
    failedUploadMbps: failed,
    sustainedMaximumMbps: Math.round(sustained * 10) / 10,
    burstMaximumMbps: Math.round(burst * 10) / 10,
    probeStage: stage,
    probeDirection: direction,
    probeStepMbps: stepMbps,
    lastSuccessfulTargetMbps: lastSuccess,
    lastFailedTargetMbps: lastFail,
    advertisedBreakthroughPercent: calcBreakthroughPercent(sustained, advertised),
    maximumUtilizationPercent: calcMaxUtilizationPercent(effective, sustained),
    adjustmentReason: reason,
    updatedAt: new Date().toISOString(),
  }
}

/**
 * 调度评分（突破优先）
 */
function computeScore(line, mode) {
  const w = BREAKTHROUGH_SCORING_WEIGHTS
  const isSubNetwork = mode === OPTIMIZATION_MODE.SUB_NETWORK

  // 1. 有效业务上传（越高越好）
  const maxEffective = 700
  const effectiveScore = Math.min(100, (line.currentEffectiveUploadMbps / maxEffective) * 100)

  // 2. 持续极限突破率（越高越好，可超过100%）
  const breakthroughScore = Math.min(100, (line.advertisedBreakthroughPercent / 150) * 100)

  // 3. 总线路有效上传
  const totalEffectiveScore = Math.min(100, (line.currentEffectiveUploadMbps / 700) * 100)

  // 4. 剩余可突破空间
  const maxPossible = line.advertisedUploadMbps * (line.maximumProbeMultiplier / 100)
  const remaining = Math.max(0, maxPossible - line.sustainedMaximumMbps)
  const remainingScore = Math.min(100, (remaining / 300) * 100)

  // 5. 平台确认（Mock: 无平台时为网络估算）
  const platformScore = 50

  // 6. 重传和失败（越低越好）
  const total = line.currentRawUploadMbps || 1
  const badRatio = (line.retransmissionMbps + line.failedUploadMbps) / total
  const badScore = Math.max(0, 100 - badRatio * 200)

  // 7. 延迟和抖动（约束指标，非首要）
  const constraintScore = isSubNetwork ? 30 : 60

  const total2 = (
    effectiveScore * w.effectiveUpload +
    breakthroughScore * w.breakthroughRate +
    totalEffectiveScore * w.totalEffective +
    remainingScore * w.remainingBreakthroughSpace +
    platformScore * w.platformConfirmed +
    badScore * w.retransmissionAndFailed +
    constraintScore * w.latencyAndJitter
  )

  return Math.round(total2 * 100) / 100
}

function computeRecommendedWeight(line, score, mode) {
  if (line.probeStage === PROBE_STAGE.FAULT) {
    return { weight: 0, reason: '线路故障，停止分配' }
  }
  if (line.probeStage === PROBE_STAGE.WAITING) {
    return { weight: 1, reason: '等待业务连接' }
  }
  // 突破率越高，权重越高
  const breakthroughBonus = line.advertisedBreakthroughPercent > 100 ? 1.2 : 1.0
  const weight = Math.max(1, Math.round(score / 3 * breakthroughBonus))
  return { weight, reason: `评分${score}，突破率${line.advertisedBreakthroughPercent}%` }
}

export const probeSchedulingService = {
  /**
   * 获取所有探测线路
   */
  getLines(mode) {
    const m = mode || OPTIMIZATION_MODE.NETWORK
    const results = mockProbeLines.map(l => {
      const score = computeScore(l, m)
      const recommended = computeRecommendedWeight(l, score, m)
      return {
        ...l,
        probeStageLabel: PROBE_STAGE_LABEL[l.probeStage] || l.probeStage,
        probeDirectionLabel: PROBE_DIRECTION_LABEL[l.probeDirection] || l.probeDirection,
        score,
        recommendedWeight: recommended.weight,
        weightReason: recommended.reason,
      }
    })
    return response(results)
  },

  /**
   * 模拟一次探测 tick
   */
  tick(mode) {
    const m = mode || OPTIMIZATION_MODE.NETWORK
    const results = mockProbeLines.map(l => {
      const updated = simulateProbeTick(l, m)
      const score = computeScore(updated, m)
      const recommended = computeRecommendedWeight(updated, score, m)
      return {
        ...updated,
        probeStageLabel: PROBE_STAGE_LABEL[updated.probeStage] || updated.probeStage,
        probeDirectionLabel: PROBE_DIRECTION_LABEL[updated.probeDirection] || updated.probeDirection,
        score,
        recommendedWeight: recommended.weight,
        weightReason: recommended.reason,
      }
    })
    return response(results)
  },

  /**
   * 获取汇总数据
   */
  getSummary(mode) {
    const m = mode || OPTIMIZATION_MODE.NETWORK
    const active = mockProbeLines.filter(l => l.probeStage !== PROBE_STAGE.FAULT && l.probeStage !== PROBE_STAGE.WAITING)
    const totalAdvertised = sumBy(active, 'advertisedUploadMbps')
    const totalEffective = sumBy(active, 'currentEffectiveUploadMbps')
    const totalSustained = sumBy(active, 'sustainedMaximumMbps')
    const totalBurst = sumBy(active, 'burstMaximumMbps')
    const totalRaw = sumBy(active, 'currentRawUploadMbps')
    const totalRetransmission = sumBy(active, 'retransmissionMbps')

    return response({
      mode: m,
      totalAdvertisedUploadMbps: totalAdvertised,
      currentTotalEffectiveUploadMbps: totalEffective,
      discoveredSustainedMaximumMbps: totalSustained,
      historicalBurstMaximumMbps: totalBurst,
      comprehensiveBreakthroughPercent: totalAdvertised > 0
        ? Math.round((totalSustained / totalAdvertised) * 10000) / 100 : 0,
      currentMaximumUtilizationPercent: totalSustained > 0
        ? Math.round((totalEffective / totalSustained) * 10000) / 100 : 0,
      totalRawUploadMbps: totalRaw,
      totalRetransmissionMbps: totalRetransmission,
      retransmissionRatioPercent: totalRaw > 0
        ? Math.round((totalRetransmission / totalRaw) * 10000) / 100 : 0,
      activeLineCount: active.length,
      totalLineCount: mockProbeLines.length,
    })
  },

  /**
   * 获取 IPv4/IPv6 独立探测结果
   */
  getDualStackProbe(mode) {
    const m = mode || OPTIMIZATION_MODE.NETWORK
    const ipv4 = mockProbeLines.filter(l => l.ipFamily === 'ipv4')
    const ipv6 = mockProbeLines.filter(l => l.ipFamily === 'ipv6')

    const process = (group) => group.map(l => {
      const score = computeScore(l, m)
      const recommended = computeRecommendedWeight(l, score, m)
      return {
        ...l,
        probeStageLabel: PROBE_STAGE_LABEL[l.probeStage] || l.probeStage,
        probeDirectionLabel: PROBE_DIRECTION_LABEL[l.probeDirection] || l.probeDirection,
        score,
        recommendedWeight: recommended.weight,
        weightReason: recommended.reason,
      }
    })

    return response({
      ipv4: process(ipv4),
      ipv6: process(ipv6),
      notice: 'IPv4 和 IPv6 极限独立探测，不假设同一宽带的极限相同。',
    })
  },

  /**
   * 获取探测参数
   */
  getProbeParams() {
    return response(DEFAULT_PROBE_PARAMS)
  },

  /**
   * 获取评分权重
   */
  getScoringWeights() {
    return response(BREAKTHROUGH_SCORING_WEIGHTS)
  },

  /**
   * 获取线路突破贡献排名
   */
  getBreakthroughRanking() {
    const ranked = mockProbeLines
      .filter(l => l.probeStage !== PROBE_STAGE.FAULT)
      .map(l => ({
        lineId: l.lineId,
        lineName: l.lineName,
        ipFamily: l.ipFamily,
        advertisedUploadMbps: l.advertisedUploadMbps,
        sustainedMaximumMbps: l.sustainedMaximumMbps,
        burstMaximumMbps: l.burstMaximumMbps,
        breakthroughPercent: calcBreakthroughPercent(l.sustainedMaximumMbps, l.advertisedUploadMbps),
        currentEffectiveUploadMbps: l.currentEffectiveUploadMbps,
        contribution: l.sustainedMaximumMbps - l.advertisedUploadMbps,
      }))
      .sort((a, b) => b.contribution - a.contribution)

    return response(ranked)
  },
}
