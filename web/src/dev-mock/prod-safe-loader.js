/**
 * 生产安全Mock数据加载器
 * 
 * 开发模式: 动态加载真实mock数据
 * 生产模式: 返回空数据结构，不打包mock文件
 * 
 * 使用 VITE_APP_MODE 环境变量控制
 */

const APP_MODE = import.meta.env.VITE_APP_MODE || 'mock'

// 空数据结构（生产模式使用）
const EMPTY_DATA = {
  mockPhysicalPorts: [],
  mockAccessChannels: [],
  mockDialInstances: [],
  mockAggregationGroups: [],
  mockLanNetworks: [],
  mockSchedulingPolicies: [],
  mockHealthCheckPolicies: [],
  mockPrefixMappings: [],
  mockPendingChanges: [],
  mockRecentDisconnects: [],
  genId: () => Date.now().toString(36),
  mockQualityLines: [],
  mockPcdnLines: [],
  mockProbeLines: [],
  mockProvincialRules: [],
  mockTrafficAnalytics: [],
  mockNetworkIntelligence: [],
}

// 开发模式：动态导入真实mock数据
async function loadMockData() {
  if (APP_MODE === 'real') {
    return EMPTY_DATA
  }
  
  try {
    const [
      { mockPhysicalPorts, mockAccessChannels, mockDialInstances,
        mockAggregationGroups, mockLanNetworks, mockSchedulingPolicies,
        mockHealthCheckPolicies, mockPrefixMappings, mockPendingChanges,
        mockRecentDisconnects, genId },
      { mockQualityLines },
      { mockPcdnLines },
      { mockProbeLines },
      { mockProvincialRules },
      { mockTrafficAnalytics },
      { mockNetworkIntelligence },
    ] = await Promise.all([
      import('./mockData.js'),
      import('./trafficAnalyticsMock.js').then(m => ({ mockQualityLines: m.mockQualityLines || [] })),
      import('./pcdnMockData.js').then(m => ({ mockPcdnLines: m.mockPcdnLines || [] })),
      import('./probeMockData.js').then(m => ({ mockProbeLines: m.mockProbeLines || [] })),
      import('./provincialMockData.js').then(m => ({ mockProvincialRules: m.mockProvincialRules || [] })),
      import('./trafficAnalyticsMock.js').then(m => ({ mockTrafficAnalytics: m.mockTrafficAnalytics || [] })),
      import('./networkIntelligenceMock.js').then(m => ({ mockNetworkIntelligence: m.mockNetworkIntelligence || [] })),
    ])
    
    return {
      mockPhysicalPorts, mockAccessChannels, mockDialInstances,
      mockAggregationGroups, mockLanNetworks, mockSchedulingPolicies,
      mockHealthCheckPolicies, mockPrefixMappings, mockPendingChanges,
      mockRecentDisconnects, genId,
      mockQualityLines, mockPcdnLines, mockProbeLines,
      mockProvincialRules, mockTrafficAnalytics, mockNetworkIntelligence,
    }
  } catch (e) {
    console.warn('[prod-safe-loader] Mock data load failed:', e.message)
    return EMPTY_DATA
  }
}

// 同步获取（用于初始化）
export function getMockDataSync() {
  if (APP_MODE === 'real') {
    return EMPTY_DATA
  }
  // 生产构建时此函数不会被调用，因为组件会检查APP_MODE
  return EMPTY_DATA
}

// 异步加载（用于开发模式）
export { loadMockData }

export { APP_MODE }
export function isRealMode() {
  return APP_MODE === 'real'
}
