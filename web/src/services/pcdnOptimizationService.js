/**
 * PCDN 上行优化服务
 * 提供优化总览、模式管理、参数配置
 */

// 生产安全: 不静态导入dev-mock
const mockPcdnLines = []
import { PCDN_MODE, PCDN_MODE_LABEL, IP_FAMILY, IP_FAMILY_LABEL, PCDN_LINE_STATUS, PCDN_LINE_STATUS_LABEL } from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

let lines = clone(mockPcdnLines)
let currentMode = PCDN_MODE.MAX_EFFECTIVE

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function response(data) {
  return Promise.resolve({
    data: clone(data),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

function sumBy(arr, key) {
  return arr.reduce((s, item) => s + (item[key] || 0), 0)
}

function avgBy(arr, key) {
  const valid = arr.filter(item => item[key] !== undefined && item[key] !== null)
  return valid.length ? valid.reduce((s, item) => s + item[key], 0) / valid.length : 0
}

function computeSummary(lineList) {
  const totalConfigured = sumBy(lineList, 'configuredUploadMbps')
  const totalLearned = sumBy(lineList, 'learnedCapacityMbps')
  const totalSafe = sumBy(lineList, 'safeCapacityMbps')
  const totalPhysical = sumBy(lineList, 'physicalUploadMbps')
  const totalEffective = sumBy(lineList, 'effectiveUploadMbps')
  const totalRetransmission = sumBy(lineList, 'retransmissionMbps')
  const totalConnections = sumBy(lineList, 'activeConnections')

  const physicalUtilization = totalSafe > 0 ? (totalPhysical / totalSafe) * 100 : 0
  const safeCapacityAchievement = totalSafe > 0 ? (totalEffective / totalSafe) * 100 : 0
  const retransmissionRate = totalPhysical > 0 ? (totalRetransmission / totalPhysical) * 100 : 0

  const ipv4Lines = lineList.filter(l => l.ipFamily === IP_FAMILY.IPV4 && l.schedulingEligible)
  const ipv6Lines = lineList.filter(l => l.ipFamily === IP_FAMILY.IPV6 && l.schedulingEligible)

  return {
    totalConfiguredUploadMbps: totalConfigured,
    autoLearnedCapacityMbps: totalLearned,
    safeAvailableUploadMbps: totalSafe,
    currentTotalUploadMbps: totalPhysical,
    currentEffectiveUploadMbps: totalEffective,
    safeCapacityAchievementPercent: Math.round(safeCapacityAchievement * 10) / 10,
    physicalUtilizationPercent: Math.round(physicalUtilization * 10) / 10,
    tcpRetransmissionPercent: Math.round(retransmissionRate * 100) / 100,
    activeConnections: totalConnections,
    ipv4EligibleLines: ipv4Lines.length,
    ipv6EligibleLines: ipv6Lines.length,
  }
}

export const pcdnOptimizationService = {
  /**
   * 获取优化总览数据
   */
  getOverview() {
    const summary = computeSummary(lines)
    return response({
      mode: currentMode,
      modeLabel: PCDN_MODE_LABEL[currentMode],
      summary,
      lines: lines.map(l => ({
        ...l,
        healthStatusLabel: PCDN_LINE_STATUS_LABEL[l.healthStatus] || l.healthStatus,
        ipFamilyLabel: IP_FAMILY_LABEL[l.ipFamily] || l.ipFamily,
      })),
    })
  },

  /**
   * 获取线路列表（按 IP 协议族分组）
   */
  getLines(ipFamily) {
    let filtered = lines
    if (ipFamily) {
      filtered = lines.filter(l => l.ipFamily === ipFamily)
    }
    return response({
      lines: filtered.map(l => ({
        ...l,
        healthStatusLabel: PCDN_LINE_STATUS_LABEL[l.healthStatus] || l.healthStatus,
        ipFamilyLabel: IP_FAMILY_LABEL[l.ipFamily] || l.ipFamily,
      })),
    })
  },

  /**
   * 切换优化模式
   */
  setMode(mode) {
    if (Object.values(PCDN_MODE).includes(mode)) {
      currentMode = mode
    }
    return response({ mode: currentMode, modeLabel: PCDN_MODE_LABEL[currentMode] })
  },

  /**
   * 获取当前模式
   */
  getMode() {
    return response({ mode: currentMode, modeLabel: PCDN_MODE_LABEL[currentMode] })
  },

  /**
   * 获取单条线路详情
   */
  getLineDetail(lineId) {
    const line = lines.find(l => l.lineId === lineId)
    if (!line) return response({ error: '线路不存在' })
    return response({
      ...line,
      healthStatusLabel: PCDN_LINE_STATUS_LABEL[line.healthStatus] || line.healthStatus,
      ipFamilyLabel: IP_FAMILY_LABEL[line.ipFamily] || line.ipFamily,
    })
  },

  /**
   * 获取 IPv4 / IPv6 独立统计
   */
  getDualStackStats() {
    const ipv4Lines = lines.filter(l => l.ipFamily === IP_FAMILY.IPV4)
    const ipv6Lines = lines.filter(l => l.ipFamily === IP_FAMILY.IPV6)
    return response({
      ipv4: {
        count: ipv4Lines.length,
        eligible: ipv4Lines.filter(l => l.schedulingEligible).length,
        totalEffective: sumBy(ipv4Lines, 'effectiveUploadMbps'),
        totalPhysical: sumBy(ipv4Lines, 'physicalUploadMbps'),
        avgRetransmission: avgBy(ipv4Lines, 'tcpRetransmissionPercent'),
      },
      ipv6: {
        count: ipv6Lines.length,
        eligible: ipv6Lines.filter(l => l.schedulingEligible).length,
        totalEffective: sumBy(ipv6Lines, 'effectiveUploadMbps'),
        totalPhysical: sumBy(ipv6Lines, 'physicalUploadMbps'),
        avgRetransmission: avgBy(ipv6Lines, 'tcpRetransmissionPercent'),
      },
    })
  },
}
