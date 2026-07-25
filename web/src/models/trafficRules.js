export const IP_VERSION_OPTIONS = Object.freeze([
  { value: 'dual', label: '双栈', description: 'IPv4流量进入IPv4线路池，IPv6流量进入IPv6线路池。' },
  { value: 'ipv4', label: '仅IPv4', description: '只匹配IPv4连接。' },
  { value: 'ipv6', label: '仅IPv6', description: '只匹配IPv6连接。' },
])

export const BUSINESS_TYPE_OPTIONS = Object.freeze([
  '网络上行',
  '网络下行',
  'DNS',
  '系统管理',
  '普通上网',
  '视频流量',
  '大流量传输',
  '自定义',
])

export const RULE_SCHEDULING_MODES = Object.freeze([
  {
    value: 'cdn_utilization',
    label: '网络优化',
    badge: '推荐',
    description: '按剩余上行、利用率和线路质量动态分配新连接。',
  },
  {
    value: 'lowest_latency',
    label: '最低延迟',
    description: '优先选择响应时间和丢包更低的健康线路。',
  },
  {
    value: 'stability_first',
    label: '稳定优先',
    description: '优先选择近期断线少、质量波动小的线路。',
  },
  {
    value: 'manual_weight',
    label: '手动权重',
    badge: '高级',
    description: '保持人工设置的线路权重。',
  },
])

export const CDN_RULE_TEMPLATES = Object.freeze([
  {
    id: 'template_cdn_upload',
    name: '网络上行最大利用率',
    businessType: '网络上行',
    ipVersion: 'dual',
    targetPoolId: 'pool_default_dual',
    schedulingMode: 'cdn_utilization',
    description: '根据线路剩余上行能力、当前利用率、丢包、重传、稳定性和连接数量动态分配新连接，优先提高所有健康宽带的综合上行利用率。',
  },
  {
    id: 'template_cdn_ipv6_inbound',
    name: '原生IPv6入站',
    businessType: '网络上行',
    ipVersion: 'ipv6',
    targetPoolId: 'pool_ipv6_native_inbound',
    schedulingMode: 'stability_first',
    description: '只允许具有可用IPv6-PD、入站可达和回程对称能力的线路参与。',
  },
  {
    id: 'template_cdn_ipv6_compat',
    name: 'IPv6兼容出站',
    businessType: '网络上行',
    ipVersion: 'ipv6',
    targetPoolId: 'pool_ipv6_compat_outbound',
    schedulingMode: 'cdn_utilization',
    description: '允许无PD但具备IPv6公网地址和出站能力的线路参与IPv6上传，不标记为原生IPv6入站线路。',
  },
  {
    id: 'template_dns_latency',
    name: 'DNS低延迟',
    businessType: 'DNS',
    ipVersion: 'dual',
    targetPoolId: 'pool_default_dual',
    schedulingMode: 'lowest_latency',
    description: '优先使用延迟和丢包最低的健康线路。',
  },
  {
    id: 'template_management_stable',
    name: '管理流量稳定优先',
    businessType: '系统管理',
    ipVersion: 'dual',
    targetPoolId: 'pool_stable',
    schedulingMode: 'stability_first',
    description: '管理连接优先使用最稳定线路，不以最大带宽利用率为目标。',
  },
])

export const RULE_EXECUTION_STEPS = Object.freeze([
  '自动获取线路参数',
  '识别IPv4和IPv6能力',
  '验证互联网连通性',
  '验证入站和回程能力',
  '匹配业务分流规则',
  '选择IPv4或IPv6线路池',
  '过滤异常或无资格线路',
  '智能调度选择具体线路',
  '保存连接线路标记',
  '该连接后续流量固定使用原线路',
])

export function createTrafficRule(value = {}) {
  return {
    id: String(value.id || ''),
    name: String(value.name || '未命名规则'),
    enabled: value.enabled !== false,
    priority: Number(value.priority || 100),
    ipVersion: String(value.ipVersion || 'dual'),
    sourceLan: String(value.sourceLan || '任意局域网'),
    sourceDevice: String(value.sourceDevice || ''),
    sourceCidr: String(value.sourceCidr || ''),
    protocol: String(value.protocol || '任意'),
    sourcePort: String(value.sourcePort || ''),
    destinationPort: String(value.destinationPort || ''),
    destinationCidr: String(value.destinationCidr || ''),
    destinationDomain: String(value.destinationDomain || ''),
    destinationProvince: String(value.destinationProvince || ''),
    destinationCarrier: String(value.destinationCarrier || ''),
    businessType: String(value.businessType || '普通上网'),
    targetPoolId: String(value.targetPoolId || 'pool_default_dual'),
    schedulingMode: String(value.schedulingMode || 'cdn_utilization'),
    fallbackPoolId: String(value.fallbackPoolId || 'pool_default_dual'),
    effectiveTime: String(value.effectiveTime || '全天'),
    hitCount: Number(value.hitCount || 0),
    hitBytes: Number(value.hitBytes || 0),
    lastHitAt: String(value.lastHitAt || '—'),
    immutable: value.immutable === true,
    templateId: String(value.templateId || ''),
    updatedAt: String(value.updatedAt || '2026-07-23 16:20:00'),
  }
}

export function detectRuleConflicts(rules = []) {
  return rules.flatMap((rule, index) => rules.slice(index + 1).flatMap((other) => {
    if (!rule.enabled || !other.enabled) return []
    const samePriority = rule.priority === other.priority
    const overlappingIpVersion = rule.ipVersion === 'dual'
      || other.ipVersion === 'dual'
      || rule.ipVersion === other.ipVersion
    const sameMatch = rule.sourceCidr === other.sourceCidr
      && rule.destinationCidr === other.destinationCidr
      && rule.destinationDomain === other.destinationDomain
      && rule.protocol === other.protocol
      && rule.destinationPort === other.destinationPort
    if (!samePriority || !overlappingIpVersion || !sameMatch) return []
    return [{
      id: `${rule.id}:${other.id}`,
      firstRuleId: rule.id,
      secondRuleId: other.id,
      message: `“${rule.name}”与“${other.name}”优先级相同且匹配范围重叠`,
    }]
  }))
}
