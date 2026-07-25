export const ACCESS_TYPE_OPTIONS = Object.freeze([
  {
    value: 'pppoe',
    label: '宽带账号拨号',
    shortLabel: 'PPPoE拨号',
    description: '通过运营商账号认证建立宽带会话，并获取地址、域名服务器和连接参数。',
    detail: 'PPPoE是以太网上的点对点拨号协议。认证成功后运营商才会返回会话状态、IP地址、对端信息、DNS和MTU。',
  },
  {
    value: 'dhcp',
    label: '自动获取地址',
    shortLabel: 'DHCP接入',
    description: '无需宽带账号，由上游自动分配地址、网关、域名服务器和租期。',
    detail: 'DHCP是动态主机配置协议，用于自动获取IP地址、默认网关、DNS和租期。',
  },
  {
    value: 'vlan_pppoe',
    label: '指定通道宽带拨号',
    shortLabel: 'VLAN上的PPPoE',
    description: '先进入指定VLAN通道，再在该通道上运行宽带账号拨号。',
    detail: 'VLAN只是逻辑隔离通道，本身不会提供IP地址、DNS或默认路由；实际网络参数来自该通道上的PPPoE拨号。',
  },
  {
    value: 'vlan_dhcp',
    label: '指定通道自动获取',
    shortLabel: 'VLAN上的DHCP',
    description: '先进入指定VLAN通道，再由上游自动分配网络参数。',
    detail: 'VLAN只是逻辑隔离通道，本身不会提供IP地址、DNS或默认路由；实际网络参数来自该通道上的DHCP。',
  },
])

export const IPV6_CAPABILITY_OPTIONS = Object.freeze({
  native_pd: {
    value: 'native_pd',
    label: '原生IPv6 + PD',
    explanation: '已获得全局IPv6地址、默认路由和运营商前缀，可为局域网分配原生公网IPv6子网。',
    tagType: 'success',
  },
  native_no_pd: {
    value: 'native_no_pd',
    label: '原生IPv6无PD',
    explanation: '外网线路已获得全局IPv6地址，但没有可分配给局域网的运营商前缀。',
    tagType: 'warning',
  },
  compat_outbound: {
    value: 'compat_outbound',
    label: '无PD兼容出站',
    explanation: '没有运营商前缀，但具备全局IPv6地址和出站能力，可在兼容检测通过后参与IPv6出站调度。',
    tagType: 'warning',
  },
  relay: {
    value: 'relay',
    label: 'IPv6中继',
    explanation: '通过路由器公告、IPv6参数分配和邻居发现中继取得配置，检测通过后参与调度。',
    tagType: 'warning',
  },
  link_local_only: {
    value: 'link_local_only',
    label: '仅链路本地IPv6',
    explanation: 'IPv6链路已建立，但未获得公网IPv6地址，暂不加入IPv6调度。',
    tagType: 'info',
  },
  ipv4_only: {
    value: 'ipv4_only',
    label: '仅IPv4',
    explanation: '当前没有可用IPv6承载方式，只退出IPv6线路池，不影响IPv4调度。',
    tagType: 'info',
  },
  error: {
    value: 'error',
    label: 'IPv6异常',
    explanation: '已获取部分IPv6参数，但默认路由、互联网连通性或健康检查未通过。',
    tagType: 'danger',
  },
  detecting: {
    value: 'detecting',
    label: '检测中',
    explanation: '正在验证全局地址、默认路由、互联网连通性或兼容承载方式。',
    tagType: 'primary',
  },
})

export const PARAMETER_STATE_OPTIONS = Object.freeze({
  acquired: { label: '已获取', tagType: 'success' },
  missing: { label: '未获取', tagType: 'info' },
  detecting: { label: '检测中', tagType: 'warning' },
})

const stringifyList = value => Array.isArray(value) && value.length ? value.join(', ') : ''

export function createLineCapability(value = {}) {
  return {
    lineId: String(value.lineId || ''),
    lineName: String(value.lineName || ''),
    carrier: String(value.carrier || '其他运营商'),
    accessType: String(value.accessType || 'pppoe'),
    physicalPort: String(value.physicalPort || '—'),
    vlanId: value.vlanId == null ? null : Number(value.vlanId),
    linkDetected: value.linkDetected === true,
    authenticationSucceeded: value.authenticationSucceeded === true,
    sessionId: String(value.sessionId || '—'),
    mtu: Number(value.mtu || 1500),
    detectedAt: String(value.detectedAt || '—'),
    updatedAt: String(value.updatedAt || '—'),

    ipv4Address: String(value.ipv4Address || ''),
    ipv4PrefixLength: value.ipv4PrefixLength == null ? null : Number(value.ipv4PrefixLength),
    ipv4Gateway: String(value.ipv4Gateway || ''),
    ipv4DnsServers: Array.isArray(value.ipv4DnsServers) ? [...value.ipv4DnsServers] : [],
    ipv4LeaseTime: String(value.ipv4LeaseTime || ''),
    ipv4RouteAvailable: value.ipv4RouteAvailable === true,
    ipv4InternetReachable: value.ipv4InternetReachable === true,
    ipv4AddressType: String(value.ipv4AddressType || 'unknown'),
    ipv4SchedulingEligible: false,
    ipv4IneligibleReason: '',
    ipv4HealthPassed: value.ipv4HealthPassed !== false,

    ipv6CpOpened: value.ipv6CpOpened === true,
    ipv6LinkLocalAddress: String(value.ipv6LinkLocalAddress || ''),
    ipv6GlobalAddresses: Array.isArray(value.ipv6GlobalAddresses)
      ? [...value.ipv6GlobalAddresses]
      : [],
    ipv6DefaultRoute: String(value.ipv6DefaultRoute || ''),
    ipv6DnsServers: Array.isArray(value.ipv6DnsServers) ? [...value.ipv6DnsServers] : [],
    ipv6PrefixDelegations: Array.isArray(value.ipv6PrefixDelegations)
      ? value.ipv6PrefixDelegations.map(item => ({ ...item }))
      : [],
    ipv6PrefixLength: value.ipv6PrefixLength == null ? null : Number(value.ipv6PrefixLength),
    ipv6PreferredLifetime: String(value.ipv6PreferredLifetime || ''),
    ipv6ValidLifetime: String(value.ipv6ValidLifetime || ''),
    ipv6InternetReachable: value.ipv6InternetReachable === true,
    ipv6SchedulingEligible: false,
    ipv6NativeLanEligible: false,
    ipv6CompatibilityMode: String(value.ipv6CompatibilityMode || 'none'),
    ipv6IneligibleReason: '',
    ipv6HealthPassed: value.ipv6HealthPassed !== false,
    ipv6DetectionPending: value.ipv6DetectionPending === true,

    cdnIpv4OutboundEligible: false,
    cdnIpv4InboundEligible: false,
    cdnIpv6OutboundEligible: false,
    cdnIpv6InboundEligible: false,
    publicReachability: String(value.publicReachability || 'unreachable'),
    returnPathSymmetric: value.returnPathSymmetric ?? null,
    publishedAddresses: Array.isArray(value.publishedAddresses)
      ? [...value.publishedAddresses]
      : [],
    inboundFailureReason: '',
  }
}

export function evaluateLineCapability(raw = {}) {
  const line = createLineCapability(raw)
  const ipv4Checks = [
    [Boolean(line.ipv4Address), '未获得IPv4地址'],
    [line.ipv4RouteAvailable && Boolean(line.ipv4Gateway), '没有可用IPv4默认路由'],
    [line.ipv4InternetReachable, 'IPv4互联网连通性检测未通过'],
    [line.ipv4HealthPassed, 'IPv4健康检查未通过'],
  ]
  const ipv4Failure = ipv4Checks.find(([passed]) => !passed)
  line.ipv4SchedulingEligible = !ipv4Failure
  line.ipv4IneligibleReason = ipv4Failure?.[1] || ''

  const hasGlobalIpv6 = line.ipv6GlobalAddresses.length > 0
  const hasPd = line.ipv6PrefixDelegations.length > 0
  const ipv6Checks = [
    [hasGlobalIpv6, line.ipv6LinkLocalAddress
      ? 'IPv6链路已建立，但未获得公网IPv6'
      : '未获得全局IPv6地址'],
    [Boolean(line.ipv6DefaultRoute), '没有可用IPv6默认路由'],
    [line.ipv6InternetReachable, 'IPv6互联网连通性检测未通过'],
    [line.ipv6HealthPassed, 'IPv6健康检查未通过'],
  ]
  const ipv6Failure = ipv6Checks.find(([passed]) => !passed)
  line.ipv6SchedulingEligible = !ipv6Failure && !line.ipv6DetectionPending
  line.ipv6NativeLanEligible = line.ipv6SchedulingEligible && hasPd
  line.ipv6IneligibleReason = line.ipv6DetectionPending
    ? 'IPv6能力仍在检测中'
    : ipv6Failure?.[1] || ''

  line.cdnIpv4OutboundEligible = line.ipv4SchedulingEligible
  line.cdnIpv4InboundEligible = line.ipv4SchedulingEligible
    && line.publicReachability === 'reachable'
    && line.returnPathSymmetric === true
  line.cdnIpv6OutboundEligible = line.ipv6SchedulingEligible
  line.cdnIpv6InboundEligible = line.ipv6SchedulingEligible
    && hasPd
    && line.publicReachability === 'reachable'
    && line.returnPathSymmetric === true

  if (line.publicReachability !== 'reachable') {
    line.inboundFailureReason = '公网端口可达性检测未通过'
  } else if (line.returnPathSymmetric !== true) {
    line.inboundFailureReason = '入站与回程未使用同一运营商线路'
  } else if (!hasPd && hasGlobalIpv6) {
    line.inboundFailureReason = '没有可用于原生IPv6入站的运营商前缀'
  }

  return line
}

export function getAccessTypeMeta(value) {
  return ACCESS_TYPE_OPTIONS.find(option => option.value === value)
    || ACCESS_TYPE_OPTIONS[0]
}

export function getIpv6CapabilityMeta(line) {
  if (line.ipv6DetectionPending) return IPV6_CAPABILITY_OPTIONS.detecting
  if (!line.ipv6CpOpened && !line.ipv6LinkLocalAddress) return IPV6_CAPABILITY_OPTIONS.ipv4_only
  if (!line.ipv6GlobalAddresses?.length && line.ipv6LinkLocalAddress) {
    return IPV6_CAPABILITY_OPTIONS.link_local_only
  }
  if (!line.ipv6SchedulingEligible && line.ipv6GlobalAddresses?.length) {
    return IPV6_CAPABILITY_OPTIONS.error
  }
  if (line.ipv6PrefixDelegations?.length) return IPV6_CAPABILITY_OPTIONS.native_pd
  if (line.ipv6CompatibilityMode === 'relay') return IPV6_CAPABILITY_OPTIONS.relay
  if (line.ipv6CompatibilityMode === 'nat66_outbound') {
    return IPV6_CAPABILITY_OPTIONS.compat_outbound
  }
  if (line.ipv6GlobalAddresses?.length) return IPV6_CAPABILITY_OPTIONS.native_no_pd
  return IPV6_CAPABILITY_OPTIONS.ipv4_only
}

export function getCapabilityParameterStates(line) {
  const detecting = line.ipv6DetectionPending ? 'detecting' : 'missing'
  return [
    {
      group: '基础接入',
      label: '物理链路',
      state: line.linkDetected ? 'acquired' : 'missing',
      value: line.linkDetected ? '已检测到连接' : '未检测到连接',
    },
    {
      group: '基础接入',
      label: '运营商认证',
      state: line.authenticationSucceeded ? 'acquired' : 'missing',
      value: line.authenticationSucceeded ? '认证成功' : '未认证或无需认证',
    },
    {
      group: 'IPv4',
      label: 'IPv4地址',
      state: line.ipv4Address ? 'acquired' : 'missing',
      value: line.ipv4Address
        ? `${line.ipv4Address}/${line.ipv4PrefixLength ?? '—'}`
        : '未获得',
    },
    {
      group: 'IPv4',
      label: 'IPv4默认路由',
      state: line.ipv4RouteAvailable ? 'acquired' : 'missing',
      value: line.ipv4Gateway || '未获得',
    },
    {
      group: 'IPv4',
      label: 'IPv4域名服务器',
      state: line.ipv4DnsServers.length ? 'acquired' : 'missing',
      value: stringifyList(line.ipv4DnsServers) || '未获得',
    },
    {
      group: 'IPv6',
      label: 'IPv6链路本地地址',
      state: line.ipv6LinkLocalAddress ? 'acquired' : detecting,
      value: line.ipv6LinkLocalAddress || (detecting === 'detecting' ? '检测中' : '未获得'),
    },
    {
      group: 'IPv6',
      label: 'IPv6全局地址',
      state: line.ipv6GlobalAddresses.length ? 'acquired' : detecting,
      value: stringifyList(line.ipv6GlobalAddresses)
        || (detecting === 'detecting' ? '检测中' : '未获得'),
    },
    {
      group: 'IPv6',
      label: 'IPv6默认路由',
      state: line.ipv6DefaultRoute ? 'acquired' : detecting,
      value: line.ipv6DefaultRoute || (detecting === 'detecting' ? '检测中' : '未获得'),
    },
    {
      group: 'IPv6',
      label: '运营商前缀（IPv6-PD）',
      state: line.ipv6PrefixDelegations.length ? 'acquired' : detecting,
      value: line.ipv6PrefixDelegations.length
        ? line.ipv6PrefixDelegations
          .map(item => `${item.prefix}/${item.length}`)
          .join(', ')
        : detecting === 'detecting' ? '检测中' : '未获得',
    },
  ]
}
