/**
 * 极限探测突破 Mock 数据
 * 10 条线路覆盖各种突破场景
 */

import { createProbeLine, PROBE_STAGE, PROBE_DIRECTION, calcBreakthroughPercent, calcMaxUtilizationPercent } from '../models/probeLineOptimization.js'

function line(overrides) {
  return createProbeLine(overrides)
}

function withDerived(l) {
  return {
    ...l,
    advertisedBreakthroughPercent: calcBreakthroughPercent(l.sustainedMaximumMbps, l.advertisedUploadMbps),
    maximumUtilizationPercent: calcMaxUtilizationPercent(l.currentEffectiveUploadMbps, l.sustainedMaximumMbps),
  }
}

export const mockProbeLines = [
  // 1. 400M标称、持续极限476M（可突破119%）
  withDerived(line({
    lineId: 'probe-001', lineName: '电信线路 A', ipFamily: 'ipv4',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 480,
    sustainedMaximumMbps: 476, burstMaximumMbps: 495,
    currentEffectiveUploadMbps: 470, currentRawUploadMbps: 488,
    retransmissionMbps: 8, protocolOverheadMbps: 6, failedUploadMbps: 4,
    probeStage: PROBE_STAGE.SUSTAINED_VERIFY, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 8, lastSuccessfulTargetMbps: 480, lastFailedTargetMbps: 500,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:20:00',
    currentWeight: 38, recommendedWeight: 40,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '持续极限476M已确认，验证中',
  })),
  // 2. 400M标称、持续极限432M（小幅突破108%）
  withDerived(line({
    lineId: 'probe-002', lineName: '联通线路 B', ipFamily: 'ipv4',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 440,
    sustainedMaximumMbps: 432, burstMaximumMbps: 448,
    currentEffectiveUploadMbps: 428, currentRawUploadMbps: 442,
    retransmissionMbps: 6, protocolOverheadMbps: 5, failedUploadMbps: 3,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 8, lastSuccessfulTargetMbps: 440, lastFailedTargetMbps: 460,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:15:00',
    currentWeight: 32, recommendedWeight: 34,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '极限已锁定432M',
  })),
  // 3. 400M标称、硬限制400M（无法突破100%）
  withDerived(line({
    lineId: 'probe-003', lineName: '移动线路 C', ipFamily: 'ipv4',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 400,
    sustainedMaximumMbps: 400, burstMaximumMbps: 405,
    currentEffectiveUploadMbps: 392, currentRawUploadMbps: 408,
    retransmissionMbps: 12, protocolOverheadMbps: 6, failedUploadMbps: 8,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 8, lastSuccessfulTargetMbps: 400, lastFailedTargetMbps: 420,
    maximumProbeMultiplier: 130, maximumConfirmedAt: '2026-07-24 17:10:00',
    currentWeight: 25, recommendedWeight: 25,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '运营商硬限速400M，无法突破',
  })),
  // 4. 400M标称、短时520M但持续460M
  withDerived(line({
    lineId: 'probe-004', lineName: '广电线路 D', ipFamily: 'ipv4',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 460,
    sustainedMaximumMbps: 460, burstMaximumMbps: 520,
    currentEffectiveUploadMbps: 445, currentRawUploadMbps: 478,
    retransmissionMbps: 18, protocolOverheadMbps: 7, failedUploadMbps: 8,
    probeStage: PROBE_STAGE.BURST_VERIFY, probeDirection: PROBE_DIRECTION.UP,
    probeStepMbps: 10, lastSuccessfulTargetMbps: 460, lastFailedTargetMbps: 480,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:18:00',
    currentWeight: 30, recommendedWeight: 32,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '突发可达520M，验证持续极限',
  })),
  // 5. 500M标称、实际可达610M（突破122%）
  withDerived(line({
    lineId: 'probe-005', lineName: '电信线路 E', ipFamily: 'ipv4',
    advertisedUploadMbps: 500, currentProbeTargetMbps: 610,
    sustainedMaximumMbps: 610, burstMaximumMbps: 635,
    currentEffectiveUploadMbps: 602, currentRawUploadMbps: 628,
    retransmissionMbps: 9, protocolOverheadMbps: 8, failedUploadMbps: 5,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 10, lastSuccessfulTargetMbps: 610, lastFailedTargetMbps: 640,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:22:00',
    currentWeight: 45, recommendedWeight: 45,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '持续极限610M已确认并锁定',
  })),
  // 6. IPv4可突破、IPv6硬限速
  withDerived(line({
    lineId: 'probe-006', lineName: '双栈线路 F', ipFamily: 'ipv4',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 472,
    sustainedMaximumMbps: 472, burstMaximumMbps: 490,
    currentEffectiveUploadMbps: 465, currentRawUploadMbps: 485,
    retransmissionMbps: 7, protocolOverheadMbps: 6, failedUploadMbps: 4,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 8, lastSuccessfulTargetMbps: 472, lastFailedTargetMbps: 495,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:16:00',
    currentWeight: 36, recommendedWeight: 38,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: 'IPv4持续极限472M已锁定',
  })),
  withDerived(line({
    lineId: 'probe-006-v6', lineName: '双栈线路 F', ipFamily: 'ipv6',
    advertisedUploadMbps: 400, currentProbeTargetMbps: 400,
    sustainedMaximumMbps: 400, burstMaximumMbps: 402,
    currentEffectiveUploadMbps: 388, currentRawUploadMbps: 410,
    retransmissionMbps: 14, protocolOverheadMbps: 6, failedUploadMbps: 8,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 8, lastSuccessfulTargetMbps: 400, lastFailedTargetMbps: 420,
    maximumProbeMultiplier: 120, maximumConfirmedAt: '2026-07-24 17:14:00',
    currentWeight: 20, recommendedWeight: 20,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: 'IPv6运营商硬限速400M',
  })),
  // 7. IPv6可突破、IPv4硬限速
  withDerived(line({
    lineId: 'probe-007', lineName: '双栈线路 G', ipFamily: 'ipv4',
    advertisedUploadMbps: 300, currentProbeTargetMbps: 300,
    sustainedMaximumMbps: 300, burstMaximumMbps: 305,
    currentEffectiveUploadMbps: 292, currentRawUploadMbps: 308,
    retransmissionMbps: 10, protocolOverheadMbps: 5, failedUploadMbps: 6,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 6, lastSuccessfulTargetMbps: 300, lastFailedTargetMbps: 315,
    maximumProbeMultiplier: 120, maximumConfirmedAt: '2026-07-24 17:12:00',
    currentWeight: 22, recommendedWeight: 22,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: 'IPv4运营商硬限速300M',
  })),
  withDerived(line({
    lineId: 'probe-007-v6', lineName: '双栈线路 G', ipFamily: 'ipv6',
    advertisedUploadMbps: 300, currentProbeTargetMbps: 378,
    sustainedMaximumMbps: 378, burstMaximumMbps: 395,
    currentEffectiveUploadMbps: 372, currentRawUploadMbps: 388,
    retransmissionMbps: 5, protocolOverheadMbps: 5, failedUploadMbps: 3,
    probeStage: PROBE_STAGE.LOCKED, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 6, lastSuccessfulTargetMbps: 378, lastFailedTargetMbps: 395,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '2026-07-24 17:19:00',
    currentWeight: 30, recommendedWeight: 32,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: 'IPv6持续极限378M已锁定',
  })),
  // 8. 总发送很高但有效上传下降
  withDerived(line({
    lineId: 'probe-008', lineName: '长宽线路 H', ipFamily: 'ipv4',
    advertisedUploadMbps: 200, currentProbeTargetMbps: 230,
    sustainedMaximumMbps: 210, burstMaximumMbps: 230,
    currentEffectiveUploadMbps: 175, currentRawUploadMbps: 228,
    retransmissionMbps: 38, protocolOverheadMbps: 7, failedUploadMbps: 8,
    probeStage: PROBE_STAGE.CONGESTION_BACKOFF, probeDirection: PROBE_DIRECTION.DOWN,
    probeStepMbps: 6, lastSuccessfulTargetMbps: 210, lastFailedTargetMbps: 230,
    maximumProbeMultiplier: 130, maximumConfirmedAt: '2026-07-24 17:08:00',
    currentWeight: 15, recommendedWeight: 10,
    schedulingEligible: true, healthStatus: 'warning',
    adjustmentReason: '有效上传下降，拥塞回退中',
  })),
  // 9. 正在快速突破
  withDerived(line({
    lineId: 'probe-009', lineName: '电信线路 I', ipFamily: 'ipv4',
    advertisedUploadMbps: 300, currentProbeTargetMbps: 360,
    sustainedMaximumMbps: 0, burstMaximumMbps: 365,
    currentEffectiveUploadMbps: 355, currentRawUploadMbps: 368,
    retransmissionMbps: 6, protocolOverheadMbps: 5, failedUploadMbps: 3,
    probeStage: PROBE_STAGE.FAST_BREAKTHROUGH, probeDirection: PROBE_DIRECTION.UP,
    probeStepMbps: 15, lastSuccessfulTargetMbps: 360, lastFailedTargetMbps: 0,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '',
    currentWeight: 28, recommendedWeight: 35,
    schedulingEligible: true, healthStatus: 'healthy',
    adjustmentReason: '快速突破中，目标360M',
  })),
  // 10. 线路故障
  withDerived(line({
    lineId: 'probe-010', lineName: '断线线路 J', ipFamily: 'ipv4',
    advertisedUploadMbps: 150, currentProbeTargetMbps: 0,
    sustainedMaximumMbps: 0, burstMaximumMbps: 0,
    currentEffectiveUploadMbps: 0, currentRawUploadMbps: 0,
    retransmissionMbps: 0, protocolOverheadMbps: 0, failedUploadMbps: 0,
    probeStage: PROBE_STAGE.FAULT, probeDirection: PROBE_DIRECTION.HOLD,
    probeStepMbps: 0, lastSuccessfulTargetMbps: 0, lastFailedTargetMbps: 0,
    maximumProbeMultiplier: 150, maximumConfirmedAt: '',
    currentWeight: 0, recommendedWeight: 0,
    schedulingEligible: false, healthStatus: 'fault',
    adjustmentReason: '线路故障，停止探测',
  })),
]
