import { evaluateLineCapability } from '../models/lineCapability.js'
import {
  CDN_RULE_TEMPLATES,
  createTrafficRule,
} from '../models/trafficRules.js'

const GB = 1024 ** 3
const detectedAt = '2026-07-23 16:18:00'
const updatedAt = '2026-07-23 16:20:00'

const publicV4 = index => `223.86.42.${100 + index}`
const privateV4 = index => `100.64.${index}.2`
const v6Address = index => `2408:8456:${index.toString(16)}::2`
const v6Prefix = index => `2408:8456:${index.toString(16)}:1000::`

const baseSeed = ({
  id,
  name,
  carrier,
  accessType,
  port,
  vlan,
  index,
  publicIpv4 = false,
}) => ({
  lineId: id,
  lineName: name,
  carrier,
  accessType,
  physicalPort: port,
  vlanId: vlan,
  linkDetected: true,
  authenticationSucceeded: true,
  sessionId: `宽带会话-${String(index).padStart(2, '0')}`,
  mtu: accessType.includes('pppoe') || accessType === 'pppoe' ? 1492 : 1500,
  detectedAt,
  updatedAt,
  ipv4Address: publicIpv4 ? publicV4(index) : privateV4(index),
  ipv4PrefixLength: publicIpv4 ? 24 : 32,
  ipv4Gateway: publicIpv4 ? `223.86.42.1` : `100.64.${index}.1`,
  ipv4DnsServers: ['223.5.5.5', '119.29.29.29'],
  ipv4LeaseTime: accessType.includes('dhcp') || accessType === 'dhcp' ? '23小时48分' : '随拨号会话',
  ipv4RouteAvailable: true,
  ipv4InternetReachable: true,
  ipv4AddressType: publicIpv4 ? 'public' : 'carrier_nat',
  ipv4HealthPassed: true,
  ipv6CpOpened: true,
  ipv6LinkLocalAddress: `fe80::${index}`,
  ipv6GlobalAddresses: [v6Address(index)],
  ipv6DefaultRoute: `fe80::1%${port}`,
  ipv6DnsServers: ['240c::6666', '240c::6644'],
  ipv6PrefixDelegations: [],
  ipv6PrefixLength: null,
  ipv6PreferredLifetime: '12小时',
  ipv6ValidLifetime: '24小时',
  ipv6InternetReachable: true,
  ipv6HealthPassed: true,
  ipv6CompatibilityMode: 'none',
  publicReachability: publicIpv4 ? 'reachable' : 'unreachable',
  returnPathSymmetric: true,
  publishedAddresses: publicIpv4 ? [publicV4(index)] : [],
})

const pdSeed = (seed, prefixLength = 60) => ({
  ...seed,
  ipv6PrefixDelegations: [{
    prefix: v6Prefix(Number(seed.lineId.split('-')[1])),
    length: prefixLength,
    preferredLifetime: '12小时',
    validLifetime: '24小时',
  }],
  ipv6PrefixLength: prefixLength,
  publicReachability: 'reachable',
  publishedAddresses: [
    ...seed.publishedAddresses,
    v6Prefix(Number(seed.lineId.split('-')[1])),
  ],
})

export const mockLineCapabilities = [
  pdSeed(baseSeed({
    id: 'line-01', name: 'PPPoE-移动-01', carrier: '中国移动',
    accessType: 'vlan_pppoe', port: '宽带入口 1', vlan: 101, index: 1, publicIpv4: true,
  })),
  pdSeed(baseSeed({
    id: 'line-02', name: 'PPPoE-电信-01', carrier: '中国电信',
    accessType: 'pppoe', port: '宽带入口 2', vlan: null, index: 2, publicIpv4: true,
  })),
  pdSeed(baseSeed({
    id: 'line-03', name: 'PPPoE-联通-01', carrier: '中国联通',
    accessType: 'vlan_dhcp', port: '宽带入口 1', vlan: 103, index: 3,
  })),
  {
    ...baseSeed({
      id: 'line-04', name: 'PPPoE-移动-02', carrier: '中国移动',
      accessType: 'dhcp', port: '宽带入口 3', vlan: null, index: 4,
    }),
    ipv6CompatibilityMode: 'nat66_outbound',
    publicReachability: 'unreachable',
  },
  {
    ...baseSeed({
      id: 'line-05', name: 'PPPoE-电信-02', carrier: '中国电信',
      accessType: 'vlan_pppoe', port: '宽带入口 1', vlan: 105, index: 5,
    }),
    ipv6CompatibilityMode: 'none',
    publicReachability: 'unreachable',
  },
  {
    ...baseSeed({
      id: 'line-06', name: 'PPPoE-移动-03', carrier: '中国移动',
      accessType: 'pppoe', port: '宽带入口 4', vlan: null, index: 6,
    }),
    ipv6CpOpened: false,
    ipv6LinkLocalAddress: '',
    ipv6GlobalAddresses: [],
    ipv6DefaultRoute: '',
    ipv6DnsServers: [],
    ipv6InternetReachable: false,
    ipv6HealthPassed: false,
    returnPathSymmetric: false,
  },
  {
    ...baseSeed({
      id: 'line-07', name: 'PPPoE-电信-03', carrier: '中国电信',
      accessType: 'vlan_pppoe', port: '宽带入口 1', vlan: 107, index: 7,
    }),
    ipv6InternetReachable: false,
    ipv6HealthPassed: false,
    publicReachability: 'unreachable',
    returnPathSymmetric: false,
  },
  {
    ...pdSeed(baseSeed({
      id: 'line-08', name: 'PPPoE-联通-02', carrier: '中国联通',
      accessType: 'vlan_dhcp', port: '宽带入口 1', vlan: 108, index: 8,
    })),
    ipv4Address: '',
    ipv4PrefixLength: null,
    ipv4Gateway: '',
    ipv4DnsServers: [],
    ipv4RouteAvailable: false,
    ipv4InternetReachable: false,
    ipv4HealthPassed: false,
    publicReachability: 'reachable',
    returnPathSymmetric: true,
  },
  {
    ...baseSeed({
      id: 'line-09', name: 'PPPoE-广电-01', carrier: '中国广电',
      accessType: 'dhcp', port: '宽带入口 5', vlan: null, index: 9,
    }),
    ipv4InternetReachable: false,
    ipv4HealthPassed: false,
    ipv6InternetReachable: false,
    ipv6HealthPassed: false,
    publicReachability: 'unreachable',
    returnPathSymmetric: false,
  },
  pdSeed(baseSeed({
    id: 'line-10', name: 'PPPoE-移动-04', carrier: '中国移动',
    accessType: 'vlan_pppoe', port: '宽带入口 1', vlan: 110, index: 10,
  })),
].map(evaluateLineCapability)

export const mockLinePools = [
  {
    id: 'pool_default_dual',
    name: '默认双栈健康线路池',
    description: '按连接的IP版本自动进入IPv4或IPv6健康线路池。',
    protocol: 'dual',
    capabilityRequirement: '对应协议具备调度资格',
    fallbackPoolId: '',
  },
  {
    id: 'pool_ipv4_default',
    name: 'IPv4默认健康线路池',
    description: '只包含获得IPv4地址、默认路由且连通性和健康检查通过的线路。',
    protocol: 'ipv4',
    capabilityRequirement: 'IPv4调度资格',
    fallbackPoolId: '',
  },
  {
    id: 'pool_ipv6_default',
    name: 'IPv6默认健康线路池',
    description: '包含原生IPv6和检测通过的无PD兼容出站线路。',
    protocol: 'ipv6',
    capabilityRequirement: 'IPv6调度资格',
    fallbackPoolId: 'pool_ipv4_default',
  },
  {
    id: 'pool_ipv6_native_inbound',
    name: '原生IPv6入站线路池',
    description: '只包含获得运营商前缀、入站可达且回程对称的线路。',
    protocol: 'ipv6',
    capabilityRequirement: 'IPv6 入站资格',
    fallbackPoolId: 'pool_ipv6_default',
  },
  {
    id: 'pool_ipv6_compat_outbound',
    name: 'IPv6兼容出站线路池',
    description: '包含无PD但具备全局IPv6地址和出站能力的线路，不用于原生IPv6入站。',
    protocol: 'ipv6',
    capabilityRequirement: 'IPv6 出站资格',
    fallbackPoolId: 'pool_ipv6_default',
  },
  {
    id: 'pool_stable',
    name: '稳定优先线路池',
    description: '从对应协议健康线路中优先选择近期波动较小的线路。',
    protocol: 'dual',
    capabilityRequirement: '对应协议健康且稳定',
    fallbackPoolId: 'pool_default_dual',
  },
]

const templateRules = CDN_RULE_TEMPLATES.map((template, index) => createTrafficRule({
  id: `rule_template_${index + 1}`,
  ...template,
  templateId: template.id,
  priority: (index + 1) * 10,
  protocol: template.businessType === 'DNS' ? 'UDP与TCP' : '任意',
  destinationPort: template.businessType === 'DNS' ? '53' : '',
  sourceLan: template.businessType === '系统管理' ? '管理局域网' : '任意局域网',
  fallbackPoolId: 'pool_default_dual',
  hitCount: 15840 - index * 1840,
  hitBytes: (620 - index * 82) * GB,
  lastHitAt: `2026-07-23 16:${19 - index}:32`,
}))

const legacyRules = [
  {
    id: 'rule_legacy_game',
    name: '游戏加速',
    sourceCidr: '192.168.1.0/24',
    protocol: 'UDP',
    destinationPort: '3000-5000',
    businessType: '自定义',
    targetPoolId: 'pool_default_dual',
    schedulingMode: 'lowest_latency',
    priority: 60,
  },
  {
    id: 'rule_legacy_video',
    name: '视频走电信',
    sourceCidr: '192.168.1.0/24',
    destinationDomain: '*.iqiyi.com,*.qq.com',
    businessType: '视频流量',
    destinationCarrier: '中国电信',
    targetPoolId: 'pool_default_dual',
    schedulingMode: 'cdn_utilization',
    priority: 70,
  },
  {
    id: 'rule_legacy_server',
    name: '服务器固定出口',
    sourceCidr: '192.168.1.200/32',
    destinationCidr: '0.0.0.0/0',
    businessType: '大流量传输',
    targetPoolId: 'pool_ipv4_default',
    schedulingMode: 'stability_first',
    priority: 80,
  },
  {
    id: 'rule_legacy_office',
    name: '办公走专线',
    sourceCidr: '192.168.1.50/32',
    destinationCidr: '10.0.0.0/8',
    businessType: '系统管理',
    targetPoolId: 'pool_stable',
    schedulingMode: 'stability_first',
    priority: 90,
  },
].map((rule, index) => createTrafficRule({
  ...rule,
  enabled: true,
  ipVersion: 'dual',
  sourceLan: '办公局域网',
  fallbackPoolId: 'pool_default_dual',
  effectiveTime: '全天',
  hitCount: 6230 + index * 1730,
  hitBytes: (82 + index * 31) * GB,
  lastHitAt: `2026-07-23 15:${42 + index}:18`,
}))

export const mockTrafficRules = [
  ...templateRules,
  ...legacyRules,
  createTrafficRule({
    id: 'rule_default',
    name: '默认智能调度',
    enabled: true,
    priority: 9999,
    ipVersion: 'dual',
    sourceLan: '任意局域网',
    protocol: '任意',
    businessType: '普通上网',
    targetPoolId: 'pool_default_dual',
    schedulingMode: 'cdn_utilization',
    fallbackPoolId: 'pool_default_dual',
    effectiveTime: '全天',
    hitCount: 928416,
    hitBytes: 5460 * GB,
    lastHitAt: '2026-07-23 16:20:00',
    immutable: true,
  }),
]

export const mockRuleHitRecords = [
  { id: 'hit-01', time: '16:20:00', ruleId: 'rule_template_1', ipVersion: 'IPv6', businessType: '网络上行', poolId: 'pool_ipv6_default', lineId: 'line-04', bytes: 4.8 * GB, result: '新连接已分配' },
  { id: 'hit-02', time: '16:19:48', ruleId: 'rule_template_4', ipVersion: 'IPv4', businessType: 'DNS', poolId: 'pool_default_dual', lineId: 'line-01', bytes: 1.2 * 1024 ** 2, result: '低延迟线路' },
  { id: 'hit-03', time: '16:19:35', ruleId: 'rule_template_2', ipVersion: 'IPv6', businessType: '网络上行', poolId: 'pool_ipv6_native_inbound', lineId: 'line-02', bytes: 2.1 * GB, result: '原生入站资格通过' },
  { id: 'hit-04', time: '16:19:12', ruleId: 'rule_legacy_video', ipVersion: 'IPv4', businessType: '视频流量', poolId: 'pool_default_dual', lineId: 'line-05', bytes: 386 * 1024 ** 2, result: '目标运营商优先' },
  { id: 'hit-05', time: '16:18:56', ruleId: 'rule_default', ipVersion: 'IPv6', businessType: '普通上网', poolId: 'pool_ipv6_default', lineId: 'line-03', bytes: 94 * 1024 ** 2, result: '默认智能调度' },
  { id: 'hit-06', time: '16:18:40', ruleId: 'rule_template_5', ipVersion: 'IPv4', businessType: '系统管理', poolId: 'pool_stable', lineId: 'line-02', bytes: 18 * 1024 ** 2, result: '稳定优先' },
]

export const mockRuleChangeLogs = [
  { id: 'change-01', time: '2026-07-23 16:05:20', ruleName: '网络上行最大利用率', action: '修改', detail: '目标利用率由92%调整为93%' },
  { id: 'change-02', time: '2026-07-23 15:48:11', ruleName: 'IPv6兼容出站', action: '启用', detail: '允许无PD但出站检测通过的线路参与' },
  { id: 'change-03', time: '2026-07-23 15:30:44', ruleName: '视频走电信', action: '迁移', detail: '从原分流规则页面迁移并保留历史统计' },
  { id: 'change-04', time: '2026-07-23 15:29:10', ruleName: '默认智能调度', action: '系统保护', detail: '确认末尾兜底规则不可删除' },
]
