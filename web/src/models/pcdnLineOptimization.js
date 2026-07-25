/**
 * 次网络优化 — 线路优化数据模型
 * 纯前端模型定义，不包含真实网络配置写入逻辑
 */

export const PCDN_LINE_STATUS = Object.freeze({
  HEALTHY: 'healthy',
  WARNING: 'warning',
  DEGRADED: 'degraded',
  FAULT: 'fault',
  OFFLINE: 'offline',
})

export const PCDN_LINE_STATUS_LABEL = Object.freeze({
  [PCDN_LINE_STATUS.HEALTHY]: '健康',
  [PCDN_LINE_STATUS.WARNING]: '警告',
  [PCDN_LINE_STATUS.DEGRADED]: '性能下降',
  [PCDN_LINE_STATUS.FAULT]: '故障',
  [PCDN_LINE_STATUS.OFFLINE]: '离线',
})

export const PCDN_MODE = Object.freeze({
  MAX_EFFECTIVE: 'max-effective',
  STABLE_HIGH: 'stable-high',
  LOW_LATENCY: 'low-latency',
  MANUAL: 'manual',
})

export const PCDN_MODE_LABEL = Object.freeze({
  [PCDN_MODE.MAX_EFFECTIVE]: '最大有效上行',
  [PCDN_MODE.STABLE_HIGH]: '稳定高利用率',
  [PCDN_MODE.LOW_LATENCY]: '低延迟保护',
  [PCDN_MODE.MANUAL]: '手动设置',
})

export const IP_FAMILY = Object.freeze({
  IPV4: 'ipv4',
  IPV6: 'ipv6',
})

export const IP_FAMILY_LABEL = Object.freeze({
  [IP_FAMILY.IPV4]: 'IPv4',
  [IP_FAMILY.IPV6]: 'IPv6',
})

export const PLATFORM_ADAPTER_TYPE = Object.freeze({
  NONE: 'none',
  HTTP_API: 'http-api',
  LOCAL_AGENT: 'local-agent',
  LOG_FILE: 'log-file',
  CUSTOM_PLUGIN: 'custom-plugin',
})

export const PLATFORM_ADAPTER_TYPE_LABEL = Object.freeze({
  [PLATFORM_ADAPTER_TYPE.NONE]: '不接入平台，仅使用网络估算',
  [PLATFORM_ADAPTER_TYPE.HTTP_API]: '自定义 HTTP API',
  [PLATFORM_ADAPTER_TYPE.LOCAL_AGENT]: '本地 Agent',
  [PLATFORM_ADAPTER_TYPE.LOG_FILE]: '日志文件适配器',
  [PLATFORM_ADAPTER_TYPE.CUSTOM_PLUGIN]: '自定义插件',
})

/**
 * 次网络优化线路模型
 * @typedef {Object} PcdnLineOptimization
 * @property {string} lineId - 线路唯一标识
 * @property {string} lineName - 线路名称
 * @property {string} ipFamily - IP 协议族（ipv4/ipv6）
 * @property {number} configuredUploadMbps - 用户配置标称上行（Mbps）
 * @property {number} learnedCapacityMbps - 系统学习到的可持续容量（Mbps）
 * @property {number} safeCapacityMbps - 安全可用容量（Mbps）
 * @property {number} targetUtilizationPercent - 目标利用率（%）
 * @property {number} physicalUploadMbps - 物理线路当前总上传（Mbps）
 * @property {number} effectiveUploadMbps - 有效业务上行（Mbps）
 * @property {number} retransmissionMbps - TCP 重传流量（Mbps）
 * @property {number} protocolOverheadMbps - 协议开销（Mbps）
 * @property {number} failedUploadMbps - 无效或失败流量（Mbps）
 * @property {number} queueDelayMs - 队列延迟（ms）
 * @property {number} latencyMs - 基础延迟（ms）
 * @property {number} jitterMs - 抖动（ms）
 * @property {number} packetLossPercent - 丢包率（%）
 * @property {number} tcpRetransmissionPercent - TCP 重传率（%）
 * @property {number} activeConnections - 当前活跃连接数
 * @property {number} newConnectionsPerSecond - 每秒新建连接数
 * @property {number} remainingEffectiveCapacityMbps - 剩余有效容量（Mbps）
 * @property {number} currentWeight - 当前调度权重
 * @property {number} recommendedWeight - 推荐调度权重
 * @property {boolean} schedulingEligible - 是否可参与调度
 * @property {boolean} cdnInboundEligible - 是否可参与入站
 * @property {boolean} cdnOutboundEligible - 是否可参与出站
 * @property {string} healthStatus - 健康状态
 * @property {string} adjustmentReason - 最近调整原因
 * @property {string} updatedAt - 最后更新时间
 */

/**
 * 创建一条次网络优化线路记录
 */
export function createPcdnLineOptimization(overrides = {}) {
  const now = new Date().toISOString()
  return {
    lineId: '',
    lineName: '',
    ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 0,
    learnedCapacityMbps: 0,
    safeCapacityMbps: 0,
    targetUtilizationPercent: 95,
    physicalUploadMbps: 0,
    effectiveUploadMbps: 0,
    retransmissionMbps: 0,
    protocolOverheadMbps: 0,
    failedUploadMbps: 0,
    queueDelayMs: 0,
    latencyMs: 0,
    jitterMs: 0,
    packetLossPercent: 0,
    tcpRetransmissionPercent: 0,
    activeConnections: 0,
    newConnectionsPerSecond: 0,
    remainingEffectiveCapacityMbps: 0,
    currentWeight: 1,
    recommendedWeight: 1,
    schedulingEligible: true,
    cdnInboundEligible: true,
    cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY,
    adjustmentReason: '初始状态',
    updatedAt: now,
    ...overrides,
  }
}

/**
 * 评分权重配置
 */
export const DEFAULT_SCORING_WEIGHTS = Object.freeze({
  remainingCapacity: 0.35,
  effectiveThroughput: 0.20,
  lossAndRetransmission: 0.20,
  currentUtilization: 0.10,
  stability: 0.10,
  latencyAndJitter: 0.05,
})

/**
 * 默认调节参数
 */
export const DEFAULT_TUNING_PARAMS = Object.freeze({
  targetPhysicalUtilization: 95,
  autoAdjustMin: 90,
  autoAdjustMax: 98,
  defaultReservePercent: 5,
  targetSafeCapacityAchievement: 100,
})
