/**
 * Mock Adapter - 开发环境模拟数据适配器
 *
 * 仅在开发环境使用，生产构建禁止导入此模块
 */

import * as systemApi from './systemApi.js'
import * as networkApi from './networkApi.js'
import * as schedulerApi from './schedulerApi.js'
import * as trafficApi from './trafficApi.js'

const NOT_IMPLEMENTED = {
  implemented: false,
  source: 'unavailable',
  reason: '尚未接入真实系统后端'
}

export function createMockAdapter() {
  return {
    mode: 'mock',

    checkImplementation(feature) {
      return {
        implemented: false,
        source: 'mock',
        reason: `当前为开发模拟模式: ${feature}`
      }
    },

    // 系统
    system: {
      getInfo: () => systemApi.getMockSystemInfo(),
      getUptime: () => systemApi.getMockUptime(),
      getServices: () => systemApi.getMockServices(),
    },

    // 网络
    network: {
      getInterfaces: () => networkApi.getMockInterfaces(),
      getWanList: () => networkApi.getMockWanList(),
      getLanList: () => networkApi.getMockLanList(),
      getVlans: () => networkApi.getMockVlans(),
      getDhcpLeases: () => networkApi.getMockDhcpLeases(),
    },

    // 调度
    scheduler: {
      getOverview: () => schedulerApi.getMockSchedulingOverview(),
      getLineRanking: () => schedulerApi.getMockLineRanking(),
      getHitRecords: () => schedulerApi.getMockHitRecords(),
      getAdvancedParams: () => schedulerApi.getMockAdvancedParams(),
    },

    // 流量
    traffic: {
      getOverview: () => trafficApi.getMockTrafficOverview(),
      getGeoAnalysis: () => trafficApi.getMockGeoAnalysis(),
      getCarrierAnalysis: () => trafficApi.getMockCarrierAnalysis(),
      getLineUtilization: () => trafficApi.getMockLineUtilization(),
      getActiveConnections: () => trafficApi.getMockActiveConnections(),
    },

    // 未实现接口统一返回
    notImplemented: () => NOT_IMPLEMENTED,
  }
}
