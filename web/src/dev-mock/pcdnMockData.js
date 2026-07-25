/**
 * 次网络优化 — Mock 数据
 * 至少 10 条线路，覆盖多种状态组合
 */

import { createPcdnLineOptimization, IP_FAMILY, PCDN_LINE_STATUS } from '../models/pcdnLineOptimization.js'

function line(overrides) {
  return createPcdnLineOptimization(overrides)
}

export const mockPcdnLines = [
  // 1. 利用率接近目标且运行良好（3条）
  line({
    lineId: 'pcdn-001', lineName: '电信千兆线路 A', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 500, learnedCapacityMbps: 480, safeCapacityMbps: 456,
    targetUtilizationPercent: 95, physicalUploadMbps: 430, effectiveUploadMbps: 420,
    retransmissionMbps: 3, protocolOverheadMbps: 5, failedUploadMbps: 2,
    queueDelayMs: 12, latencyMs: 28, jitterMs: 4, packetLossPercent: 0.05,
    tcpRetransmissionPercent: 0.7, activeConnections: 1240, newConnectionsPerSecond: 45,
    remainingEffectiveCapacityMbps: 26, currentWeight: 32, recommendedWeight: 32,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: '利用率稳定，权重保持',
  }),
  line({
    lineId: 'pcdn-002', lineName: '联通千兆线路 B', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 400, learnedCapacityMbps: 385, safeCapacityMbps: 365,
    targetUtilizationPercent: 95, physicalUploadMbps: 345, effectiveUploadMbps: 335,
    retransmissionMbps: 4, protocolOverheadMbps: 4, failedUploadMbps: 2,
    queueDelayMs: 15, latencyMs: 35, jitterMs: 5, packetLossPercent: 0.08,
    tcpRetransmissionPercent: 1.1, activeConnections: 980, newConnectionsPerSecond: 38,
    remainingEffectiveCapacityMbps: 20, currentWeight: 28, recommendedWeight: 28,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: '利用率稳定，权重保持',
  }),
  line({
    lineId: 'pcdn-003', lineName: '移动宽带线路 C', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 300, learnedCapacityMbps: 290, safeCapacityMbps: 275,
    targetUtilizationPercent: 95, physicalUploadMbps: 260, effectiveUploadMbps: 250,
    retransmissionMbps: 4, protocolOverheadMbps: 4, failedUploadMbps: 2,
    queueDelayMs: 18, latencyMs: 42, jitterMs: 6, packetLossPercent: 0.12,
    tcpRetransmissionPercent: 1.5, activeConnections: 820, newConnectionsPerSecond: 32,
    remainingEffectiveCapacityMbps: 15, currentWeight: 22, recommendedWeight: 22,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: '利用率稳定，权重保持',
  }),
  // 2. 空闲、应当升权（2条）
  line({
    lineId: 'pcdn-004', lineName: '电信备用线路 D', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 500, learnedCapacityMbps: 475, safeCapacityMbps: 450,
    targetUtilizationPercent: 95, physicalUploadMbps: 120, effectiveUploadMbps: 110,
    retransmissionMbps: 3, protocolOverheadMbps: 5, failedUploadMbps: 2,
    queueDelayMs: 8, latencyMs: 25, jitterMs: 3, packetLossPercent: 0.03,
    tcpRetransmissionPercent: 0.5, activeConnections: 320, newConnectionsPerSecond: 12,
    remainingEffectiveCapacityMbps: 330, currentWeight: 10, recommendedWeight: 35,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: '空闲线路，建议升权',
  }),
  line({
    lineId: 'pcdn-005', lineName: '联通备用线路 E', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 400, learnedCapacityMbps: 380, safeCapacityMbps: 360,
    targetUtilizationPercent: 95, physicalUploadMbps: 90, effectiveUploadMbps: 82,
    retransmissionMbps: 3, protocolOverheadMbps: 4, failedUploadMbps: 1,
    queueDelayMs: 10, latencyMs: 30, jitterMs: 4, packetLossPercent: 0.05,
    tcpRetransmissionPercent: 0.8, activeConnections: 240, newConnectionsPerSecond: 9,
    remainingEffectiveCapacityMbps: 270, currentWeight: 8, recommendedWeight: 30,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: '空闲线路，建议升权',
  }),
  // 3. 总上传很高但 TCP 重传严重
  line({
    lineId: 'pcdn-006', lineName: '广电宽带线路 F', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 200, learnedCapacityMbps: 190, safeCapacityMbps: 180,
    targetUtilizationPercent: 95, physicalUploadMbps: 178, effectiveUploadMbps: 140,
    retransmissionMbps: 28, protocolOverheadMbps: 6, failedUploadMbps: 4,
    queueDelayMs: 45, latencyMs: 68, jitterMs: 15, packetLossPercent: 2.5,
    tcpRetransmissionPercent: 15.7, activeConnections: 890, newConnectionsPerSecond: 55,
    remainingEffectiveCapacityMbps: 2, currentWeight: 15, recommendedWeight: 5,
    schedulingEligible: true, cdnInboundEligible: false, cdnOutboundEligible: false,
    healthStatus: PCDN_LINE_STATUS.DEGRADED, adjustmentReason: 'TCP重传严重，建议降权',
  }),
  // 4. 队列延迟严重
  line({
    lineId: 'pcdn-007', lineName: '长宽线路 G', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 150, learnedCapacityMbps: 140, safeCapacityMbps: 133,
    targetUtilizationPercent: 95, physicalUploadMbps: 125, effectiveUploadMbps: 95,
    retransmissionMbps: 18, protocolOverheadMbps: 5, failedUploadMbps: 7,
    queueDelayMs: 120, latencyMs: 55, jitterMs: 22, packetLossPercent: 1.8,
    tcpRetransmissionPercent: 12.5, activeConnections: 720, newConnectionsPerSecond: 40,
    remainingEffectiveCapacityMbps: 8, currentWeight: 12, recommendedWeight: 4,
    schedulingEligible: true, cdnInboundEligible: false, cdnOutboundEligible: false,
    healthStatus: PCDN_LINE_STATUS.WARNING, adjustmentReason: '队列延迟严重，建议降权',
  }),
  // 5. IPv4 正常、IPv6 异常
  line({
    lineId: 'pcdn-008', lineName: '双栈线路 H', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 300, learnedCapacityMbps: 290, safeCapacityMbps: 275,
    targetUtilizationPercent: 95, physicalUploadMbps: 200, effectiveUploadMbps: 190,
    retransmissionMbps: 4, protocolOverheadMbps: 4, failedUploadMbps: 2,
    queueDelayMs: 15, latencyMs: 30, jitterMs: 4, packetLossPercent: 0.08,
    tcpRetransmissionPercent: 1.0, activeConnections: 650, newConnectionsPerSecond: 28,
    remainingEffectiveCapacityMbps: 75, currentWeight: 25, recommendedWeight: 30,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: 'IPv4 正常，权重保持',
  }),
  line({
    lineId: 'pcdn-008-v6', lineName: '双栈线路 H', ipFamily: IP_FAMILY.IPV6,
    configuredUploadMbps: 300, learnedCapacityMbps: 50, safeCapacityMbps: 47,
    targetUtilizationPercent: 95, physicalUploadMbps: 45, effectiveUploadMbps: 20,
    retransmissionMbps: 15, protocolOverheadMbps: 5, failedUploadMbps: 5,
    queueDelayMs: 85, latencyMs: 120, jitterMs: 35, packetLossPercent: 5.0,
    tcpRetransmissionPercent: 30.0, activeConnections: 180, newConnectionsPerSecond: 8,
    remainingEffectiveCapacityMbps: 2, currentWeight: 5, recommendedWeight: 2,
    schedulingEligible: false, cdnInboundEligible: false, cdnOutboundEligible: false,
    healthStatus: PCDN_LINE_STATUS.FAULT, adjustmentReason: 'IPv6 故障，已摘除调度',
  }),
  // 6. IPv6 正常、IPv4 异常
  line({
    lineId: 'pcdn-009', lineName: '双栈线路 I', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 250, learnedCapacityMbps: 60, safeCapacityMbps: 57,
    targetUtilizationPercent: 95, physicalUploadMbps: 55, effectiveUploadMbps: 25,
    retransmissionMbps: 18, protocolOverheadMbps: 6, failedUploadMbps: 6,
    queueDelayMs: 95, latencyMs: 110, jitterMs: 30, packetLossPercent: 4.5,
    tcpRetransmissionPercent: 28.0, activeConnections: 200, newConnectionsPerSecond: 9,
    remainingEffectiveCapacityMbps: 2, currentWeight: 6, recommendedWeight: 2,
    schedulingEligible: false, cdnInboundEligible: false, cdnOutboundEligible: false,
    healthStatus: PCDN_LINE_STATUS.FAULT, adjustmentReason: 'IPv4 故障，已摘除调度',
  }),
  line({
    lineId: 'pcdn-009-v6', lineName: '双栈线路 I', ipFamily: IP_FAMILY.IPV6,
    configuredUploadMbps: 250, learnedCapacityMbps: 240, safeCapacityMbps: 228,
    targetUtilizationPercent: 95, physicalUploadMbps: 180, effectiveUploadMbps: 170,
    retransmissionMbps: 3, protocolOverheadMbps: 4, failedUploadMbps: 3,
    queueDelayMs: 14, latencyMs: 32, jitterMs: 5, packetLossPercent: 0.06,
    tcpRetransmissionPercent: 0.9, activeConnections: 580, newConnectionsPerSecond: 25,
    remainingEffectiveCapacityMbps: 48, currentWeight: 28, recommendedWeight: 32,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: 'IPv6 正常，权重保持',
  }),
  // 7. 断线
  line({
    lineId: 'pcdn-010', lineName: '断线线路 J', ipFamily: IP_FAMILY.IPV4,
    configuredUploadMbps: 100, learnedCapacityMbps: 0, safeCapacityMbps: 0,
    targetUtilizationPercent: 95, physicalUploadMbps: 0, effectiveUploadMbps: 0,
    retransmissionMbps: 0, protocolOverheadMbps: 0, failedUploadMbps: 0,
    queueDelayMs: 0, latencyMs: 0, jitterMs: 0, packetLossPercent: 100,
    tcpRetransmissionPercent: 0, activeConnections: 0, newConnectionsPerSecond: 0,
    remainingEffectiveCapacityMbps: 0, currentWeight: 0, recommendedWeight: 0,
    schedulingEligible: false, cdnInboundEligible: false, cdnOutboundEligible: false,
    healthStatus: PCDN_LINE_STATUS.OFFLINE, adjustmentReason: '线路断线，已停止分配',
  }),
  // 8. IPv6 专线
  line({
    lineId: 'pcdn-011', lineName: 'IPv6 专线 K', ipFamily: IP_FAMILY.IPV6,
    configuredUploadMbps: 600, learnedCapacityMbps: 580, safeCapacityMbps: 551,
    targetUtilizationPercent: 95, physicalUploadMbps: 480, effectiveUploadMbps: 465,
    retransmissionMbps: 5, protocolOverheadMbps: 7, failedUploadMbps: 3,
    queueDelayMs: 10, latencyMs: 22, jitterMs: 3, packetLossPercent: 0.04,
    tcpRetransmissionPercent: 0.6, activeConnections: 1520, newConnectionsPerSecond: 62,
    remainingEffectiveCapacityMbps: 71, currentWeight: 38, recommendedWeight: 38,
    schedulingEligible: true, cdnInboundEligible: true, cdnOutboundEligible: true,
    healthStatus: PCDN_LINE_STATUS.HEALTHY, adjustmentReason: 'IPv6 专线稳定，权重保持',
  }),
]
