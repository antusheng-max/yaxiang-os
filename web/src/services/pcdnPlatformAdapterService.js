/**
 * PCDN 平台适配器服务
 * 支持多种平台数据源接入方式
 */

import { PLATFORM_ADAPTER_TYPE, PLATFORM_ADAPTER_TYPE_LABEL } from '../models/pcdnLineOptimization.js'

const DEMO_META = Object.freeze({ demo: true, source: 'mock', label: '前端演示数据' })

let currentAdapter = PLATFORM_ADAPTER_TYPE.NONE
let platformData = null

function response(data) {
  return Promise.resolve({
    data,
    meta: { ...DEMO_META, generatedAt: new Date().toISOString() },
  })
}

function generateMockPlatformData() {
  return {
    confirmedEffectiveUploadMbps: Math.round(450 + Math.random() * 100),
    currentTaskCount: Math.round(120 + Math.random() * 50),
    peerCount: Math.round(3500 + Math.random() * 800),
    contentHitRatePercent: Math.round(85 + Math.random() * 10),
    receivedSuccessBytesGB: Math.round(1200 + Math.random() * 300),
    rejectedOrFailedBytesGB: Math.round(30 + Math.random() * 15),
    ipv4TaskCount: Math.round(80 + Math.random() * 30),
    ipv6TaskCount: Math.round(40 + Math.random() * 20),
    carrierDistribution: [
      { carrier: '电信', taskCount: 45, percent: 37.5 },
      { carrier: '联通', taskCount: 35, percent: 29.2 },
      { carrier: '移动', taskCount: 25, percent: 20.8 },
      { carrier: '其他', taskCount: 15, percent: 12.5 },
    ],
    regionDistribution: [
      { region: '华东', taskCount: 40, percent: 33.3 },
      { region: '华南', taskCount: 30, percent: 25.0 },
      { region: '华北', taskCount: 25, percent: 20.8 },
      { region: '其他', taskCount: 25, percent: 20.8 },
    ],
  }
}

export const pcdnPlatformAdapterService = {
  /**
   * 获取当前适配器类型
   */
  getAdapterType() {
    return response({
      adapterType: currentAdapter,
      adapterTypeLabel: PLATFORM_ADAPTER_TYPE_LABEL[currentAdapter],
      hasPlatformData: currentAdapter !== PLATFORM_ADAPTER_TYPE.NONE && platformData !== null,
    })
  },

  /**
   * 设置适配器类型
   */
  setAdapterType(type) {
    if (Object.values(PLATFORM_ADAPTER_TYPE).includes(type)) {
      currentAdapter = type
      if (type === PLATFORM_ADAPTER_TYPE.NONE) {
        platformData = null
      } else {
        platformData = generateMockPlatformData()
      }
    }
    return response({
      adapterType: currentAdapter,
      adapterTypeLabel: PLATFORM_ADAPTER_TYPE_LABEL[currentAdapter],
      hasPlatformData: currentAdapter !== PLATFORM_ADAPTER_TYPE.NONE && platformData !== null,
    })
  },

  /**
   * 获取平台数据（如有）
   */
  getPlatformData() {
    if (currentAdapter === PLATFORM_ADAPTER_TYPE.NONE || !platformData) {
      return response({
        hasData: false,
        message: '有效上传为网络层估算值。',
        data: null,
      })
    }
    return response({
      hasData: true,
      message: '数据来自平台适配器。',
      data: platformData,
    })
  },

  /**
   * 刷新平台数据
   */
  refreshPlatformData() {
    if (currentAdapter !== PLATFORM_ADAPTER_TYPE.NONE) {
      platformData = generateMockPlatformData()
    }
    return this.getPlatformData()
  },

  /**
   * 获取所有适配器类型选项
   */
  getAdapterOptions() {
    return response(
      Object.entries(PLATFORM_ADAPTER_TYPE_LABEL).map(([value, label]) => ({ value, label }))
    )
  },
}
