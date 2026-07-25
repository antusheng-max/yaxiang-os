/**
 * 本网流量控制 — 服务层
 * 6 个服务接口：geoLocationService / flowRegionClassifierService /
 * provincialTrafficTelemetryService / provincialRateControllerService /
 * platformRegionAdapterService / provincialControlHistoryService
 *
 * 当前使用 Mock 实现，所有接口按真实后端设计，后续可直接替换。
 * 真实实现计划：nftables/eBPF 识别首包和连接 → conntrack mark 保存分类 →
 * nftables 集合保存地域前缀 → ip rule 策略路由 → tc 速率限制 → Netlink 读取计数
 */

// 生产安全: 不静态导入dev-mock
const mockIpPrefixLocations = []
const mockFlowClassifications = []
const mockProvincialLines = []
const mockTrendData = []
const mockControlHistory = []
const mockPlatformRegionData = []
import {
  FLOW_CATEGORY,
  CONTROL_MODE,
  CONTROL_STATUS,
  CONTROL_ACTION,
  CONTROL_MODE_LABEL,
  CONTROL_STATUS_LABEL,
  CONTROL_ACTION_LABEL,
  FLOW_CATEGORY_LABEL,
  CARRIERS,
  TIME_WINDOW,
  createProvincialTrafficConfig,
  calcOverallCrossProvinceRate,
  calcCarrierCrossProvinceRate,
  calcIdentificationCoverage,
  calcUnknownRatio,
} from '../models/provincialTrafficControl.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function clone(v) { return JSON.parse(JSON.stringify(v)) }
function response(data) {
  return Promise.resolve({ data: clone(data), meta: { ...DEMO_META, generatedAt: new Date().toISOString() } })
}
function sumBy(arr, key) { return arr.reduce((s, i) => s + (i[key] || 0), 0) }
function carrierLabel(val) { return CARRIERS.find(c => c.value === val)?.label || '未知' }

// ========== 1. geoLocationService — IP归属查询 ==========

export const geoLocationService = {
  /**
   * 查询单个IP的归属信息
   * 真实实现：本地离线数据库最长前缀匹配 / 商业GeoIP API
   */
  async lookup(ip, ipFamily) {
    const match = mockIpPrefixLocations.find(l => l.ipFamily === ipFamily)
    return response(match || { ...mockIpPrefixLocations[0], confidence: 0, province: '', carrier: 'unknown' })
  },

  /**
   * 批量查询IP归属
   */
  async batchLookup(ips, ipFamily) {
    return response(mockIpPrefixLocations.filter(l => l.ipFamily === ipFamily))
  },

  /**
   * 获取当前数据源信息
   */
  getSourceInfo() {
    return response({
      source: 'mock',
      sourceLabel: 'Mock数据库',
      version: 'mock-v1.0',
      totalV4Prefixes: mockIpPrefixLocations.filter(l => l.ipFamily === 'ipv4').length,
      totalV6Prefixes: mockIpPrefixLocations.filter(l => l.ipFamily === 'ipv6').length,
      lastUpdated: '2026-07-24',
      avgConfidence: 75,
    })
  },

  /**
   * 最长前缀匹配（模拟）
   * 真实实现：使用 Trie 树或 nftables set 进行最长前缀匹配
   */
  longestPrefixMatch(ip, ipFamily) {
    const match = mockIpPrefixLocations
      .filter(l => l.ipFamily === ipFamily)
      .sort((a, b) => b.cidr.split('/')[1] - a.cidr.split('/')[1])[0]
    return match || null
  },
}

// ========== 2. flowRegionClassifierService — 连接地域分类 ==========

export const flowRegionClassifierService = {
  /**
   * 获取所有连接地域分类
   */
  async getClassifications(filter) {
    let result = mockFlowClassifications
    if (filter?.ipFamily) result = result.filter(c => c.ipFamily === filter.ipFamily)
    if (filter?.category) result = result.filter(c => c.category === filter.category)
    return response(result.map(c => ({
      ...c,
      categoryLabel: FLOW_CATEGORY_LABEL[c.category] || c.category,
      sourceCarrierLabel: carrierLabel(c.sourceCarrier),
      destinationCarrierLabel: carrierLabel(c.destinationCarrier),
    })))
  },

  /**
   * 按协议族获取分类统计
   * 真实实现：读取 conntrack 表 + nftables counter
   */
  async getClassificationStats(ipFamily, config) {
    const flows = mockFlowClassifications.filter(c => c.ipFamily === ipFamily)
    const localProvince = config?.localProvince || '江西'
    const localCarrier = config?.localCarrier || 'telecom'

    const sameProvSameCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER), 'effectiveBytes')
    const sameProvDiffCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.SAME_PROVINCE_DIFF_CARRIER), 'effectiveBytes')
    const crossProvSameCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER), 'effectiveBytes')
    const crossProvDiffCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER), 'effectiveBytes')
    const unknown = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.UNKNOWN), 'effectiveBytes')
    const total = sameProvSameCarrier + sameProvDiffCarrier + crossProvSameCarrier + crossProvDiffCarrier + unknown

    return response({
      ipFamily,
      ipFamilyLabel: ipFamily === 'ipv4' ? 'IPv4' : 'IPv6',
      sameProvinceSameCarrierBytes: sameProvSameCarrier,
      sameProvinceDiffCarrierBytes: sameProvDiffCarrier,
      crossProvinceSameCarrierBytes: crossProvSameCarrier,
      crossProvinceDiffCarrierBytes: crossProvDiffCarrier,
      unknownBytes: unknown,
      totalEffectiveBytes: total,
      overallCrossProvinceRate: calcOverallCrossProvinceRate(flows),
      carrierCrossProvinceRate: calcCarrierCrossProvinceRate(flows, localCarrier),
      identificationCoverage: calcIdentificationCoverage(flows),
      unknownRatio: calcUnknownRatio(flows),
    })
  },

  /**
   * 分类新连接（模拟）
   * 真实实现：首包 hook → IP归属查询 → 分类 → conntrack mark
   */
  classifyNewConnection(srcIp, dstIp, ipFamily, wanLineId, config) {
    const srcLoc = this._lookupInternal(srcIp, ipFamily)
    const dstLoc = this._lookupInternal(dstIp, ipFamily)
    const localProvince = config?.localProvince || '江西'

    let category = FLOW_CATEGORY.UNKNOWN
    if (srcLoc?.province && dstLoc?.province) {
      const sameProvince = srcLoc.province === localProvince || dstLoc.province === localProvince
      const sameCarrier = srcLoc.carrier === dstLoc.carrier
      if (sameProvince && sameCarrier) category = FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER
      else if (sameProvince && !sameCarrier) category = FLOW_CATEGORY.SAME_PROVINCE_DIFF_CARRIER
      else if (!sameProvince && sameCarrier) category = FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER
      else category = FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER
    }

    return {
      category,
      categoryLabel: FLOW_CATEGORY_LABEL[category],
      sourceProvince: srcLoc?.province || '',
      destinationProvince: dstLoc?.province || '',
      sourceCarrier: srcLoc?.carrier || 'unknown',
      destinationCarrier: dstLoc?.carrier || 'unknown',
      confidence: Math.min(srcLoc?.confidence || 0, dstLoc?.confidence || 0),
    }
  },

  _lookupInternal(ip, ipFamily) {
    return mockIpPrefixLocations.find(l => l.ipFamily === ipFamily) || null
  },
}

// ========== 3. provincialTrafficTelemetryService — 遥测统计 ==========

export const provincialTrafficTelemetryService = {
  /**
   * 获取总览指标
   */
  async getOverview(config) {
    const cfg = config || createProvincialTrafficConfig()
    const flows = mockFlowClassifications
    const ipv4Flows = flows.filter(c => c.ipFamily === 'ipv4')
    const ipv6Flows = flows.filter(c => c.ipFamily === 'ipv6')

    const totalEffective = sumBy(flows, 'effectiveBytes')
    const sameProvSameCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER), 'effectiveBytes')
    const crossProvSameCarrier = sumBy(flows.filter(c => c.category === FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER), 'effectiveBytes')

    const ipv4Stats = await flowRegionClassifierService.getClassificationStats('ipv4', cfg)
    const ipv6Stats = await flowRegionClassifierService.getClassificationStats('ipv6', cfg)

    return response({
      localProvince: cfg.localProvince,
      localCarrier: carrierLabel(cfg.localCarrier),
      currentTotalEffectiveUpload: totalEffective,
      sameProvinceSameCarrierBytes: sameProvSameCarrier,
      crossProvinceSameCarrierBytes: crossProvSameCarrier,
      overallCrossProvinceRate: calcOverallCrossProvinceRate(flows),
      carrierCrossProvinceRate: calcCarrierCrossProvinceRate(flows, cfg.localCarrier),
      targetCrossProvinceRate: cfg.targetCrossProvinceRate,
      ipv4CrossProvinceRate: ipv4Stats.data.overallCrossProvinceRate,
      ipv6CrossProvinceRate: ipv6Stats.data.overallCrossProvinceRate,
      identificationCoverage: calcIdentificationCoverage(flows),
      unknownRatio: calcUnknownRatio(flows),
      controlStatus: CONTROL_STATUS.NORMAL,
      controlStatusLabel: CONTROL_STATUS_LABEL[CONTROL_STATUS.NORMAL],
    })
  },

  /**
   * 获取趋势数据
   */
  async getTrend(timeRange) {
    const dataMap = {
      '5min': mockTrendData.last5min,
      '1hour': mockTrendData.last1hour,
      '24hours': mockTrendData.last24hours,
      '7days': mockTrendData.last7days,
    }
    return response(dataMap[timeRange] || mockTrendData.last1hour)
  },

  /**
   * 获取线路明细
   */
  async getLineDetails(config) {
    const cfg = config || createProvincialTrafficConfig()
    const details = mockProvincialLines.map(line => {
      const lineFlows = mockFlowClassifications.filter(c => c.wanLineId === line.lineId)
      const ipv4Flows = lineFlows.filter(c => c.ipFamily === 'ipv4')
      const ipv6Flows = lineFlows.filter(c => c.ipFamily === 'ipv6')
      const ipv4SameProv = sumBy(ipv4Flows.filter(c => c.category === FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER), 'effectiveBytes')
      const ipv6SameProv = sumBy(ipv6Flows.filter(c => c.category === FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER), 'effectiveBytes')
      const unknown = sumBy(lineFlows.filter(c => c.category === FLOW_CATEGORY.UNKNOWN), 'effectiveBytes')
      const total = sumBy(lineFlows, 'effectiveBytes')

      return {
        ...line,
        localCarrierLabel: carrierLabel(line.localCarrier),
        ipv4SameProvinceBytes: ipv4SameProv,
        ipv4CrossProvinceRate: calcOverallCrossProvinceRate(ipv4Flows),
        ipv6SameProvinceBytes: ipv6SameProv,
        ipv6CrossProvinceRate: calcOverallCrossProvinceRate(ipv6Flows),
        unknownRatio: total > 0 ? Math.round((unknown / total) * 10000) / 100 : 0,
        currentWeight: 30,
        recommendedWeight: 32,
        controlAction: CONTROL_ACTION.NONE,
        controlActionLabel: CONTROL_ACTION_LABEL[CONTROL_ACTION.NONE],
        adjustmentReason: '正常调度',
      }
    })
    return response(details)
  },
}

// ========== 4. provincialRateControllerService — 控制器 ==========

export const provincialRateControllerService = {
  /**
   * 执行控制逻辑
   * 真实实现：ip rule 更新策略路由 + tc 速率限制 + nftables 规则
   */
  async evaluateAndControl(config, telemetry) {
    const cfg = config || createProvincialTrafficConfig()
    const currentRate = telemetry?.overallCrossProvinceRate || 0
    const target = cfg.targetCrossProvinceRate
    const hardLimit = cfg.hardLimitRate
    const mode = cfg.controlMode

    let status = CONTROL_STATUS.NORMAL
    let action = CONTROL_ACTION.NONE
    let reason = '出省率正常'

    // 低可信度检查
    if (telemetry?.identificationCoverage < 60) {
      status = CONTROL_STATUS.LOW_CONFIDENCE
      action = CONTROL_ACTION.NONE
      reason = '数据库可信度低，不执行强制控制'
    } else if (currentRate >= hardLimit) {
      status = CONTROL_STATUS.EXCEEDED
      action = mode === CONTROL_MODE.HARD_LIMIT ? CONTROL_ACTION.BLOCK_NEW_CROSS_PROVINCE : CONTROL_ACTION.REDUCE_CROSS_PROVINCE_WEIGHT
      reason = `出省率${currentRate}%超过硬上限${hardLimit}%`
    } else if (currentRate >= target * 0.9) {
      status = CONTROL_STATUS.APPROACHING
      action = CONTROL_ACTION.PREFER_INTRAPROVINCE_POOL
      reason = `出省率${currentRate}%接近目标${target}%`
    }

    return response({
      status,
      statusLabel: CONTROL_STATUS_LABEL[status],
      action,
      actionLabel: CONTROL_ACTION_LABEL[action],
      currentRate,
      targetRate: target,
      hardLimitRate: hardLimit,
      mode: mode,
      modeLabel: CONTROL_MODE_LABEL[mode],
      reason,
    })
  },

  /**
   * 获取控制配置
   */
  getConfig() {
    return response(createProvincialTrafficConfig())
  },

  /**
   * 更新控制配置
   */
  updateConfig(updates) {
    return response({ ...createProvincialTrafficConfig(), ...updates, updated: true })
  },

  /**
   * 获取控制模式选项
   */
  getControlModes() {
    return response(Object.entries(CONTROL_MODE_LABEL).map(([value, label]) => ({
      value,
      label,
      description: CONTROL_MODE_LABEL[value] + ': ' + (Object.freeze({
        [CONTROL_MODE.MONITOR_ONLY]: '只统计出省率，不改变线路调度。',
        [CONTROL_MODE.THROUGHPUT_PRIORITY]: '优先保持最大有效上行，在不明显降低吞吐的情况下优先同省同网流量。',
        [CONTROL_MODE.PROVINCE_PRIORITY]: '优先达到目标出省率，允许一定程度降低总有效上传。',
        [CONTROL_MODE.HARD_LIMIT]: '超过出省率硬上限后，停止或限制新的跨省业务连接。',
      }))[value],
    })))
  },
}

// ========== 5. platformRegionAdapterService — 平台适配 ==========

export const platformRegionAdapterService = {
  /**
   * 获取平台数据
   */
  async getPlatformData() {
    return response(mockPlatformRegionData)
  },

  /**
   * 检查是否有平台数据
   */
  hasData() {
    return mockPlatformRegionData.hasData
  },

  /**
   * 获取提示文字
   */
  getNotice() {
    return mockPlatformRegionData.hasData
      ? '数据来自业务平台适配器。'
      : '当前仅依据网络层IP归属进行估算和控制。'
  },

  /**
   * 获取可提供的字段列表
   */
  getAvailableFields() {
    return response([
      '任务目标IP', '客户端省份', '客户端运营商', '平台确认有效字节',
      '任务可选节点', '省内任务数量', '跨省任务数量', '任务优先级',
    ])
  },
}

// ========== 6. provincialControlHistoryService — 控制历史 ==========

export const provincialControlHistoryService = {
  /**
   * 获取控制历史记录
   */
  async getRecords(filter) {
    let records = mockControlHistory
    if (filter?.ipFamily) records = records.filter(r => r.ipFamily === filter.ipFamily)
    if (filter?.action) records = records.filter(r => r.action === filter.action)
    return response(records)
  },

  /**
   * 获取最新记录
   */
  async getLatest(limit) {
    return response(mockControlHistory.slice(0, limit || 5))
  },
}
