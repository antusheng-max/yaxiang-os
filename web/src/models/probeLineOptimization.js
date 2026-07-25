/**
 * 极限探测突破模型
 * 以运营商标称上行为起点，主动探测每条线路实际能够达到的最大有效上传
 */

export const PROBE_STAGE = Object.freeze({
  WAITING: 'waiting',
  NOMINAL: 'nominal',
  STEPPING: 'stepping',
  FAST_BREAKTHROUGH: 'fast-breakthrough',
  SUSTAINED_VERIFY: 'sustained-verify',
  BURST_VERIFY: 'burst-verify',
  STAGNATION: 'stagnation',
  CONGESTION_BACKOFF: 'congestion-backoff',
  REPROBE: 'reprobe',
  LOCKED: 'locked',
  FAULT: 'fault',
})

export const PROBE_STAGE_LABEL = Object.freeze({
  [PROBE_STAGE.WAITING]: '等待业务',
  [PROBE_STAGE.NOMINAL]: '标称容量运行',
  [PROBE_STAGE.STEPPING]: '逐级加压',
  [PROBE_STAGE.FAST_BREAKTHROUGH]: '快速突破',
  [PROBE_STAGE.SUSTAINED_VERIFY]: '持续极限验证',
  [PROBE_STAGE.BURST_VERIFY]: '突发极限验证',
  [PROBE_STAGE.STAGNATION]: '有效吞吐停滞',
  [PROBE_STAGE.CONGESTION_BACKOFF]: '拥塞回退',
  [PROBE_STAGE.REPROBE]: '重新探测',
  [PROBE_STAGE.LOCKED]: '当前极限锁定',
  [PROBE_STAGE.FAULT]: '线路故障',
})

export const PROBE_DIRECTION = Object.freeze({
  UP: 'up',
  HOLD: 'hold',
  DOWN: 'down',
})

export const PROBE_DIRECTION_LABEL = Object.freeze({
  [PROBE_DIRECTION.UP]: '加压中',
  [PROBE_DIRECTION.HOLD]: '保持',
  [PROBE_DIRECTION.DOWN]: '回退',
})

export const OPTIMIZATION_MODE = Object.freeze({
  NETWORK: 'network',
  SUB_NETWORK: 'sub-network',
})

export const OPTIMIZATION_MODE_LABEL = Object.freeze({
  [OPTIMIZATION_MODE.NETWORK]: '网络优化',
  [OPTIMIZATION_MODE.SUB_NETWORK]: '次网络优化',
})

export const DEFAULT_PROBE_PARAMS = Object.freeze({
  startTargetPercent: 100,
  stepMinPercent: 2,
  stepMaxPercent: 5,
  maxProbeMultiplierDefault: 150,
  maxProbeMultiplierMin: 100,
  maxProbeMultiplierMax: 200,
  fastCheckIntervalSec: 1,
  adjustIntervalSec: 5,
  sustainedVerifyIntervalSec: 30,
  sustainedConfirmDurationMin: 3,
})

/**
 * 极限探测线路数据模型
 * @typedef {Object} ProbeLineData
 * @property {string} lineId
 * @property {string} lineName
 * @property {string} ipFamily - ipv4/ipv6
 * @property {number} advertisedUploadMbps - 套餐标称上行
 * @property {number} currentProbeTargetMbps - 当前探测目标
 * @property {number} sustainedMaximumMbps - 已发现持续极限
 * @property {number} burstMaximumMbps - 历史突发极限
 * @property {number} currentEffectiveUploadMbps - 当前有效上传
 * @property {number} currentRawUploadMbps - 当前总发送
 * @property {number} retransmissionMbps - 重传流量
 * @property {number} protocolOverheadMbps - 协议开销
 * @property {number} failedUploadMbps - 失败流量
 * @property {number} advertisedBreakthroughPercent - 标称突破率
 * @property {number} maximumUtilizationPercent - 极限利用率
 * @property {string} probeStage - 探测状态
 * @property {string} probeDirection - 探测方向
 * @property {number} probeStepMbps - 当前步长
 * @property {number} lastSuccessfulTargetMbps - 上次成功目标
 * @property {number} lastFailedTargetMbps - 上次失败目标
 * @property {number} maximumProbeMultiplier - 最大探测倍率(%)
 * @property {string} maximumConfirmedAt - 极限确认时间
 * @property {number} currentWeight - 当前权重
 * @property {number} recommendedWeight - 推荐权重
 * @property {boolean} schedulingEligible - 可调度
 * @property {string} healthStatus - 健康状态
 * @property {string} adjustmentReason - 调整原因
 * @property {string} updatedAt
 */

export function createProbeLine(overrides = {}) {
  return {
    lineId: '',
    lineName: '',
    ipFamily: 'ipv4',
    advertisedUploadMbps: 0,
    currentProbeTargetMbps: 0,
    sustainedMaximumMbps: 0,
    burstMaximumMbps: 0,
    currentEffectiveUploadMbps: 0,
    currentRawUploadMbps: 0,
    retransmissionMbps: 0,
    protocolOverheadMbps: 0,
    failedUploadMbps: 0,
    advertisedBreakthroughPercent: 0,
    maximumUtilizationPercent: 0,
    probeStage: PROBE_STAGE.WAITING,
    probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 0,
    lastSuccessfulTargetMbps: 0,
    lastFailedTargetMbps: 0,
    maximumProbeMultiplier: 150,
    maximumConfirmedAt: '',
    currentWeight: 1,
    recommendedWeight: 1,
    schedulingEligible: true,
    healthStatus: 'healthy',
    adjustmentReason: '初始状态',
    updatedAt: new Date().toISOString(),
    ...overrides,
  }
}

/**
 * 计算标称突破率
 * 持续极限 / 套餐标称上行 * 100%
 */
export function calcBreakthroughPercent(sustained, advertised) {
  if (!advertised || advertised <= 0) return 0
  return Math.round((sustained / advertised) * 10000) / 100
}

/**
 * 计算极限利用率
 * 当前有效上传 / 持续极限 * 100%
 */
export function calcMaxUtilizationPercent(effective, sustained) {
  if (!sustained || sustained <= 0) return 0
  return Math.round((effective / sustained) * 10000) / 100
}

/**
 * 调度评分权重（突破优先）
 */
export const BREAKTHROUGH_SCORING_WEIGHTS = Object.freeze({
  effectiveUpload: 0.30,
  breakthroughRate: 0.25,
  totalEffective: 0.15,
  remainingBreakthroughSpace: 0.10,
  platformConfirmed: 0.10,
  retransmissionAndFailed: 0.05,
  latencyAndJitter: 0.05,
})
