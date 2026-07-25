/**
 * 本网流量控制 — Mock 数据
 * 10+ 场景覆盖各种流量分类状态
 */

import {
  createIpPrefixLocation,
  createFlowRegionClassification,
  createProvincialLineConfig,
  FLOW_CATEGORY,
  GEO_SOURCE,
} from '../models/provincialTrafficControl.js'

const GB = 1024 ** 3
const MB = 1024 ** 2

// ========== IP归属Mock数据库 ==========

export const mockIpPrefixLocations = [
  createIpPrefixLocation({ cidr: '223.86.42.0/24', ipFamily: 'ipv4', province: '江西', carrier: 'telecom', city: '南昌', asn: '4134', organization: '中国电信江西', confidence: 95 }),
  createIpPrefixLocation({ cidr: '223.86.43.0/24', ipFamily: 'ipv4', province: '江西', carrier: 'telecom', city: '赣州', asn: '4134', confidence: 93 }),
  createIpPrefixLocation({ cidr: '111.72.0.0/16', ipFamily: 'ipv4', province: '江西', carrier: 'mobile', city: '南昌', asn: '9808', organization: '中国移动江西', confidence: 90 }),
  createIpPrefixLocation({ cidr: '125.92.0.0/16', ipFamily: 'ipv4', province: '江西', carrier: 'unicom', city: '南昌', asn: '4837', confidence: 88 }),
  createIpPrefixLocation({ cidr: '120.197.0.0/16', ipFamily: 'ipv4', province: '广东', carrier: 'telecom', city: '广州', asn: '4134', confidence: 95 }),
  createIpPrefixLocation({ cidr: '183.232.0.0/16', ipFamily: 'ipv4', province: '广东', carrier: 'mobile', city: '深圳', asn: '9808', confidence: 92 }),
  createIpPrefixLocation({ cidr: '60.190.0.0/16', ipFamily: 'ipv4', province: '浙江', carrier: 'telecom', city: '杭州', asn: '4134', confidence: 94 }),
  createIpPrefixLocation({ cidr: '60.191.0.0/16', ipFamily: 'ipv4', province: '浙江', carrier: 'mobile', city: '宁波', asn: '9808', confidence: 85 }),
  createIpPrefixLocation({ cidr: '2408:8456::/32', ipFamily: 'ipv6', province: '江西', carrier: 'telecom', city: '南昌', asn: '4134', confidence: 91 }),
  createIpPrefixLocation({ cidr: '2408:8220::/32', ipFamily: 'ipv6', province: '广东', carrier: 'mobile', city: '广州', asn: '9808', confidence: 88 }),
  createIpPrefixLocation({ cidr: '240e:1::/32', ipFamily: 'ipv6', province: '浙江', carrier: 'telecom', city: '杭州', asn: '4134', confidence: 89 }),
  // 低可信度数据
  createIpPrefixLocation({ cidr: '114.114.114.0/24', ipFamily: 'ipv4', province: '江苏', carrier: 'unknown', city: '', asn: '', confidence: 35, source: GEO_SOURCE.MOCK }),
  createIpPrefixLocation({ cidr: '8.8.8.0/24', ipFamily: 'ipv4', province: '', country: '美国', carrier: 'unknown', city: '', asn: '15169', organization: 'Google', confidence: 20 }),
]

// ========== 线路配置 ==========

export const mockProvincialLines = [
  createProvincialLineConfig({ lineId: 'line-01', lineName: '电信线路A', localProvince: '江西', localCarrier: 'telecom', wanInterface: 'pppoe-wan1', ipv4Eligible: true, ipv6Eligible: true }),
  createProvincialLineConfig({ lineId: 'line-02', lineName: '电信线路B', localProvince: '江西', localCarrier: 'telecom', wanInterface: 'pppoe-wan2', ipv4Eligible: true, ipv6Eligible: true }),
  createProvincialLineConfig({ lineId: 'line-03', lineName: '移动线路C', localProvince: '江西', localCarrier: 'mobile', wanInterface: 'pppoe-wan3', ipv4Eligible: true, ipv6Eligible: false }),
  createProvincialLineConfig({ lineId: 'line-04', lineName: '联通线路D', localProvince: '江西', localCarrier: 'unicom', wanInterface: 'pppoe-wan4', ipv4Eligible: true, ipv6Eligible: true }),
  createProvincialLineConfig({ lineId: 'line-05', lineName: '广电线路E', localProvince: '江西', localCarrier: 'broadnet', wanInterface: 'pppoe-wan5', ipv4Eligible: true, ipv6Eligible: false }),
  createProvincialLineConfig({ lineId: 'line-06', lineName: '电信线路F', localProvince: '江西', localCarrier: 'telecom', wanInterface: 'pppoe-wan6', ipv4Eligible: true, ipv6Eligible: true }),
]

// ========== 连接地域分类Mock数据 ==========

export const mockFlowClassifications = [
  // 1. 江西电信同省同网高流量
  createFlowRegionClassification({ connectionId: 'conn-001', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'telecom', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 320 * GB, rawBytes: 345 * GB, retransmissionBytes: 8 * GB, confidence: 95 }),
  createFlowRegionClassification({ connectionId: 'conn-002', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'telecom', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-02', businessType: '网络上行', effectiveBytes: 280 * GB, rawBytes: 302 * GB, retransmissionBytes: 6 * GB, confidence: 93 }),

  // 2. 江西移动同省异网流量
  createFlowRegionClassification({ connectionId: 'conn-003', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'mobile', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.SAME_PROVINCE_DIFF_CARRIER, wanLineId: 'line-03', businessType: '网络上行', effectiveBytes: 145 * GB, rawBytes: 158 * GB, retransmissionBytes: 5 * GB, confidence: 90 }),
  createFlowRegionClassification({ connectionId: 'conn-004', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'telecom', destinationProvince: '江西', destinationCarrier: 'mobile', category: FLOW_CATEGORY.SAME_PROVINCE_DIFF_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 92 * GB, rawBytes: 100 * GB, retransmissionBytes: 3 * GB, confidence: 88 }),

  // 3. 广东电信跨省同网流量
  createFlowRegionClassification({ connectionId: 'conn-005', ipFamily: 'ipv4', sourceProvince: '广东', sourceCarrier: 'telecom', destinationProvince: '广东', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 180 * GB, rawBytes: 195 * GB, retransmissionBytes: 7 * GB, confidence: 95 }),
  createFlowRegionClassification({ connectionId: 'conn-006', ipFamily: 'ipv4', sourceProvince: '广东', sourceCarrier: 'telecom', destinationProvince: '广东', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-02', businessType: '网络上行', effectiveBytes: 165 * GB, rawBytes: 178 * GB, retransmissionBytes: 6 * GB, confidence: 94 }),

  // 4. 浙江移动跨省异网流量
  createFlowRegionClassification({ connectionId: 'conn-007', ipFamily: 'ipv4', sourceProvince: '浙江', sourceCarrier: 'mobile', destinationProvince: '浙江', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER, wanLineId: 'line-03', businessType: '网络上行', effectiveBytes: 110 * GB, rawBytes: 122 * GB, retransmissionBytes: 5 * GB, confidence: 85 }),
  createFlowRegionClassification({ connectionId: 'conn-008', ipFamily: 'ipv4', sourceProvince: '浙江', sourceCarrier: 'telecom', destinationProvince: '浙江', destinationCarrier: 'mobile', category: FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 88 * GB, rawBytes: 95 * GB, retransmissionBytes: 3 * GB, confidence: 82 }),

  // 5. IPv6省份已识别流量
  createFlowRegionClassification({ connectionId: 'conn-009', ipFamily: 'ipv6', sourceProvince: '江西', sourceCarrier: 'telecom', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 75 * GB, rawBytes: 82 * GB, retransmissionBytes: 2 * GB, confidence: 91 }),
  createFlowRegionClassification({ connectionId: 'conn-010', ipFamily: 'ipv6', sourceProvince: '广东', sourceCarrier: 'telecom', destinationProvince: '广东', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-02', businessType: '网络上行', effectiveBytes: 52 * GB, rawBytes: 58 * GB, retransmissionBytes: 2 * GB, confidence: 88 }),

  // 6. IPv6未知流量
  createFlowRegionClassification({ connectionId: 'conn-011', ipFamily: 'ipv6', sourceProvince: '', sourceCarrier: 'unknown', destinationProvince: '', destinationCarrier: 'unknown', category: FLOW_CATEGORY.UNKNOWN, wanLineId: 'line-04', businessType: '网络上行', effectiveBytes: 38 * GB, rawBytes: 42 * GB, retransmissionBytes: 1 * GB, confidence: 15 }),

  // 7. 数据库低可信度流量
  createFlowRegionClassification({ connectionId: 'conn-012', ipFamily: 'ipv4', sourceProvince: '江苏', sourceCarrier: 'unknown', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_DIFF_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 15 * GB, rawBytes: 18 * GB, retransmissionBytes: 1 * GB, confidence: 35 }),

  // 8. 出省率接近目标的边界流量
  createFlowRegionClassification({ connectionId: 'conn-013', ipFamily: 'ipv4', sourceProvince: '湖南', sourceCarrier: 'telecom', destinationProvince: '湖南', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-06', businessType: '网络上行', effectiveBytes: 62 * GB, rawBytes: 68 * GB, retransmissionBytes: 3 * GB, confidence: 87 }),

  // 9. 出省率超过硬上限的流量
  createFlowRegionClassification({ connectionId: 'conn-014', ipFamily: 'ipv4', sourceProvince: '北京', sourceCarrier: 'unicom', destinationProvince: '北京', destinationCarrier: 'unicom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-04', businessType: '网络上行', effectiveBytes: 45 * GB, rawBytes: 50 * GB, retransmissionBytes: 2 * GB, confidence: 90 }),
  createFlowRegionClassification({ connectionId: 'conn-015', ipFamily: 'ipv4', sourceProvince: '上海', sourceCarrier: 'telecom', destinationProvince: '上海', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-01', businessType: '网络上行', effectiveBytes: 38 * GB, rawBytes: 42 * GB, retransmissionBytes: 2 * GB, confidence: 92 }),

  // 10. 平台任务不足导致省内比例无法继续提升
  createFlowRegionClassification({ connectionId: 'conn-016', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'telecom', destinationProvince: '江西', destinationCarrier: 'telecom', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-02', businessType: '网络上行', effectiveBytes: 25 * GB, rawBytes: 27 * GB, retransmissionBytes: 1 * GB, confidence: 93 }),

  // 补充流量
  createFlowRegionClassification({ connectionId: 'conn-017', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'unicom', destinationProvince: '江西', destinationCarrier: 'unicom', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-04', businessType: '网络上行', effectiveBytes: 68 * GB, rawBytes: 74 * GB, retransmissionBytes: 2 * GB, confidence: 88 }),
  createFlowRegionClassification({ connectionId: 'conn-018', ipFamily: 'ipv6', sourceProvince: '广东', sourceCarrier: 'mobile', destinationProvince: '广东', destinationCarrier: 'mobile', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-02', businessType: '网络上行', effectiveBytes: 28 * GB, rawBytes: 32 * GB, retransmissionBytes: 1 * GB, confidence: 86 }),
  createFlowRegionClassification({ connectionId: 'conn-019', ipFamily: 'ipv4', sourceProvince: '江西', sourceCarrier: 'broadnet', destinationProvince: '江西', destinationCarrier: 'broadnet', category: FLOW_CATEGORY.SAME_PROVINCE_SAME_CARRIER, wanLineId: 'line-05', businessType: '网络上行', effectiveBytes: 42 * GB, rawBytes: 46 * GB, retransmissionBytes: 1 * GB, confidence: 80 }),
  createFlowRegionClassification({ connectionId: 'conn-020', ipFamily: 'ipv4', sourceProvince: '福建', sourceCarrier: 'telecom', destinationProvince: '福建', destinationCarrier: 'telecom', category: FLOW_CATEGORY.CROSS_PROVINCE_SAME_CARRIER, wanLineId: 'line-06', businessType: '网络上行', effectiveBytes: 55 * GB, rawBytes: 60 * GB, retransmissionBytes: 2 * GB, confidence: 91 }),
]

// ========== 历史趋势Mock数据 ==========

function generateTrendData(hours, baseRate, variance) {
  return Array.from({ length: hours }, (_, i) => {
    const t = i / hours
    const noise = (Math.sin(i / 5) + Math.random() * 0.6 - 0.3) * variance
    return {
      timestamp: new Date(Date.now() - (hours - i) * 3600000).toISOString(),
      overallRate: Math.max(0, Math.min(100, Math.round((baseRate + noise) * 100) / 100)),
      sameProvinceSameCarrierGb: Math.round((200 + Math.random() * 80) * 10) / 10,
      sameProvinceDiffCarrierGb: Math.round((80 + Math.random() * 40) * 10) / 10,
      crossProvinceSameCarrierGb: Math.round((120 + Math.random() * 60) * 10) / 10,
      crossProvinceDiffCarrierGb: Math.round((60 + Math.random() * 30) * 10) / 10,
      unknownGb: Math.round((20 + Math.random() * 15) * 10) / 10,
      totalEffectiveGb: Math.round((480 + Math.random() * 100) * 10) / 10,
      reducedUploadGb: Math.round((Math.random() * 30) * 10) / 10,
    }
  })
}

export const mockTrendData = {
  last5min: generateTrendData(5, 28, 3),
  last1hour: generateTrendData(60, 29, 5),
  last24hours: generateTrendData(24, 30, 8),
  last7days: generateTrendData(7, 31, 10),
}

// ========== 控制历史Mock ==========

export const mockControlHistory = [
  { id: 'ctrl-001', time: '2026-07-24 18:00:00', action: 'reduce-cross-province-weight', actionLabel: '降低跨省权重', targetLine: 'line-01', ipFamily: 'ipv4', rateBefore: 28, rateAfter: 25, reason: '出省率接近目标30%', triggerMetrics: 'overallRate=29.8%, trend=up', result: '跨省新连接权重降低20%' },
  { id: 'ctrl-002', time: '2026-07-24 17:45:00', action: 'prefer-intra-province-pool', actionLabel: '优先省内线路池', targetLine: 'line-02', ipFamily: 'ipv4', rateBefore: 31, rateAfter: 28, reason: '出省率超过目标', triggerMetrics: 'overallRate=31.2% > target=30%', result: '新连接优先分配到省内线路' },
  { id: 'ctrl-003', time: '2026-07-24 17:30:00', action: 'block-new-cross-province', actionLabel: '限制新跨省连接', targetLine: 'line-04', ipFamily: 'ipv4', rateBefore: 52, rateAfter: 48, reason: '出省率超过硬上限50%', triggerMetrics: 'overallRate=52.1% > hardLimit=50%', result: '停止新跨省连接分配' },
  { id: 'ctrl-004', time: '2026-07-24 17:15:00', action: 'restore-normal', actionLabel: '恢复正常调度', targetLine: 'line-01', ipFamily: 'ipv4', rateBefore: 48, rateAfter: 26, reason: '出省率降至安全范围', triggerMetrics: 'overallRate=26.3% < target=30%', result: '恢复正常调度权重' },
  { id: 'ctrl-005', time: '2026-07-24 17:00:00', action: 'reduce-cross-province-weight', actionLabel: '降低跨省权重', targetLine: 'line-03', ipFamily: 'ipv6', rateBefore: 35, rateAfter: 30, reason: 'IPv6出省率偏高', triggerMetrics: 'ipv6Rate=34.8%, target=30%', result: 'IPv6跨省权重降低15%' },
]

// ========== 平台适配Mock ==========

export const mockPlatformRegionData = {
  hasData: false,
  message: '当前仅依据网络层IP归属进行估算和控制。',
  data: null,
}
