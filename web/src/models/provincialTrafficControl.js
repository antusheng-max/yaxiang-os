/**
 * 本网流量控制 — 数据模型
 * 基于IP归属数据库进行流量地域分类和出省率控制
 */

// ========== 流量地域分类 ==========

export const FLOW_CATEGORY = Object.freeze({
  SAME_PROVINCE_SAME_CARRIER: 'same-province-same-carrier',
  SAME_PROVINCE_DIFF_CARRIER: 'same-province-diff-carrier',
  CROSS_PROVINCE_SAME_CARRIER: 'cross-province-same-carrier',
  CROSS_PROVINCE_DIFF_CARRIER: 'cross-province-diff-carrier',
  UNKNOWN: 'unknown',
})

export const FLOW_CATEGORY_LABEL = Object.freeze({
  [FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER]: '同省同网',
  [FLOW_CATEGORY.SAME_PROVINCE_DIFF_CARRIER]: '同省异网',
  [FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER]: '跨省同网',
  [FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER]: '跨省异网',
  [FLOW_CATEGORY.UNKNOWN]: '无法确认',
})

// ========== 控制模式 ==========

export const CONTROL_MODE = Object.freeze({
  MONITOR_ONLY: 'monitor-only',
  THROUGHPUT_PRIORITY: 'throughput-priority',
  PROVINCE_PRIORITY: 'province-priority',
  HARD_LIMIT: 'hard-limit',
})

export const CONTROL_MODE_LABEL = Object.freeze({
  [CONTROL_MODE.MONITOR_ONLY]: '仅监控',
  [CONTROL_MODE.THROUGHPUT_PRIORITY]: '吞吐优先（推荐）',
  [CONTROL_MODE.PROVINCE_PRIORITY]: '省内优先',
  [CONTROL_MODE.HARD_LIMIT]: '强制上限（高级）',
})

export const CONTROL_MODE_DESCRIPTION = Object.freeze({
  [CONTROL_MODE.MONITOR_ONLY]: '只统计出省率，不改变线路调度。',
  [CONTROL_MODE.THROUGHPUT_PRIORITY]: '优先保持最大有效上行，在不明显降低吞吐的情况下优先同省同网流量。',
  [CONTROL_MODE.PROVINCE_PRIORITY]: '优先达到目标出省率，允许一定程度降低总有效上传。',
  [CONTROL_MODE.HARD_LIMIT]: '超过出省率硬上限后，停止或限制新的跨省业务连接。',
})

// ========== 控制状态 ==========

export const CONTROL_STATUS = Object.freeze({
  NORMAL: 'normal',
  APPROACHING: 'approaching',
  EXCEEDED: 'exceeded',
  THROTTLED: 'throttled',
  LOW_CONFIDENCE: 'low-confidence',
})

export const CONTROL_STATUS_LABEL = Object.freeze({
  [CONTROL_STATUS.NORMAL]: '正常调度',
  [CONTROL_STATUS.APPROACHING]: '接近目标',
  [CONTROL_STATUS.EXCEEDED]: '超过上限',
  [CONTROL_STATUS.THROTTLED]: '正在限速',
  [CONTROL_STATUS.LOW_CONFIDENCE]: '数据可信度低',
})

// ========== IP归属数据源 ==========

export const GEO_SOURCE = Object.freeze({
  MOCK: 'mock',
  LOCAL_DB: 'local-db',
  COMMERCIAL: 'commercial',
  HTTP_API: 'http-api',
  IMPORTED_CIDR: 'imported-cidr',
  CARRIER_STATS: 'carrier-stats',
})

export const GEO_SOURCE_LABEL = Object.freeze({
  [GEO_SOURCE.MOCK]: 'Mock数据库',
  [GEO_SOURCE.LOCAL_DB]: '本地离线数据库',
  [GEO_SOURCE.COMMERCIAL]: '商业GeoIP数据库',
  [GEO_SOURCE.HTTP_API]: '自定义HTTP API',
  [GEO_SOURCE.IMPORTED_CIDR]: '用户导入CIDR数据库',
  [GEO_SOURCE.CARRIER_STATS]: '运营商统计数据导入',
})

// ========== 控制动作 ==========

export const CONTROL_ACTION = Object.freeze({
  NONE: 'none',
  REDUCE_CROSS_PROVINCE_WEIGHT: 'reduce-cross-province-weight',
  PREFER_INTRAPROVINCE_POOL: 'prefer-intra-province-pool',
  BLOCK_NEW_CROSS_PROVINCE: 'block-new-cross-province',
  RESTORE_NORMAL: 'restore-normal',
})

export const CONTROL_ACTION_LABEL = Object.freeze({
  [CONTROL_ACTION.NONE]: '无动作',
  [CONTROL_ACTION.REDUCE_CROSS_PROVINCE_WEIGHT]: '降低跨省新连接权重',
  [CONTROL_ACTION.PREFER_INTRAPROVINCE_POOL]: '优先省内线路池',
  [CONTROL_ACTION.BLOCK_NEW_CROSS_PROVINCE]: '限制新跨省连接',
  [CONTROL_ACTION.RESTORE_NORMAL]: '恢复正常调度',
})

// ========== 运营商 ==========

export const CARRIERS = Object.freeze([
  { value: 'telecom', label: '中国电信' },
  { value: 'unicom', label: '中国联通' },
  { value: 'mobile', label: '中国移动' },
  { value: 'broadnet', label: '中国广电' },
  { value: 'cernet', label: '教育网' },
  { value: 'other', label: '其他' },
  { value: 'unknown', label: '未知' },
])

// ========== 时间窗口 ==========

export const TIME_WINDOW = Object.freeze({
  REALTIME: 60,        // 1分钟
  CONTROL: 300,        // 5分钟
  TREND: 3600,         // 1小时
})

// ========== IP归属模型 ==========

/**
 * @typedef {Object} IpPrefixLocation
 * @property {string} cidr - CIDR前缀
 * @property {string} ipFamily - ipv4/ipv6
 * @property {string} country - 国家
 * @property {string} province - 省份
 * @property {string} city - 城市
 * @property {string} carrier - 运营商
 * @property {string} asn - ASN号
 * @property {string} organization - 组织
 * @property {number} confidence - 可信度(0-100)
 * @property {string} source - 数据来源
 * @property {string} databaseVersion - 数据库版本
 * @property {string} updatedAt - 更新时间
 */
export function createIpPrefixLocation(overrides = {}) {
  return {
    cidr: '',
    ipFamily: 'ipv4',
    country: '中国',
    province: '',
    city: '',
    carrier: 'unknown',
    asn: '',
    organization: '',
    confidence: 80,
    source: GEO_SOURCE.MOCK,
    databaseVersion: 'mock-v1.0',
    updatedAt: new Date().toISOString(),
    ...overrides,
  }
}

// ========== 连接地域分类模型 ==========

/**
 * @typedef {Object} FlowRegionClassification
 * @property {string} connectionId - 连接ID
 * @property {string} ipFamily - ipv4/ipv6
 * @property {string} sourceProvince - 源省份
 * @property {string} sourceCarrier - 源运营商
 * @property {string} destinationProvince - 目标省份
 * @property {string} destinationCarrier - 目标运营商
 * @property {string} category - 地域分类
 * @property {string} wanLineId - WAN线路ID
 * @property {string} businessType - 业务类型
 * @property {number} effectiveBytes - 有效业务字节
 * @property {number} rawBytes - 总字节
 * @property {number} retransmissionBytes - 重传字节
 * @property {string} startedAt - 连接开始时间
 * @property {string} lastSeenAt - 最后活跃时间
 * @property {number} confidence - 可信度
 */
export function createFlowRegionClassification(overrides = {}) {
  return {
    connectionId: '',
    ipFamily: 'ipv4',
    sourceProvince: '',
    sourceCarrier: 'unknown',
    destinationProvince: '',
    destinationCarrier: 'unknown',
    category: FLOW_CATEGORY.UNKNOWN,
    wanLineId: '',
    businessType: '',
    effectiveBytes: 0,
    rawBytes: 0,
    retransmissionBytes: 0,
    startedAt: new Date().toISOString(),
    lastSeenAt: new Date().toISOString(),
    confidence: 0,
    ...overrides,
  }
}

// ========== 本网流量控制配置 ==========

/**
 * @typedef {Object} ProvincialTrafficConfig
 * @property {string} localProvince - 本地省份
 * @property {string} localCarrier - 本地运营商
 * @property {string} businessScope - 统计业务范围
 * @property {boolean} ipv4Enabled - IPv4是否参与
 * @property {boolean} ipv6Enabled - IPv6是否参与
 * @property {number} targetCrossProvinceRate - 目标出省率(%)
 * @property {number} hardLimitRate - 硬上限出省率(%)
 * @property {string} controlMode - 控制模式
 * @property {number} statsTimeWindow - 统计时间窗口(秒)
 */
export function createProvincialTrafficConfig(overrides = {}) {
  return {
    localProvince: '江西',
    localCarrier: 'telecom',
    businessScope: 'all',
    ipv4Enabled: true,
    ipv6Enabled: true,
    targetCrossProvinceRate: 30,
    hardLimitRate: 50,
    controlMode: CONTROL_MODE.THROUGHPUT_PRIORITY,
    statsTimeWindow: TIME_WINDOW.CONTROL,
    ...overrides,
  }
}

// ========== 线路配置 ==========

/**
 * @typedef {Object} ProvincialLineConfig
 * @property {string} lineId
 * @property {string} lineName
 * @property {string} localProvince
 * @property {string} localCarrier
 * @property {string} wanInterface
 * @property {boolean} ipv4Eligible
 * @property {boolean} ipv6Eligible
 */
export function createProvincialLineConfig(overrides = {}) {
  return {
    lineId: '',
    lineName: '',
    localProvince: '江西',
    localCarrier: 'telecom',
    wanInterface: '',
    ipv4Eligible: true,
    ipv6Eligible: true,
    ...overrides,
  }
}

// ========== 出省率计算 ==========

/**
 * 总体出省率 = (跨省同网有效流量 + 跨省异网有效流量) / 全部已识别有效业务流量 * 100%
 */
export function calcOverallCrossProvinceRate(classifications) {
  const identified = classifications.filter(c => c.category !== FLOW_CATEGORY.UNKNOWN)
  const total = identified.reduce((s, c) => s + c.effectiveBytes, 0)
  if (total === 0) return 0
  const crossProvince = identified
    .filter(c => c.category === FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER || c.category === FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER)
    .reduce((s, c) => s + c.effectiveBytes, 0)
  return Math.round((crossProvince / total) * 10000) / 100
}

/**
 * 本网出省率 = 跨省同运营商有效流量 / 该运营商全部已识别有效业务流量 * 100%
 */
export function calcCarrierCrossProvinceRate(classifications, carrier) {
  const carrierFlows = classifications.filter(c => c.sourceCarrier === carrier && c.category !== FLOW_CATEGORY.UNKNOWN)
  const total = carrierFlows.reduce((s, c) => s + c.effectiveBytes, 0)
  if (total === 0) return 0
  const crossProvinceSameCarrier = carrierFlows
    .filter(c => c.category === FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER)
    .reduce((s, c) => s + c.effectiveBytes, 0)
  return Math.round((crossProvinceSameCarrier / total) * 10000) / 100
}

/**
 * 识别覆盖率 = 已识别流量 / 总流量 * 100%
 */
export function calcIdentificationCoverage(classifications) {
  const total = classifications.reduce((s, c) => s + c.effectiveBytes, 0)
  if (total === 0) return 0
  const identified = classifications
    .filter(c => c.category !== FLOW_CATEGORY.UNKNOWN)
    .reduce((s, c) => s + c.effectiveBytes, 0)
  return Math.round((identified / total) * 10000) / 100
}

/**
 * 未知流量比例 = 未知流量 / 总流量 * 100%
 */
export function calcUnknownRatio(classifications) {
  const total = classifications.reduce((s, c) => s + c.effectiveBytes, 0)
  if (total === 0) return 0
  const unknown = classifications
    .filter(c => c.category === FLOW_CATEGORY.UNKNOWN)
    .reduce((s, c) => s + c.effectiveBytes, 0)
  return Math.round((unknown / total) * 10000) / 100
}
