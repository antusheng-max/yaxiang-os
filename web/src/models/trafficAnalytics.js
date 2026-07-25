export const LOCAL_PROVINCE = '江西省'

export const TRAFFIC_WINDOWS = [
  { value: '1m', label: '最近1分钟' },
  { value: '5m', label: '最近5分钟' },
  { value: '1h', label: '最近1小时' },
  { value: '24h', label: '最近24小时' },
]

export const CARRIER_CATEGORIES = [
  '中国移动',
  '中国电信',
  '中国联通',
  '中国广电',
  '教育网',
  '云服务商',
  '海外网络',
  '其他',
  '未识别',
]

export const LINE_HEALTH_STATES = [
  '优秀',
  '良好',
  '一般',
  '拥塞',
  '高延迟',
  '高丢包',
  '离线',
]

export const LINE_SCORE_WEIGHTS = Object.freeze({
  headroomScore: 0.35,
  utilizationScore: 0.20,
  packetLossScore: 0.15,
  errorScore: 0.10,
  stabilityScore: 0.10,
  latencyJitterScore: 0.10,
})

export const SCHEDULING_GOALS = Object.freeze([
  {
    value: 'cdn_utilization',
    label: '网络优化',
    badge: '推荐',
    description: '面向内容分发网络业务，在保持线路质量的同时提高整体上行利用率。',
    detail: '本模式综合剩余上行、利用率、丢包、传输重试、稳定性、延迟和抖动计算新连接权重。',
  },
  {
    value: 'lowest_latency',
    label: '最低延迟',
    description: '优先把新连接分配给响应更快的线路。',
    detail: '延迟越低评分越高，适合交互式业务；仍会独立检查IPv4和IPv6健康状态。',
  },
  {
    value: 'stability_first',
    label: '稳定优先',
    description: '优先选择近期断线少、错误少且质量波动小的线路。',
    detail: '适合长连接和对连续性要求较高的业务，恢复线路会逐步重新加入。',
  },
  {
    value: 'manual_weight',
    label: '手动权重',
    badge: '高级',
    description: '保持人工设置的权重，不自动根据评分调整。',
    detail: '权重越高，新连接被分配到该线路的概率越大；故障线路仍会按协议独立摘除。',
  },
])

export const SCORE_FACTOR_DESCRIPTIONS = Object.freeze({
  headroomScore: {
    label: '剩余上行能力',
    description: '线路距离配置上行上限还有多少可用空间。',
    detail: '剩余能力越多，越适合承接新的上传连接。',
  },
  utilizationScore: {
    label: '当前上行利用率',
    description: '当前上传速率占配置上行带宽的比例。',
    detail: '接近目标利用率时平滑降权，避免线路突然过载。',
  },
  packetLossScore: {
    label: '丢包率',
    description: '传输过程中未成功到达的数据包比例。',
    detail: '丢包率达到3%时会触发快速降权；IPv4和IPv6分别判断。',
  },
  errorScore: {
    label: '传输重试与错误',
    description: '统计传输控制协议重传及线路错误。',
    detail: 'TCP是传输控制协议。重传率达到3%时会触发快速降权。',
  },
  stabilityScore: {
    label: '稳定性',
    description: '根据近期重连次数和质量波动评价线路稳定程度。',
    detail: '重连越少、波动越小，稳定性得分越高。',
  },
  latencyJitterScore: {
    label: '延迟与抖动',
    description: '衡量响应时间以及响应时间的波动。',
    detail: '延迟表示往返等待时间，抖动表示延迟变化幅度，数值越低越好。',
  },
})

export const SCHEDULING_RULES = Object.freeze([
  '只调度新连接。',
  '已建立连接保持原出口。',
  '空闲线路自动升权。',
  '接近目标利用率时平滑降权。',
  '高丢包和高重传快速降权。',
  '故障线路立即摘除。',
  '恢复线路逐步重新加入。',
  'IPv4和IPv6分别计算，不互相强制绑定。',
])

/**
 * @typedef {Object} LineQualityMetrics
 * @property {string} lineId
 * @property {number} latencyMs
 * @property {number} jitterMs
 * @property {number} packetLossPercent
 * @property {number} configuredUploadMbps
 * @property {number} currentUploadMbps
 * @property {number} currentDownloadMbps
 * @property {number} utilizationPercent
 * @property {number} availableUploadMbps
 * @property {number} activeConnections
 * @property {number} reconnectCount24h
 * @property {number} errorCount
 * @property {number} tcpRetransmissionPercent
 * @property {boolean} ipv4Healthy
 * @property {boolean} ipv6Healthy
 * @property {string} updatedAt
 */

/**
 * @param {Partial<LineQualityMetrics>} value
 * @returns {LineQualityMetrics}
 */
export function createLineQualityMetrics(value = {}) {
  const configuredUploadMbps = Number(value.configuredUploadMbps ?? 100)
  const currentUploadMbps = Number(value.currentUploadMbps ?? 0)
  const utilizationPercent = Number(
    value.utilizationPercent
      ?? (configuredUploadMbps > 0 ? currentUploadMbps / configuredUploadMbps * 100 : 0),
  )

  return {
    lineId: String(value.lineId ?? ''),
    latencyMs: Number(value.latencyMs ?? 0),
    jitterMs: Number(value.jitterMs ?? 0),
    packetLossPercent: Number(value.packetLossPercent ?? 0),
    configuredUploadMbps,
    currentUploadMbps,
    currentDownloadMbps: Number(value.currentDownloadMbps ?? 0),
    utilizationPercent: Number(utilizationPercent.toFixed(2)),
    availableUploadMbps: Number(
      value.availableUploadMbps
        ?? Math.max(0, configuredUploadMbps - currentUploadMbps),
    ),
    activeConnections: Number(value.activeConnections ?? 0),
    reconnectCount24h: Number(value.reconnectCount24h ?? 0),
    errorCount: Number(value.errorCount ?? 0),
    tcpRetransmissionPercent: Number(value.tcpRetransmissionPercent ?? 0),
    ipv4Healthy: value.ipv4Healthy !== false,
    ipv6Healthy: value.ipv6Healthy !== false,
    updatedAt: String(value.updatedAt ?? new Date().toISOString()),
  }
}

/**
 * @typedef {Object} LineQualityScore
 * @property {string} lineId
 * @property {number} latencyScore
 * @property {number} jitterScore
 * @property {number} latencyJitterScore
 * @property {number} packetLossScore
 * @property {number} headroomScore
 * @property {number} utilizationScore
 * @property {number} stabilityScore
 * @property {number} errorScore
 * @property {number} totalScore
 * @property {number} rank
 * @property {number} currentWeight
 * @property {number} recommendedWeight
 * @property {string[]} reasons
 */

/**
 * @param {Partial<LineQualityScore>} value
 * @returns {LineQualityScore}
 */
export function createLineQualityScore(value = {}) {
  return {
    lineId: String(value.lineId ?? ''),
    latencyScore: Number(value.latencyScore ?? 0),
    jitterScore: Number(value.jitterScore ?? 0),
    latencyJitterScore: Number(value.latencyJitterScore ?? 0),
    packetLossScore: Number(value.packetLossScore ?? 0),
    headroomScore: Number(value.headroomScore ?? 0),
    utilizationScore: Number(value.utilizationScore ?? 0),
    stabilityScore: Number(value.stabilityScore ?? 0),
    errorScore: Number(value.errorScore ?? 0),
    totalScore: Number(value.totalScore ?? 0),
    rank: Number(value.rank ?? 0),
    currentWeight: Number(value.currentWeight ?? 100),
    recommendedWeight: Number(value.recommendedWeight ?? 100),
    reasons: Array.isArray(value.reasons) ? [...value.reasons] : [],
  }
}

export function createProtocolSchedulingState(value = {}) {
  const healthy = value.healthy !== false
  const eligible = value.eligible ?? healthy
  const removed = value.removed ?? (!healthy || !eligible)
  return {
    healthy,
    healthState: String(value.healthState ?? (healthy ? '正常' : '异常')),
    eligible,
    eligibilityState: String(
      value.eligibilityState ?? (eligible ? '具备调度资格' : '不具备调度资格'),
    ),
    score: Number(value.score ?? 0),
    rank: value.rank == null ? null : Number(value.rank),
    currentWeight: Number(value.currentWeight ?? (healthy ? 100 : 0)),
    recommendedWeight: Number(value.recommendedWeight ?? (healthy ? 100 : 0)),
    failureState: String(value.failureState ?? (healthy ? '无' : '健康检查失败')),
    removed,
    removalState: String(value.removalState ?? (removed ? '已摘除' : '参与调度')),
    recoveryState: String(
      value.recoveryState ?? (removed ? '等待恢复检测' : '已正常加入'),
    ),
  }
}

export function clampScore(value) {
  return Math.max(0, Math.min(100, Number(value) || 0))
}
