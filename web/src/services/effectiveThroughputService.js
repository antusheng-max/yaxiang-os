/**
 * 有效吞吐服务
 * 计算有效业务上行，排除重传和失败流量
 */

// 生产安全: 不静态导入dev-mock
const mockPcdnLines = []
import { IP_FAMILY } from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

function response(data) {
  return Promise.resolve({
    data: JSON.parse(JSON.stringify(data)),
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

function computeEffectiveMetrics(line) {
  const total = line.physicalUploadMbps || 0
  const effective = line.effectiveUploadMbps || 0
  const retransmission = line.retransmissionMbps || 0
  const overhead = line.protocolOverheadMbps || 0
  const failed = line.failedUploadMbps || 0

  const effectiveRatio = total > 0 ? (effective / total) * 100 : 0
  const retransmissionRatio = total > 0 ? (retransmission / total) * 100 : 0
  const overheadRatio = total > 0 ? (overhead / total) * 100 : 0
  const failedRatio = total > 0 ? (failed / total) * 100 : 0

  return {
    lineId: line.lineId,
    lineName: line.lineName,
    ipFamily: line.ipFamily,
    ipFamilyLabel: line.ipFamily === IP_FAMILY.IPV4 ? 'IPv4' : 'IPv6',
    totalUploadMbps: total,
    effectiveUploadMbps: effective,
    retransmissionMbps: retransmission,
    protocolOverheadMbps: overhead,
    failedUploadMbps: failed,
    effectiveRatioPercent: Math.round(effectiveRatio * 100) / 100,
    retransmissionRatioPercent: Math.round(retransmissionRatio * 100) / 100,
    overheadRatioPercent: Math.round(overheadRatio * 100) / 100,
    failedRatioPercent: Math.round(failedRatio * 100) / 100,
  }
}

export const effectiveThroughputService = {
  /**
   * 获取所有线路的有效吞吐指标
   */
  getEffectiveMetrics() {
    const metrics = mockPcdnLines.map(computeEffectiveMetrics)
    return response(metrics)
  },

  /**
   * 获取有效吞吐汇总
   */
  getSummary() {
    const metrics = mockPcdnLines.map(computeEffectiveMetrics)
    const totalUpload = metrics.reduce((s, m) => s + m.totalUploadMbps, 0)
    const totalEffective = metrics.reduce((s, m) => s + m.effectiveUploadMbps, 0)
    const totalRetransmission = metrics.reduce((s, m) => s + m.retransmissionMbps, 0)
    const totalFailed = metrics.reduce((s, m) => s + m.failedUploadMbps, 0)

    return response({
      totalUploadMbps: totalUpload,
      totalEffectiveMbps: totalEffective,
      totalRetransmissionMbps: totalRetransmission,
      totalFailedMbps: totalFailed,
      effectiveRatioPercent: totalUpload > 0 ? Math.round((totalEffective / totalUpload) * 10000) / 100 : 0,
      retransmissionRatioPercent: totalUpload > 0 ? Math.round((totalRetransmission / totalUpload) * 10000) / 100 : 0,
      failedRatioPercent: totalUpload > 0 ? Math.round((totalFailed / totalUpload) * 10000) / 100 : 0,
    })
  },

  /**
   * 按 IP 协议族获取有效吞吐
   */
  getByIpFamily(ipFamily) {
    const metrics = mockPcdnLines
      .filter(l => l.ipFamily === ipFamily)
      .map(computeEffectiveMetrics)
    return response(metrics)
  },
}
