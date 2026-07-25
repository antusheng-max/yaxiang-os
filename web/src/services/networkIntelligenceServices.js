import {
  ACCESS_TYPE_OPTIONS,
  evaluateLineCapability,
  getCapabilityParameterStates,
  getIpv6CapabilityMeta,
} from '../models/lineCapability.js'
import {
  BUSINESS_TYPE_OPTIONS,
  CDN_RULE_TEMPLATES,
  createTrafficRule,
  detectRuleConflicts,
} from '../models/trafficRules.js'
// 生产安全: 不静态导入dev-mock
const mockLineCapabilities = []
const mockLinePools = []
const mockRuleChangeLogs = []
const mockRuleHitRecords = []
const mockTrafficRules = []
const mockQualityLines = []

const DEMO_META = Object.freeze({
  demo: true,
  source: 'mock',
  label: '前端演示数据',
})

let lineCapabilities = clone(mockLineCapabilities)
let trafficRules = clone(mockTrafficRules)
let changeLogs = clone(mockRuleChangeLogs)

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function response(data) {
  return Promise.resolve({
    data: clone(data),
    meta: {
      ...DEMO_META,
      generatedAt: '2026-07-23 16:20:00',
    },
  })
}

function addChangeLog(rule, action, detail) {
  changeLogs.unshift({
    id: `change-${Date.now()}`,
    time: '2026-07-23 16:20:00',
    ruleName: rule.name,
    action,
    detail,
  })
}

function qualityByLineId(lineId) {
  return mockQualityLines.find(item => item.id === lineId)
}

function ruleMatchesProtocol(rule, ipVersion) {
  return rule.ipVersion === 'dual' || rule.ipVersion === ipVersion.toLowerCase()
}

function valueIncludes(value, expected) {
  if (!expected) return true
  if (!value) return false
  return String(value).toLowerCase().includes(String(expected).toLowerCase())
}

function ruleMatchesInput(rule, input, classification) {
  if (!rule.enabled || !ruleMatchesProtocol(rule, input.ipVersion)) return false
  if (rule.businessType !== '自定义' && rule.businessType !== classification.businessType) {
    return false
  }
  if (
    rule.protocol !== '任意'
    && rule.protocol !== 'UDP或TCP'
    && rule.protocol.toLowerCase() !== String(input.protocol || '').toLowerCase()
  ) {
    return false
  }
  if (rule.destinationPort && !valueIncludes(rule.destinationPort, input.port)) return false
  if (rule.destinationDomain && !valueIncludes(rule.destinationDomain, input.destination)) {
    return false
  }
  return true
}

function poolAcceptsLine(pool, line, protocol) {
  if (!line) return false
  if (pool.id === 'pool_ipv6_native_inbound') return line.cdnIpv6InboundEligible
  if (pool.id === 'pool_ipv6_compat_outbound') {
    return line.cdnIpv6OutboundEligible && !line.ipv6NativeLanEligible
  }
  if (pool.id === 'pool_stable') {
    return protocol === 'ipv6'
      ? line.ipv6SchedulingEligible
      : line.ipv4SchedulingEligible
  }
  return protocol === 'ipv6'
    ? line.ipv6SchedulingEligible
    : line.ipv4SchedulingEligible
}

function getEligibleLines(poolId, protocol) {
  const pool = mockLinePools.find(item => item.id === poolId)
    || mockLinePools.find(item => item.id === `pool_${protocol}_default`)
    || mockLinePools[0]
  return lineCapabilities.filter(line => poolAcceptsLine(pool, line, protocol))
}

function chooseLine(lines, protocol, mode) {
  const candidates = lines.map((line) => {
    const quality = qualityByLineId(line.lineId)
    const state = quality?.protocolScheduling?.[protocol]
    return {
      ...line,
      score: state?.score ?? 0,
      currentWeight: state?.currentWeight ?? 0,
      utilizationPercent: quality?.metrics?.utilizationPercent ?? 0,
      latencyMs: quality?.metrics?.latencyMs ?? 0,
      stabilityScore: quality?.score?.stabilityScore ?? 0,
    }
  })
  if (mode === 'lowest_latency') {
    return candidates.sort((a, b) => a.latencyMs - b.latencyMs)[0]
  }
  if (mode === 'stability_first') {
    return candidates.sort((a, b) => b.stabilityScore - a.stabilityScore)[0]
  }
  if (mode === 'manual_weight') {
    return candidates.sort((a, b) => b.currentWeight - a.currentWeight)[0]
  }
  return candidates.sort((a, b) => {
    const aHeadroom = 100 - a.utilizationPercent
    const bHeadroom = 100 - b.utilizationPercent
    return (b.score + bHeadroom * 0.35) - (a.score + aHeadroom * 0.35)
  })[0]
}

export const lineCapabilityService = {
  list: () => response(lineCapabilities),
  get: lineId => response(
    lineCapabilities.find(item => item.lineId === lineId) || null,
  ),
  getParameterStates: lineId => {
    const line = lineCapabilities.find(item => item.lineId === lineId)
    return response(line ? getCapabilityParameterStates(line) : [])
  },
  getSummary: () => {
    const ipv4Eligible = lineCapabilities.filter(item => item.ipv4SchedulingEligible).length
    const ipv6Eligible = lineCapabilities.filter(item => item.ipv6SchedulingEligible).length
    const ipv6Pd = lineCapabilities.filter(item => item.ipv6NativeLanEligible).length
    const ipv6NoPd = lineCapabilities.filter(item =>
      item.ipv6SchedulingEligible && !item.ipv6NativeLanEligible).length
    return response({
      total: lineCapabilities.length,
      ipv4Eligible,
      ipv6Eligible,
      ipv6Pd,
      ipv6NoPd,
      abnormal: lineCapabilities.filter(item =>
        !item.ipv4SchedulingEligible || !item.ipv6SchedulingEligible).length,
    })
  },
}

export const lineDetectionService = {
  getSourceExplanation: () => response({
    accessTypes: ACCESS_TYPE_OPTIONS,
    notice: 'VLAN本身不会提供IP地址、域名服务器或默认路由；系统实际读取指定通道上的宽带拨号或自动获取结果。',
    sources: [
      {
        title: 'DHCP IPv4（自动获取）',
        description: '读取IPv4地址、子网掩码、默认网关、域名服务器和租期。',
      },
      {
        title: 'PPPoE IPv4（宽带账号拨号）',
        description: '读取认证结果、会话状态、IPv4地址、对端信息、域名服务器和最大传输单元。',
      },
      {
        title: 'IPv6（新一代互联网协议）',
        description: '读取链路本地地址、全局地址、默认路由、域名服务器、运营商前缀及有效期。',
      },
    ],
  }),
  getStages: () => response([
    '检测物理连接',
    '读取运营商返回参数',
    '分别验证IPv4和IPv6互联网连通性',
    '验证公网入站和回程路径',
    '计算线路池与调度资格',
  ]),
  detect: (lineId) => {
    const index = lineCapabilities.findIndex(item => item.lineId === lineId)
    if (index < 0) return response(null)
    lineCapabilities[index] = evaluateLineCapability({
      ...lineCapabilities[index],
      updatedAt: '2026-07-23 16:21:00',
      ipv6DetectionPending: false,
    })
    return response(lineCapabilities[index])
  },
}

export const flowClassificationService = {
  listBusinessTypes: () => response(BUSINESS_TYPE_OPTIONS),
  classify: (input = {}) => {
    const destination = String(input.destination || '').toLowerCase()
    const port = String(input.port || '')
    let businessType = '普通上网'
    let reason = '未命中专用业务特征，按普通上网处理。'
    if (port === '53') {
      businessType = 'DNS'
      reason = '目标端口为53，识别为域名解析流量。'
    } else if (['22', '3389', '8443'].includes(port)) {
      businessType = '系统管理'
      reason = '目标端口符合常用管理连接特征。'
    } else if (/video|iqiyi|youku|bilibili|qq\.com/.test(destination)) {
      businessType = '视频流量'
      reason = '目标域名符合视频业务特征。'
    } else if (/cdn|upload|object|storage/.test(destination)) {
      businessType = '网络上行'
      reason = '目标域名符合内容分发或对象存储上传特征。'
    }
    return response({ businessType, reason })
  },
}

export const trafficRuleService = {
  list: () => response([...trafficRules].sort((a, b) => a.priority - b.priority)),
  get: id => response(trafficRules.find(item => item.id === id) || null),
  listTemplates: () => response(CDN_RULE_TEMPLATES),
  listChangeLogs: () => response(changeLogs),
  getConflicts: () => response(detectRuleConflicts(trafficRules)),
  create: (value) => {
    const rule = createTrafficRule({
      ...value,
      id: `rule-${Date.now()}`,
      priority: trafficRules.filter(item => !item.immutable).length * 10 + 10,
    })
    const fallbackIndex = trafficRules.findIndex(item => item.immutable)
    trafficRules.splice(fallbackIndex < 0 ? trafficRules.length : fallbackIndex, 0, rule)
    addChangeLog(rule, '新建', '已在前端演示规则中添加')
    return response(rule)
  },
  update: (id, patch) => {
    const index = trafficRules.findIndex(item => item.id === id)
    if (index < 0) return response(null)
    const current = trafficRules[index]
    trafficRules[index] = createTrafficRule({
      ...current,
      ...patch,
      id: current.id,
      immutable: current.immutable,
      updatedAt: '2026-07-23 16:21:00',
    })
    addChangeLog(trafficRules[index], '修改', '已更新前端演示规则字段')
    return response(trafficRules[index])
  },
  toggle: (id, enabled) => {
    const rule = trafficRules.find(item => item.id === id)
    if (!rule || rule.immutable) return response(rule || null)
    rule.enabled = Boolean(enabled)
    addChangeLog(rule, rule.enabled ? '启用' : '停用', '只影响前端Mock匹配结果')
    return response(rule)
  },
  copy: (id) => {
    const source = trafficRules.find(item => item.id === id)
    if (!source) return response(null)
    const copyRule = createTrafficRule({
      ...source,
      id: `rule-copy-${Date.now()}`,
      name: `${source.name}（副本）`,
      immutable: false,
      priority: Math.min(9998, source.priority + 1),
      hitCount: 0,
      hitBytes: 0,
      lastHitAt: '—',
    })
    const fallbackIndex = trafficRules.findIndex(item => item.immutable)
    trafficRules.splice(fallbackIndex < 0 ? trafficRules.length : fallbackIndex, 0, copyRule)
    addChangeLog(copyRule, '复制', `复制自“${source.name}”`)
    return response(copyRule)
  },
  remove: (id) => {
    const rule = trafficRules.find(item => item.id === id)
    if (!rule || rule.immutable) return response(false)
    trafficRules = trafficRules.filter(item => item.id !== id)
    addChangeLog(rule, '删除', '已从前端演示规则中移除')
    return response(true)
  },
  reorder: (orderedIds) => {
    const orderMap = new Map(orderedIds.map((id, index) => [id, index]))
    trafficRules = trafficRules
      .sort((a, b) => {
        if (a.immutable) return 1
        if (b.immutable) return -1
        return (orderMap.get(a.id) ?? 9998) - (orderMap.get(b.id) ?? 9998)
      })
      .map((rule, index) => ({
        ...rule,
        priority: rule.immutable ? 9999 : (index + 1) * 10,
      }))
    const first = trafficRules.find(item => !item.immutable)
    if (first) addChangeLog(first, '排序', '已拖动调整规则优先级')
    return response(trafficRules)
  },
  createFromTemplate: (templateId) => {
    const template = CDN_RULE_TEMPLATES.find(item => item.id === templateId)
    if (!template) return response(null)
    return trafficRuleService.create({
      ...template,
      name: `${template.name}（新规则）`,
      templateId,
      sourceLan: '任意局域网',
      protocol: template.businessType === 'DNS' ? 'UDP或TCP' : '任意',
      destinationPort: template.businessType === 'DNS' ? '53' : '',
      fallbackPoolId: 'pool_default_dual',
    })
  },
}

export const linePoolService = {
  list: () => response(mockLinePools),
  get: id => response(mockLinePools.find(item => item.id === id) || null),
  listEligibleLines: (poolId, protocol = 'ipv4') => response(
    getEligibleLines(poolId, protocol),
  ),
}

export const schedulingSimulationService = {
  simulate: async (input = {}) => {
    const protocol = String(input.ipVersion || 'IPv4').toLowerCase()
    const classification = (await flowClassificationService.classify(input)).data
    const orderedRules = [...trafficRules].sort((a, b) => a.priority - b.priority)
    const matchedRule = orderedRules.find(rule =>
      ruleMatchesInput(rule, { ...input, ipVersion: protocol }, classification))
      || orderedRules.find(rule => rule.immutable)
    const poolId = matchedRule?.targetPoolId
      || (protocol === 'ipv6' ? 'pool_ipv6_default' : 'pool_ipv4_default')
    const pool = mockLinePools.find(item => item.id === poolId)
      || mockLinePools.find(item => item.id === `pool_${protocol}_default`)
    const eligibleLines = getEligibleLines(pool?.id, protocol)
    const possibleLine = chooseLine(eligibleLines, protocol, matchedRule?.schedulingMode)
    const fallbackPool = mockLinePools.find(item => item.id === matchedRule?.fallbackPoolId)
    return response({
      input,
      classification,
      matchedRule,
      pool,
      eligibleLines,
      possibleLine: possibleLine || null,
      reason: possibleLine
        ? `已先按“${classification.businessType}”匹配规则，再从具备${protocol.toUpperCase()}资格的线路中按当前调度模式选择。`
        : '当前线路池没有具备资格的线路，将进入故障兜底处理。',
      fallback: fallbackPool
        ? `故障时转入“${fallbackPool.name}”重新选择。`
        : '无额外线路池，保持现有连接并等待健康线路恢复。',
      connectionPolicy: '只为新连接选择线路；已建立连接保持原出口。',
    })
  },
}

export const ruleHitStatisticsService = {
  list: () => response(mockRuleHitRecords),
  getSummary: () => response({
    totalHits: trafficRules.reduce((sum, item) => sum + item.hitCount, 0),
    totalBytes: trafficRules.reduce((sum, item) => sum + item.hitBytes, 0),
    activeRules: trafficRules.filter(item => item.enabled).length,
    fallbackHits: trafficRules.find(item => item.immutable)?.hitCount || 0,
  }),
}
