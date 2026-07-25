import BRAND from '../config/brand.js'

export const IPV6_DNS_HANDLING_OPTIONS = Object.freeze([
  {
    value: 'wan_follow',
    label: '跟随出口线路',
    badge: '推荐',
    description: 'IPv6连接使用哪条出口线路，就优先使用该线路获得的运营商DNS。',
    detail: '适合多线路环境，可让域名解析与实际IPv6出口保持一致，减少跨运营商解析带来的绕行。',
  },
  {
    value: 'linehub_proxy',
    label: '系统统一转发',
    description: `所有IPv6 DNS请求由${BRAND.gatewayName}统一接收、缓存并转发。`,
    detail: `局域网设备只访问${BRAND.gatewayName}，由系统统一选择上游DNS并提供缓存。`,
  },
  {
    value: 'custom',
    label: '自定义DNS',
    badge: '高级',
    description: '用户手动设置IPv6 DNS服务器。',
    detail: '适合已有固定DNS服务的场景。填写错误或服务器不可达时可能影响域名解析。',
  },
])

export const NO_PD_HANDLING_OPTIONS = Object.freeze([
  {
    value: 'auto_best',
    label: '自动选择最佳方式',
    badge: '推荐',
    description: '按线路实际获得的IPv6地址、前缀和上游能力自动选择可用方式。',
    detail: [
      '获得PD时使用原生IPv6前缀。',
      '无PD但外网线路（WAN）获得公网IPv6地址时，尝试兼容出站模式。',
      '上游支持中继时可尝试IPv6中继。',
      '完全没有可用IPv6时，才退出IPv6调度。',
      '不影响该线路继续参与IPv4调度。',
    ],
    scheduling: '检测通过后参与',
    outbound: '支持，按检测结果选择',
    inbound: '获得原生前缀时适合',
    requiresPd: '不强制，服务器原生入站需要',
    translation: '必要时使用',
    ipv4Impact: '无影响，IPv4独立调度',
    risk: 'recommended',
  },
  {
    value: 'native_pd_only',
    label: '仅使用原生IPv6前缀',
    description: '只有获得PD的线路才参与IPv6调度。适合要求服务器持有原生运营商公网IPv6地址的业务。',
    detail: ['未获得PD的线路仍可继续参与IPv4调度。'],
    scheduling: '仅获得PD后参与',
    outbound: '支持',
    inbound: '适合服务器入站服务',
    requiresPd: '需要',
    translation: '不使用',
    ipv4Impact: '无影响，IPv4独立调度',
  },
  {
    value: 'nat66_outbound',
    label: 'NAT66兼容出站',
    badge: '高级',
    description: '无PD但外网线路（WAN）获得公网IPv6地址时，让局域网（LAN）的IPv6流量通过地址转换从该线路出站。主要适合出站流量，不等同于原生公网前缀。',
    detail: ['该方式依赖外网线路具备可用公网IPv6地址，本阶段仅展示前端演示状态。'],
    scheduling: '兼容检测通过后参与',
    outbound: '支持',
    inbound: '通常不适合服务器入站',
    requiresPd: '不需要',
    translation: '使用IPv6地址转换',
    ipv4Impact: '无影响，IPv4独立调度',
    risk: 'advanced',
  },
  {
    value: 'ipv6_relay',
    label: 'IPv6中继',
    badge: '高级',
    description: '尝试通过路由器公告（RA）、IPv6参数分配（DHCPv6）和邻居发现（NDP）中继，让局域网设备从上游取得IPv6配置。该模式属于高级功能，必须经过连通性检测后才能加入调度。',
    detail: ['RA用于发布网络信息，DHCPv6用于下发IPv6配置，NDP用于发现同一链路上的IPv6邻居。'],
    scheduling: '连通性检测通过后参与',
    outbound: '检测通过后支持',
    inbound: '取决于上游中继能力',
    requiresPd: '不强制',
    translation: '不使用',
    ipv4Impact: '无影响，IPv4独立调度',
    risk: 'advanced',
  },
  {
    value: 'ipv6_disabled',
    label: '不参与IPv6调度',
    description: '该线路只参与IPv4调度，IPv6流量不会选择此线路。',
    detail: ['只有确认线路没有任何可行IPv6承载方式，或用户明确停用时才应选择。'],
    scheduling: '不参与',
    outbound: '不支持',
    inbound: '不支持',
    requiresPd: '不适用',
    translation: '不使用',
    ipv4Impact: '无影响，继续参与IPv4调度',
    risk: 'warning',
  },
])

export const IPV6_CAPABILITY_STATES = Object.freeze({
  native_ipv6: {
    value: 'native_ipv6',
    label: '原生IPv6',
    explanation: '外网线路已获得公网IPv6地址，但当前没有可下发给局域网的前缀。',
    tagType: 'success',
  },
  native_ipv6_pd: {
    value: 'native_ipv6_pd',
    label: '原生IPv6 + PD',
    explanation: '已获得公网IPv6地址和运营商前缀，可为局域网分配原生IPv6子网。',
    tagType: 'success',
  },
  no_pd_compat: {
    value: 'no_pd_compat',
    label: '无PD兼容出站',
    explanation: '没有可下发前缀，但已获得公网IPv6地址，可在检测通过后用于兼容出站。',
    tagType: 'warning',
  },
  ipv6_relay: {
    value: 'ipv6_relay',
    label: 'IPv6中继',
    explanation: '通过上游中继获得IPv6配置，连通性检测通过后才参与调度。',
    tagType: 'warning',
  },
  ipv4_only: {
    value: 'ipv4_only',
    label: '仅IPv4',
    explanation: '当前未发现可用IPv6承载方式，IPv4仍可独立参与调度。',
    tagType: 'info',
  },
  ipv6_error: {
    value: 'ipv6_error',
    label: 'IPv6异常',
    explanation: '已发现IPv6能力，但健康检查未通过，暂时退出IPv6调度。',
    tagType: 'danger',
  },
  detecting: {
    value: 'detecting',
    label: '检测中',
    explanation: '正在检测原生前缀、兼容出站或中继能力，检测完成前不加入IPv6调度。',
    tagType: 'primary',
  },
})

const NO_PD_ALIASES = Object.freeze({
  exclude: 'auto_best',
  ipv4_only: 'auto_best',
  nat66_fallback: 'nat66_outbound',
  native: 'native_pd_only',
  relay: 'ipv6_relay',
})

export function normalizeNoPdHandling(value) {
  const normalized = NO_PD_ALIASES[value] || value
  return NO_PD_HANDLING_OPTIONS.some(option => option.value === normalized)
    ? normalized
    : 'auto_best'
}

export function normalizeIpv6DnsStrategy(value) {
  return IPV6_DNS_HANDLING_OPTIONS.some(option => option.value === value)
    ? value
    : 'wan_follow'
}

export function getNoPdHandlingOption(value) {
  const normalized = normalizeNoPdHandling(value)
  return NO_PD_HANDLING_OPTIONS.find(option => option.value === normalized)
}

export function getIpv6DnsHandlingOption(value) {
  const normalized = normalizeIpv6DnsStrategy(value)
  return IPV6_DNS_HANDLING_OPTIONS.find(option => option.value === normalized)
}

export function resolveIpv6Capability(line, noPdHandling = 'auto_best') {
  const runtime = line?.runtimeStatus || {}
  const ipv6 = runtime.ipv6 || {}
  const explicit = runtime.ipv6CapabilityState
  let state = IPV6_CAPABILITY_STATES[explicit] ? explicit : ''

  if (!state) {
    const hasPd = Boolean(ipv6.hasUsablePd || ipv6.delegatedPrefixes?.length)
    const hasGlobalAddress = Array.isArray(ipv6.globalAddresses)
      && ipv6.globalAddresses.some(address => address && address !== '-')

    if (ipv6.state === 'detecting') state = 'detecting'
    else if (ipv6.state === 'error') state = 'ipv6_error'
    else if (ipv6.state !== 'online') state = 'ipv4_only'
    else if (hasPd) state = 'native_ipv6_pd'
    else if (hasGlobalAddress && normalizeNoPdHandling(noPdHandling) === 'auto_best') {
      state = 'no_pd_compat'
    } else if (hasGlobalAddress) state = 'native_ipv6'
    else state = 'detecting'
  }

  const capability = IPV6_CAPABILITY_STATES[state]
  const eligible = ['native_ipv6_pd', 'no_pd_compat', 'ipv6_relay'].includes(state)
    || (state === 'native_ipv6' && normalizeNoPdHandling(noPdHandling) === 'nat66_outbound')

  return {
    ...capability,
    eligible,
    eligibilityLabel: eligible ? '可参与IPv6调度' : state === 'detecting' ? '检测后决定' : '暂不参与IPv6调度',
  }
}
