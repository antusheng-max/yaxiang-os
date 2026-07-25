import {
  LINE_SCORE_WEIGHTS,
  LOCAL_PROVINCE,
  SCHEDULING_RULES,
  TRAFFIC_WINDOWS,
} from '../models/trafficAnalytics.js'
// 生产安全: 不静态导入dev-mock
const mockActiveFlows = []
const mockCarrierTraffic = []
const mockDailyHistory = []
const mockGeoTraffic = []
const mockHistorySeries = []
const mockLineTrafficContribution = []
const mockQualityLines = []
const mockSchedulingSettings = []
const mockTrafficOverviewByWindow = []
const mockWanCarrierTraffic = []
const mockWeightChangeLogs = []

const DEMO_META = Object.freeze({
  demo: true,
  source: 'mock',
  label: '演示数据',
})

let schedulingSettings = { ...mockSchedulingSettings }

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function response(data) {
  return Promise.resolve({
    data: clone(data),
    meta: { ...DEMO_META, generatedAt: '2026-07-23 15:30:00' },
  })
}

function protocolBytes(item, protocol) {
  if (protocol === 'ipv4') return item.ipv4Bytes
  if (protocol === 'ipv6') return item.ipv6Bytes
  return item.totalBytes
}

export const trafficAnalyticsService = {
  getWindows: () => response(TRAFFIC_WINDOWS),
  getOverview: (window = '5m') => {
    const overview = mockTrafficOverviewByWindow[window] ?? mockTrafficOverviewByWindow['5m']
    return response({
      ...overview,
      lineContribution: mockLineTrafficContribution,
    })
  },
  getHistory: ({ window = '24h' } = {}) => response({
    window,
    series: mockHistorySeries,
    daily: mockDailyHistory,
  }),
}

export const geoTrafficService = {
  getAnalysis: ({ protocol = 'all', window = '24h' } = {}) => {
    const rows = mockGeoTraffic.map((item) => {
      const totalBytes = protocolBytes(item, protocol)
      const ratio = item.totalBytes > 0 ? totalBytes / item.totalBytes : 0
      return {
        ...item,
        totalBytes,
        uploadBytes: item.uploadBytes * ratio,
        downloadBytes: item.downloadBytes * ratio,
        connections: Math.round(item.connections * ratio),
      }
    })
    const recognized = rows.filter((item) => item.recognized)
    const localBytes = recognized
      .filter((item) => item.province === LOCAL_PROVINCE)
      .reduce((sum, item) => sum + item.totalBytes, 0)
    const outboundBytes = recognized
      .filter((item) => item.province !== LOCAL_PROVINCE)
      .reduce((sum, item) => sum + item.totalBytes, 0)
    const identifiedBytes = localBytes + outboundBytes
    const allBytes = rows.reduce((sum, item) => sum + item.totalBytes, 0)
    const ranked = rows.map((item) => ({
      ...item,
      sharePercent: allBytes > 0 ? Number((item.totalBytes / allBytes * 100).toFixed(2)) : 0,
    })).sort((a, b) => b.totalBytes - a.totalBytes)

    return response({
      window,
      protocol,
      localProvince: LOCAL_PROVINCE,
      rows: ranked,
      mostProvince: ranked.find((item) => item.recognized)?.province ?? '-',
      leastProvince: [...ranked].reverse().find((item) => item.recognized)?.province ?? '-',
      localBytes,
      outboundBytes,
      unknownBytes: ranked.filter((item) => !item.recognized).reduce((sum, item) => sum + item.totalBytes, 0),
      outboundRate: identifiedBytes > 0 ? Number((outboundBytes / identifiedBytes * 100).toFixed(2)) : 0,
      identifiedBytes,
    })
  },
}

export const carrierTrafficService = {
  getAnalysis: ({ protocol = 'all', window = '24h' } = {}) => {
    const ranking = mockCarrierTraffic.map((item) => {
      const totalBytes = protocolBytes(item, protocol)
      const ratio = item.totalBytes > 0 ? totalBytes / item.totalBytes : 0
      return {
        ...item,
        totalBytes,
        uploadBytes: item.uploadBytes * ratio,
        downloadBytes: item.downloadBytes * ratio,
        connections: Math.round(item.connections * ratio),
      }
    }).sort((a, b) => b.totalBytes - a.totalBytes)
    const wanRows = mockWanCarrierTraffic.map((item) => {
      const ratio = protocol === 'ipv4' ? 0.66 : protocol === 'ipv6' ? 0.34 : 1
      return {
        ...item,
        onNetBytes: item.onNetBytes * ratio,
        crossNetBytes: item.crossNetBytes * ratio,
      }
    })
    const onNetBytes = wanRows.reduce((sum, item) => sum + item.onNetBytes, 0)
    const crossNetBytes = wanRows.reduce((sum, item) => sum + item.crossNetBytes, 0)
    return response({
      window,
      protocol,
      ranking,
      wanRows,
      onNetBytes,
      crossNetBytes,
      onNetRate: onNetBytes + crossNetBytes > 0
        ? Number((onNetBytes / (onNetBytes + crossNetBytes) * 100).toFixed(2))
        : 0,
    })
  },
}

export const flowTelemetryService = {
  getSummary: () => {
    const activeConnections = mockActiveFlows.length
    const ipv4Connections = mockActiveFlows.filter((item) => item.ipVersion === 'IPv4').length
    const ipv6Connections = activeConnections - ipv4Connections
    const uploadBytes = mockActiveFlows.reduce((sum, item) => sum + item.uploadBytes, 0)
    const downloadBytes = mockActiveFlows.reduce((sum, item) => sum + item.downloadBytes, 0)
    return response({
      activeConnections,
      ipv4Connections,
      ipv6Connections,
      uploadBytes,
      downloadBytes,
      averageDurationSeconds: Math.round(
        mockActiveFlows.reduce((sum, item) => sum + item.durationSeconds, 0) / activeConnections,
      ),
    })
  },
  listActiveConnections: (filters = {}) => {
    const rows = mockActiveFlows.filter((item) => {
      if (filters.ipVersion && filters.ipVersion !== 'all' && item.ipVersion !== filters.ipVersion) return false
      if (filters.carrier && filters.carrier !== 'all' && item.carrier !== filters.carrier) return false
      if (filters.province && filters.province !== 'all' && item.province !== filters.province) return false
      if (filters.lineId && filters.lineId !== 'all' && item.lineId !== filters.lineId) return false
      return true
    })
    return response(rows)
  },
}

function flattenLine(line) {
  return {
    id: line.id,
    lineId: line.id,
    name: line.name,
    carrier: line.carrier,
    vlan: line.vlan,
    ipv4Status: line.ipv4Status,
    ipv6Status: line.ipv6Status,
    healthState: line.healthState,
    ...line.metrics,
    ...line.score,
    reasons: [...line.score.reasons],
    protocolScheduling: clone(line.protocolScheduling),
  }
}

export const lineQualityService = {
  listLines: () => response(
    [...mockQualityLines]
      .sort((a, b) => a.score.rank - b.score.rank)
      .map(flattenLine),
  ),
  getMetrics: (lineId) => {
    const line = mockQualityLines.find((item) => item.id === lineId)
    return response(line ? line.metrics : null)
  },
  getScore: (lineId) => {
    const line = mockQualityLines.find((item) => item.id === lineId)
    return response(line ? line.score : null)
  },
}

export const adaptiveSchedulingService = {
  getModelDescription: () => response({
    scoreWeights: LINE_SCORE_WEIGHTS,
    rules: SCHEDULING_RULES,
    thresholds: {
      packetLossFastDropPercent: 3,
      retransmissionFastDropPercent: 3,
      failureRemovalScore: schedulingSettings.failureRemovalThreshold,
      recoveryJoinScore: schedulingSettings.recoveryJoinThreshold,
      scoreUpdateSeconds: schedulingSettings.scoreUpdateSeconds,
      weightUpdateSeconds: schedulingSettings.weightUpdateSeconds,
    },
  }),
  getRecommendations: () => {
    const goal = schedulingSettings.schedulingGoal || 'cdn_utilization'
    const targetUtilization = Number(schedulingSettings.targetUtilization) || 93
    const rows = mockQualityLines.map((line) => {
      const row = flattenLine(line)
      const protocolScheduling = {}

      for (const protocol of ['ipv4', 'ipv6']) {
        const state = { ...line.protocolScheduling[protocol] }
        if (state.healthy && state.eligible) {
          if (goal === 'lowest_latency') {
            state.score = Math.max(0, Number((100 - line.metrics.latencyMs * 0.8).toFixed(1)))
          } else if (goal === 'stability_first') {
            state.score = line.score.stabilityScore
          }

          if (goal === 'manual_weight') {
            state.recommendedWeight = state.currentWeight
          } else if (goal === 'cdn_utilization') {
            const headroom = targetUtilization - line.metrics.utilizationPercent
            let delta = headroom > 20 ? 15 : headroom > 5 ? 8 : headroom >= 0 ? -5 : -20
            if (
              line.metrics.packetLossPercent >= 3
              || line.metrics.tcpRetransmissionPercent >= 3
            ) {
              delta = -30
            }
            state.recommendedWeight = Math.max(
              schedulingSettings.minimumWeight,
              Math.min(
                schedulingSettings.maximumWeight,
                state.currentWeight + delta,
              ),
            )
          } else {
            state.recommendedWeight = Math.max(
              schedulingSettings.minimumWeight,
              Math.min(
                schedulingSettings.maximumWeight,
                Math.round(state.score * 1.5),
              ),
            )
          }
        }
        protocolScheduling[protocol] = state
      }

      return { ...row, protocolScheduling }
    })

    for (const protocol of ['ipv4', 'ipv6']) {
      rows
        .filter(row => (
          row.protocolScheduling[protocol].healthy
          && row.protocolScheduling[protocol].eligible
        ))
        .sort((a, b) =>
          b.protocolScheduling[protocol].score - a.protocolScheduling[protocol].score)
        .forEach((row, index) => {
          row.protocolScheduling[protocol].rank = index + 1
        })
    }

    return response(rows.sort((a, b) =>
      (a.protocolScheduling.ipv4.rank ?? 999) - (b.protocolScheduling.ipv4.rank ?? 999)))
  },
  getSettings: () => response(schedulingSettings),
  updateSimulationSettings: (patch) => {
    schedulingSettings = {
      ...schedulingSettings,
      ...patch,
      targetUtilization: Math.max(
        90,
        Math.min(98, Number(patch.targetUtilization ?? schedulingSettings.targetUtilization) || 93),
      ),
      demoOnly: true,
    }
    return response(schedulingSettings)
  },
  getWeightChangeLogs: () => response(mockWeightChangeLogs),
  resetSimulationSettings: () => {
    schedulingSettings = { ...mockSchedulingSettings }
    return response(schedulingSettings)
  },
}
