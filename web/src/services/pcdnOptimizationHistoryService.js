/**
 * PCDN 优化记录服务
 * 记录调度调整历史
 */

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function response(data) {
  return Promise.resolve({
    data: JSON.parse(JSON.stringify(data)),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

const mockHistoryRecords = [
  {
    id: 'rec-001',
    time: '2026-07-24 16:00:00',
    lineId: 'pcdn-004',
    lineName: '电信备用线路 D',
    ipFamily: 'ipv4',
    ipFamilyLabel: 'IPv4',
    weightBefore: 10,
    weightAfter: 35,
    utilizationBefore: 24,
    utilizationAfter: 76,
    reason: '空闲线路，剩余上行充足，升权',
    triggerMetrics: 'remainingCapacity=330Mbps, score=89.2',
    result: '权重已调整，新建连接开始分配到该线路',
  },
  {
    id: 'rec-002',
    time: '2026-07-24 16:01:00',
    lineId: 'pcdn-006',
    lineName: '广电宽带线路 F',
    ipFamily: 'ipv4',
    ipFamilyLabel: 'IPv4',
    weightBefore: 15,
    weightAfter: 5,
    utilizationBefore: 98.9,
    utilizationAfter: 98.9,
    reason: 'TCP重传率15.7%，超过安全阈值，降权保护',
    triggerMetrics: 'tcpRetransmission=15.7%, packetLoss=2.5%',
    result: '权重已降低，新连接不再优先分配到该线路',
  },
  {
    id: 'rec-003',
    time: '2026-07-24 16:02:00',
    lineId: 'pcdn-008-v6',
    lineName: '双栈线路 H',
    ipFamily: 'ipv6',
    ipFamilyLabel: 'IPv6',
    weightBefore: 5,
    weightAfter: 2,
    utilizationBefore: 95.7,
    utilizationAfter: 95.7,
    reason: 'IPv6 丢包率5%，重传率30%，故障摘除',
    triggerMetrics: 'packetLoss=5.0%, tcpRetransmission=30.0%',
    result: '线路已摘除调度，停止分配新连接',
  },
  {
    id: 'rec-004',
    time: '2026-07-24 16:03:00',
    lineId: 'pcdn-007',
    lineName: '长宽线路 G',
    ipFamily: 'ipv4',
    ipFamilyLabel: 'IPv4',
    weightBefore: 12,
    weightAfter: 4,
    utilizationBefore: 93.9,
    utilizationAfter: 93.9,
    reason: '队列延迟120ms，超过安全阈值，降权',
    triggerMetrics: 'queueDelay=120ms, latency=55ms',
    result: '权重已降低，减轻线路压力',
  },
  {
    id: 'rec-005',
    time: '2026-07-24 16:04:00',
    lineId: 'pcdn-010',
    lineName: '断线线路 J',
    ipFamily: 'ipv4',
    ipFamilyLabel: 'IPv4',
    weightBefore: 3,
    weightAfter: 0,
    utilizationBefore: 0,
    utilizationAfter: 0,
    reason: '线路断线，停止分配',
    triggerMetrics: 'packetLoss=100%',
    result: '线路已停止调度',
  },
  {
    id: 'rec-006',
    time: '2026-07-24 16:05:00',
    lineId: 'pcdn-005',
    lineName: '联通备用线路 E',
    ipFamily: 'ipv4',
    ipFamilyLabel: 'IPv4',
    weightBefore: 8,
    weightAfter: 30,
    utilizationBefore: 25,
    utilizationAfter: 72,
    reason: '空闲线路，剩余上行充足，升权',
    triggerMetrics: 'remainingCapacity=270Mbps, score=85.6',
    result: '权重已调整，新建连接开始分配到该线路',
  },
  {
    id: 'rec-007',
    time: '2026-07-24 16:06:00',
    lineId: 'pcdn-009-v6',
    lineName: '双栈线路 I',
    ipFamily: 'ipv6',
    ipFamilyLabel: 'IPv6',
    weightBefore: 28,
    weightAfter: 32,
    utilizationBefore: 79,
    utilizationAfter: 85,
    reason: 'IPv6 正常，有剩余容量，升权',
    triggerMetrics: 'remainingCapacity=48Mbps, score=82.1',
    result: '权重已提升，开始接收更多新连接',
  },
]

export const pcdnOptimizationHistoryService = {
  /**
   * 获取优化记录列表
   */
  getRecords(filter) {
    let records = mockHistoryRecords
    if (filter && filter.ipFamily) {
      records = records.filter(r => r.ipFamily === filter.ipFamily)
    }
    if (filter && filter.lineId) {
      records = records.filter(r => r.lineId === filter.lineId)
    }
    return response(records)
  },

  /**
   * 获取最新记录
   */
  getLatest(limit) {
    const records = mockHistoryRecords.slice(0, limit || 5)
    return response(records)
  },

  /**
   * 按线路获取记录
   */
  getByLine(lineId) {
    const records = mockHistoryRecords.filter(r => r.lineId === lineId)
    return response(records)
  },
}
