import {
  CARRIER_CATEGORIES,
  LINE_SCORE_WEIGHTS,
  LOCAL_PROVINCE,
  clampScore,
  createLineQualityMetrics,
  createLineQualityScore,
  createProtocolSchedulingState,
} from '../models/trafficAnalytics.js'

const TB = 1024 ** 4
const GB = 1024 ** 3

const lineSeeds = [
  { id: 'line-01', name: 'PPPoE-移动-01', carrier: '中国移动', vlan: 101, state: '优秀', latency: 12, jitter: 2.1, loss: 0.03, up: 26, down: 168, connections: 4380, reconnects: 0, errors: 0, weight: 130 },
  { id: 'line-02', name: 'PPPoE-电信-01', carrier: '中国电信', vlan: 102, state: '优秀', latency: 15, jitter: 2.8, loss: 0.05, up: 31, down: 192, connections: 4210, reconnects: 0, errors: 0, weight: 125 },
  { id: 'line-03', name: 'PPPoE-联通-01', carrier: '中国联通', vlan: 103, state: '优秀', latency: 17, jitter: 3.2, loss: 0.08, up: 29, down: 175, connections: 3990, reconnects: 1, errors: 0, weight: 120 },
  { id: 'line-04', name: 'PPPoE-移动-02', carrier: '中国移动', vlan: 104, state: '优秀', latency: 14, jitter: 2.5, loss: 0.04, up: 35, down: 205, connections: 4520, reconnects: 0, errors: 1, weight: 125 },
  { id: 'line-05', name: 'PPPoE-电信-02', carrier: '中国电信', vlan: 105, state: '良好', latency: 32, jitter: 7.8, loss: 0.28, up: 52, down: 248, connections: 5080, reconnects: 1, errors: 1, weight: 105 },
  { id: 'line-06', name: 'PPPoE-移动-03', carrier: '中国移动', vlan: 106, state: '良好', latency: 38, jitter: 9.2, loss: 0.42, up: 58, down: 276, connections: 5360, reconnects: 1, errors: 2, weight: 100, ipv6Healthy: false, ipv6Failure: '运营商未返回可用IPv6参数' },
  { id: 'line-07', name: 'PPPoE-电信-03', carrier: '中国电信', vlan: 107, state: '高延迟', latency: 168, jitter: 24, loss: 0.65, up: 43, down: 156, connections: 3140, reconnects: 2, errors: 3, weight: 70, ipv6Healthy: false, ipv6Failure: 'IPv6互联网连通性检测失败' },
  { id: 'line-08', name: 'PPPoE-联通-02', carrier: '中国联通', vlan: 108, state: '一般', latency: 46, jitter: 12, loss: 0.5, up: 48, down: 132, connections: 2860, reconnects: 1, errors: 2, retrans: 0.8, weight: 75, ipv4Healthy: false, ipv4Failure: 'IPv4默认路由未获得' },
  { id: 'line-09', name: 'PPPoE-广电-01', carrier: '中国广电', vlan: 109, state: '高丢包', latency: 75, jitter: 22, loss: 6.8, up: 34, down: 96, connections: 1280, reconnects: 4, errors: 7, retrans: 4.8, weight: 35, ipv4Healthy: false, ipv6Healthy: false, ipv4Failure: '高丢包，IPv4已故障摘除', ipv6Failure: '高丢包，IPv6已故障摘除' },
  { id: 'line-10', name: 'PPPoE-移动-04', carrier: '中国移动', vlan: 110, state: '拥塞', latency: 28, jitter: 6.1, loss: 0.2, up: 95, down: 214, connections: 6710, reconnects: 1, errors: 2, retrans: 0.6, weight: 60 },
]

function scoreLatency(latency) {
  if (latency <= 20) return 100
  return clampScore(100 - (latency - 20) * 0.62)
}

function scoreJitter(jitter) {
  if (jitter <= 3) return 100
  return clampScore(100 - (jitter - 3) * 1.75)
}

function scoreLoss(loss) {
  return clampScore(100 - loss * 15)
}

function reasonsFor(line, metrics, score) {
  const reasons = []
  if (!metrics.ipv4Healthy) reasons.push('IPv4 健康检查异常，仅保留 IPv6 调度')
  if (!metrics.ipv6Healthy) reasons.push('IPv6 健康检查异常，仅保留 IPv4 建议权重')
  if (metrics.packetLossPercent >= 3) reasons.push(`丢包率 ${metrics.packetLossPercent}% 明显偏高`)
  if (metrics.latencyMs >= 100) reasons.push(`平均延迟 ${metrics.latencyMs}ms 偏高`)
  if (metrics.utilizationPercent >= 90) reasons.push(`上行利用率 ${metrics.utilizationPercent}% 接近满载`)
  if (metrics.reconnectCount24h >= 3) reasons.push('24小时内重连次数较多')
  if (score.recommendedWeight > score.currentWeight && score.totalScore >= 85) {
    reasons.push('质量稳定且剩余带宽充足，建议升权')
  } else if (score.recommendedWeight > score.currentWeight) {
    reasons.push('综合评分高于当前权重，建议通过平滑机制逐步升权')
  }
  if (!reasons.length) reasons.push('线路质量与当前权重基本匹配')
  return reasons
}

function buildLines() {
  const lines = lineSeeds.map((seed) => {
    const metrics = createLineQualityMetrics({
      lineId: seed.id,
      latencyMs: seed.latency,
      jitterMs: seed.jitter,
      packetLossPercent: seed.loss,
      configuredUploadMbps: 100,
      currentUploadMbps: seed.up,
      currentDownloadMbps: seed.down,
      activeConnections: seed.connections,
      reconnectCount24h: seed.reconnects,
      errorCount: seed.errors,
      tcpRetransmissionPercent: seed.retrans ?? Number((seed.errors * 0.28 + seed.loss * 0.18).toFixed(2)),
      ipv4Healthy: seed.ipv4Healthy !== false,
      ipv6Healthy: seed.ipv6Healthy !== false,
      updatedAt: '2026-07-23 15:30:00',
    })
    const latencyScore = scoreLatency(metrics.latencyMs)
    const jitterScore = scoreJitter(metrics.jitterMs)
    const partialScore = createLineQualityScore({
      lineId: seed.id,
      latencyScore,
      jitterScore,
      latencyJitterScore: (latencyScore + jitterScore) / 2,
      packetLossScore: scoreLoss(metrics.packetLossPercent),
      headroomScore: clampScore(metrics.configuredUploadMbps > 0
        ? metrics.availableUploadMbps / metrics.configuredUploadMbps * 100
        : 0),
      utilizationScore: clampScore(100 - Math.max(0, metrics.utilizationPercent - 75) * 3.5),
      stabilityScore: clampScore(100 - metrics.reconnectCount24h * 12),
      errorScore: clampScore(
        100 - metrics.errorCount * 8 - metrics.tcpRetransmissionPercent * 12,
      ),
      currentWeight: seed.weight,
    })
    partialScore.totalScore = Number(Object.entries(LINE_SCORE_WEIGHTS)
      .reduce((sum, [key, weight]) => sum + partialScore[key] * weight, 0)
      .toFixed(1))
    let desiredWeight = Math.round(partialScore.totalScore * 1.5)
    if (!metrics.ipv6Healthy) desiredWeight = seed.weight - 10
    if (metrics.latencyMs >= 100) desiredWeight = seed.weight - 15
    if (metrics.packetLossPercent >= 3 || metrics.utilizationPercent >= 90) {
      desiredWeight = seed.weight - 20
    }
    const delta = Math.max(-20, Math.min(20, desiredWeight - seed.weight))
    partialScore.recommendedWeight = Math.max(10, Math.min(180, seed.weight + delta))
    partialScore.reasons = reasonsFor(seed, metrics, partialScore)

    const createProtocolState = (protocol) => {
      const healthy = metrics[`${protocol}Healthy`]
      const bothOffline = !metrics.ipv4Healthy && !metrics.ipv6Healthy
      const scoreOffset = protocol === 'ipv4' ? 1.8 : -1.8
      const protocolScore = healthy
        ? Number(clampScore(partialScore.totalScore + scoreOffset).toFixed(1))
        : 0
      const currentWeight = healthy
        ? Math.max(10, seed.weight + (protocol === 'ipv4' ? 0 : -5))
        : 0
      const recommendedWeight = healthy
        ? Math.max(10, Math.min(180, partialScore.recommendedWeight + (protocol === 'ipv4' ? 2 : -2)))
        : 0
      const failureState = healthy
        ? '无'
        : seed[`${protocol}Failure`] || `${protocol.toUpperCase()}健康检查失败`

      return createProtocolSchedulingState({
        healthy,
        healthState: healthy ? '正常' : bothOffline ? '离线' : '异常',
        eligible: healthy,
        eligibilityState: healthy ? '具备调度资格' : '暂不具备调度资格',
        score: protocolScore,
        currentWeight,
        recommendedWeight,
        failureState,
        removed: !healthy,
        recoveryState: healthy ? '已正常加入' : '等待连续健康检测',
      })
    }

    return {
      id: seed.id,
      name: seed.name,
      carrier: seed.carrier,
      vlan: seed.vlan,
      ipv4Status: metrics.ipv4Healthy ? '在线' : (!metrics.ipv6Healthy ? '离线' : '异常'),
      ipv6Status: metrics.ipv6Healthy ? '在线' : (!metrics.ipv4Healthy ? '离线' : '异常'),
      healthState: seed.state,
      metrics,
      score: partialScore,
      protocolScheduling: {
        ipv4: createProtocolState('ipv4'),
        ipv6: createProtocolState('ipv6'),
      },
    }
  })

  const ranked = [...lines].sort((a, b) => b.score.totalScore - a.score.totalScore)
  ranked.forEach((line, index) => {
    line.score.rank = index + 1
  })
  for (const protocol of ['ipv4', 'ipv6']) {
    const protocolRanked = lines
      .filter(line => (
        line.protocolScheduling[protocol].healthy
        && line.protocolScheduling[protocol].eligible
      ))
      .sort((a, b) =>
        b.protocolScheduling[protocol].score - a.protocolScheduling[protocol].score)
    protocolRanked.forEach((line, index) => {
      line.protocolScheduling[protocol].rank = index + 1
    })
  }
  return lines
}

export const mockQualityLines = buildLines()

function makeTrend(scale = 1, points = 30) {
  const labels = []
  const upload = []
  const download = []
  const outboundRate = []
  const connections = []
  for (let index = 0; index < points; index += 1) {
    labels.push(`${String(Math.floor(index / 2)).padStart(2, '0')}:${index % 2 ? '30' : '00'}`)
    upload.push(Number(((540 + Math.sin(index / 3) * 95 + index * 2.8) * scale).toFixed(1)))
    download.push(Number(((1080 + Math.cos(index / 4) * 180 + index * 5.2) * scale).toFixed(1)))
    outboundRate.push(Number((55 + Math.sin(index / 5) * 6).toFixed(1)))
    connections.push(Math.round(39000 + Math.sin(index / 2.6) * 4200 + index * 105))
  }
  return { labels, upload, download, outboundRate, connections }
}

const overviewFactors = {
  '1m': { factor: 0.91, points: 20 },
  '5m': { factor: 1, points: 30 },
  '1h': { factor: 1.08, points: 36 },
  '24h': { factor: 0.96, points: 48 },
}

export const mockTrafficOverviewByWindow = Object.fromEntries(
  Object.entries(overviewFactors).map(([window, config]) => {
    const trend = makeTrend(config.factor, config.points)
    const recognizedGeoBytes = 7.07 * TB
    const outboundBytes = 4.22 * TB
    return [window, {
      window,
      localProvince: LOCAL_PROVINCE,
      currentUploadMbps: Number((612.4 * config.factor).toFixed(1)),
      currentDownloadMbps: Number((1250.8 * config.factor).toFixed(1)),
      todayUploadBytes: 1.82 * TB,
      todayDownloadBytes: 5.91 * TB,
      ipv4Bytes: 4.98 * TB,
      ipv6Bytes: 2.75 * TB,
      localProvinceBytes: 2.85 * TB,
      outboundProvinceBytes: outboundBytes,
      outboundRate: Number((outboundBytes / recognizedGeoBytes * 100).toFixed(1)),
      onNetBytes: 3.88 * TB,
      crossNetBytes: 2.84 * TB,
      unknownBytes: 0.32 * TB,
      activeConnections: Math.round(42872 * config.factor),
      overallUploadUtilizationPercent: Number((61.2 * config.factor).toFixed(1)),
      lineCount: 10,
      trend,
      updatedAt: '2026-07-23 15:30:00',
    }]
  }),
)

const geoSeeds = [
  ['江西省', 2.85, 34, 282, 0.62],
  ['广东省', 1.08, 18, 214, 0.65],
  ['浙江省', 0.72, 12, 188, 0.67],
  ['江苏省', 0.65, 11, 176, 0.69],
  ['北京市', 0.42, 7.8, 205, 0.74],
  ['上海市', 0.36, 6.7, 196, 0.72],
  ['湖南省', 0.31, 5.3, 164, 0.58],
  ['湖北省', 0.28, 4.9, 158, 0.6],
  ['福建省', 0.24, 4.2, 171, 0.61],
  ['四川省', 0.16, 3.1, 152, 0.63],
  ['未识别地区', 0.18, 2.8, 96, 0.78],
]

export const mockGeoTraffic = geoSeeds.map(([province, totalTb, connectionsK, duration, ipv4Ratio], index) => {
  const totalBytes = totalTb * TB
  const uploadBytes = totalBytes * (0.24 + index % 3 * 0.025)
  return {
    id: province === '未识别地区' ? 'unknown' : `geo-${index + 1}`,
    province,
    recognized: province !== '未识别地区',
    local: province === LOCAL_PROVINCE,
    uploadBytes,
    downloadBytes: totalBytes - uploadBytes,
    totalBytes,
    ipv4Bytes: totalBytes * ipv4Ratio,
    ipv6Bytes: totalBytes * (1 - ipv4Ratio),
    connections: Math.round(connectionsK * 1000),
    averageDurationSeconds: duration,
  }
})

const carrierTotals = {
  中国移动: 2.26,
  中国电信: 1.78,
  中国联通: 1.31,
  中国广电: 0.54,
  教育网: 0.22,
  云服务商: 0.84,
  海外网络: 0.43,
  其他: 0.17,
  未识别: 0.18,
}

export const mockCarrierTraffic = CARRIER_CATEGORIES.map((carrier, index) => {
  const totalBytes = carrierTotals[carrier] * TB
  const ipv4Ratio = 0.59 + index % 4 * 0.05
  return {
    id: `carrier-${index + 1}`,
    carrier,
    recognized: carrier !== '未识别',
    totalBytes,
    uploadBytes: totalBytes * (0.22 + index % 2 * 0.04),
    downloadBytes: totalBytes * (0.78 - index % 2 * 0.04),
    ipv4Bytes: totalBytes * ipv4Ratio,
    ipv6Bytes: totalBytes * (1 - ipv4Ratio),
    connections: 5400 + index * 1680,
  }
})

export const mockWanCarrierTraffic = mockQualityLines.map((line, lineIndex) => {
  const totalBytes = (0.46 + lineIndex * 0.055) * TB
  const onNetRate = lineIndex === 7 ? 38 : lineIndex === 8 ? 44 : 58 + lineIndex % 4 * 6
  return {
    lineId: line.id,
    lineName: line.name,
    carrier: line.carrier,
    onNetBytes: totalBytes * onNetRate / 100,
    crossNetBytes: totalBytes * (100 - onNetRate) / 100,
    onNetRate,
    ipv4Bytes: totalBytes * 0.66,
    ipv6Bytes: totalBytes * 0.34,
    peerMetrics: CARRIER_CATEGORIES.slice(0, 7).map((carrier, peerIndex) => ({
      carrier,
      latencyMs: Math.round(line.metrics.latencyMs + peerIndex * 4.5 + lineIndex % 3 * 2),
      packetLossPercent: Number(Math.max(
        line.metrics.packetLossPercent,
        line.metrics.packetLossPercent + peerIndex * 0.08,
      ).toFixed(2)),
    })),
  }
})

const flowProvinces = ['江西省', '广东省', '浙江省', '江苏省', '北京市', '上海市', '湖南省', '未识别地区']
const flowCarriers = CARRIER_CATEGORIES.slice(0, 8)
const protocols = ['TCP', 'UDP', 'QUIC']
const applications = ['HTTPS', '视频流', '对象存储', '游戏', 'DNS', '远程办公', '软件更新']

export const mockActiveFlows = Array.from({ length: 42 }, (_, index) => {
  const line = mockQualityLines[index % mockQualityLines.length]
  const province = flowProvinces[index % flowProvinces.length]
  const carrier = flowCarriers[(index * 3) % flowCarriers.length]
  const protocol = protocols[index % protocols.length]
  const durationSeconds = 35 + index * 47
  return {
    id: `flow-${String(index + 1).padStart(3, '0')}`,
    sourceIp: `192.168.${1 + index % 6}.${20 + index}`,
    sourcePort: 32000 + index * 17,
    destinationIp: index % 6 === 0 ? `240e:${index + 10}::${index + 1}` : `120.${10 + index % 20}.${index % 255}.${30 + index}`,
    destinationPort: [443, 80, 53, 3478, 8443][index % 5],
    ipVersion: index % 6 === 0 ? 'IPv6' : 'IPv4',
    protocol,
    application: applications[index % applications.length],
    province,
    carrier,
    lineId: line.id,
    lineName: line.name,
    uploadBytes: (220 + index * 31) * 1024 ** 2,
    downloadBytes: (580 + index * 66) * 1024 ** 2,
    durationSeconds,
    startedAt: `2026-07-23 ${String(14 + index % 2).padStart(2, '0')}:${String(index % 60).padStart(2, '0')}:00`,
  }
})

export const mockHistorySeries = (() => {
  const points = []
  for (let index = 0; index < 48; index += 1) {
    const hour = Math.floor(index / 2)
    points.push({
      time: `${String(hour).padStart(2, '0')}:${index % 2 ? '30' : '00'}`,
      uploadMbps: Number((420 + Math.sin(index / 3.2) * 130 + index * 3.5).toFixed(1)),
      downloadMbps: Number((880 + Math.cos(index / 4.1) * 260 + index * 7).toFixed(1)),
      ipv4Mbps: Number((720 + Math.sin(index / 5) * 155).toFixed(1)),
      ipv6Mbps: Number((310 + Math.cos(index / 5.5) * 92).toFixed(1)),
      outboundRate: Number((52 + Math.sin(index / 6) * 7).toFixed(1)),
      onNetRate: Number((58 + Math.cos(index / 7) * 6).toFixed(1)),
      averageLatencyMs: Number((28 + Math.sin(index / 4) * 8).toFixed(1)),
      averageScore: Number((78 + Math.cos(index / 5) * 5).toFixed(1)),
      activeConnections: Math.round(36000 + Math.sin(index / 3) * 5200 + index * 120),
    })
  }
  return points
})()

export const mockDailyHistory = Array.from({ length: 14 }, (_, index) => ({
  date: `2026-07-${String(10 + index).padStart(2, '0')}`,
  uploadBytes: (1.32 + index * 0.038) * TB,
  downloadBytes: (4.56 + index * 0.082) * TB,
  outboundRate: Number((52 + Math.sin(index / 2) * 5.5).toFixed(1)),
  onNetRate: Number((57 + Math.cos(index / 2.5) * 4).toFixed(1)),
  peakConnections: 46800 + index * 730,
  averageScore: Number((76 + Math.cos(index / 2.8) * 4.2).toFixed(1)),
}))

export const mockSchedulingSettings = {
  enabled: true,
  schedulingGoal: 'cdn_utilization',
  targetUtilization: 93,
  minimumWeight: 10,
  maximumWeight: 180,
  scoreUpdateSeconds: 10,
  weightUpdateSeconds: 30,
  failureRemovalThreshold: 35,
  recoveryJoinThreshold: 65,
  maximumWeightStep: 20,
  smoothingWindow: 6,
  hysteresisPoints: 5,
  demoOnly: true,
}

export const mockWeightChangeLogs = [
  { id: 'weight-log-01', time: '15:29:30', lineName: 'PPPoE-移动-01', direction: '升权', before: 120, after: 130, reason: '低延迟、低丢包且剩余上行充足' },
  { id: 'weight-log-02', time: '15:29:00', lineName: 'PPPoE-广电-01', direction: '降权', before: 75, after: 55, reason: '上行利用率达到94%，触发拥塞降权' },
  { id: 'weight-log-03', time: '15:28:30', lineName: 'PPPoE-联通-02', direction: '降权', before: 65, after: 45, reason: '丢包率连续超过故障阈值' },
  { id: 'weight-log-04', time: '15:28:00', lineName: 'PPPoE-移动-04', direction: '协议调整', before: 90, after: 80, reason: 'IPv6异常，退出IPv6调度，IPv4继续保留' },
  { id: 'weight-log-05', time: '15:27:30', lineName: 'PPPoE-电信-03', direction: '降权', before: 90, after: 70, reason: '平均延迟持续高于150ms' },
  { id: 'weight-log-06', time: '15:27:00', lineName: 'PPPoE-电信-02', direction: '升权', before: 95, after: 105, reason: '质量恢复并通过滞回确认' },
]

export const mockLineTrafficContribution = mockQualityLines.map((line) => ({
  lineId: line.id,
  lineName: line.name,
  carrier: line.carrier,
  uploadMbps: line.metrics.currentUploadMbps,
  downloadMbps: line.metrics.currentDownloadMbps,
  utilizationPercent: line.metrics.utilizationPercent,
  activeConnections: line.metrics.activeConnections,
  totalScore: line.score.totalScore,
  healthState: line.healthState,
}))

export const mockTrafficTotals = {
  recognizedGeoBytes: mockGeoTraffic.filter((item) => item.recognized).reduce((sum, item) => sum + item.totalBytes, 0),
  unknownGeoBytes: mockGeoTraffic.filter((item) => !item.recognized).reduce((sum, item) => sum + item.totalBytes, 0),
  carrierBytes: mockCarrierTraffic.reduce((sum, item) => sum + item.totalBytes, 0),
  flowBytes: mockActiveFlows.reduce((sum, item) => sum + item.uploadBytes + item.downloadBytes, 0),
  sampleBytes: 128 * GB,
}
