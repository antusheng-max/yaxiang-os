export function getDialStatus(instance) {
  if (!instance?.enabled) return 'disabled'

  const runtime = instance.runtimeStatus || {}
  if (runtime.pppoeState === 'dialing') return 'dialing'
  if (runtime.pppoeState === 'redialing') return 'redialing'
  if (runtime.pppoeState === 'auth_failed') return 'authFail'
  if (runtime.pppoeState !== 'connected') return 'offline'

  const ipv4Online = runtime.ipv4?.state === 'online'
  const ipv6Online = runtime.ipv6?.state === 'online'

  if (ipv4Online && ipv6Online && runtime.ipv6?.hasUsablePd) return 'dualStack'
  if (ipv4Online && ipv6Online) return 'ipv6NoPd'
  if (ipv4Online) return 'ipv4Only'
  if (ipv6Online) return 'ipv6Only'
  return 'offline'
}

export function getDialHealth(instance) {
  const state = instance?.runtimeStatus?.healthState
  if (state === 'healthy') return 'ok'
  if (state === 'offline') return 'fail'
  if (state) return 'warning'
  return 'unknown'
}

export function formatBytes(bytes) {
  const value = Number(bytes) || 0
  if (value >= 1024 ** 3) return `${(value / 1024 ** 3).toFixed(2)}G`
  if (value >= 1024 ** 2) return `${(value / 1024 ** 2).toFixed(1)}M`
  if (value >= 1024) return `${(value / 1024).toFixed(0)}K`
  return `${value}`
}

export function maskBroadbandAccount(account) {
  const value = String(account || '')
  if (!value) return '—'
  const [local, domain] = value.split('@')
  const visible = local.length <= 2
    ? `${local.slice(0, 1)}***`
    : `${local.slice(0, 3)}***${local.slice(-1)}`
  return domain ? `${visible}@${domain}` : visible
}

export function getProtocolLineStatus(instance, protocol) {
  if (!instance?.enabled) return 'disabled'
  const runtime = instance.runtimeStatus || {}
  const protocolState = runtime[protocol]?.state
  if (runtime.pppoeState !== 'connected') return 'offline'
  if (protocolState !== 'online') return 'abnormal'
  if (protocol === 'ipv6' && !runtime.ipv6?.hasUsablePd) return 'limited'
  return 'online'
}

export function getLineQuality(instance) {
  const runtime = instance?.runtimeStatus || {}
  if (runtime.pppoeState !== 'connected') return '离线'
  const loss = Math.max(
    Number(runtime.ipv4?.packetLoss) || 0,
    Number(runtime.ipv6?.packetLoss) || 0,
  )
  const latency = Math.max(
    Number(runtime.ipv4?.latency) || 0,
    Number(runtime.ipv6?.latency) || 0,
  )
  if (loss >= 3) return '较差'
  if (loss >= 1 || latency >= 100) return '一般'
  if (loss >= 0.3 || latency >= 50 || runtime.healthState !== 'healthy') return '良好'
  return '优秀'
}

export function toDialStatusRow(instance) {
  const runtime = instance.runtimeStatus || {}
  const ipv4 = runtime.ipv4 || {}
  const ipv6 = runtime.ipv6 || {}
  const delegatedPrefixes = ipv6.delegatedPrefixes || []

  return {
    ...instance,
    maskedUsername: maskBroadbandAccount(instance.username),
    carrier: instance.carrier || '其他运营商',
    configuredUploadMbps: Number(instance.configuredUploadMbps) || 100,
    currentUploadMbps: Number(runtime.txRate) || 0,
    uploadUtilizationPercent: Number((
      (Number(runtime.txRate) || 0) / (Number(instance.configuredUploadMbps) || 100) * 100
    ).toFixed(1)),
    ipv4LineStatus: getProtocolLineStatus(instance, 'ipv4'),
    ipv6LineStatus: getProtocolLineStatus(instance, 'ipv6'),
    lineQuality: getLineQuality(instance),
    channelId: instance.accessChannelId,
    account: instance.username,
    groupId: instance.aggregationGroupId,
    status: getDialStatus(instance),
    sessionId: runtime.sessionId,
    uptime: runtime.uptime,
    ipv4Address: ipv4.address,
    ipv4Peer: ipv4.peerAddress,
    ipv4Dns: (ipv4.dnsServers || []).join(', '),
    ipv6LinkLocal: ipv6.linkLocalAddress,
    ipv6Address: (ipv6.globalAddresses || []).join(', '),
    ipv6Pd: delegatedPrefixes.map(item => `${item.prefix}/${item.length}`).join(', '),
    ipv6Dns: (ipv6.dnsServers || []).join(', '),
    ipv4Latency: ipv4.latency,
    ipv6Latency: ipv6.latency,
    lossRate: Math.max(Number(ipv4.packetLoss) || 0, Number(ipv6.packetLoss) || 0),
    rxRate: `${Number(runtime.rxRate) || 0} Mbps`,
    txRate: `${Number(runtime.txRate) || 0} Mbps`,
    rxTotal: formatBytes(runtime.rxBytes),
    txTotal: formatBytes(runtime.txBytes),
    // Mock 数据尚未按协议栈拆分流量，演示视图按 70/30 估算；真实接口接入后直接使用后端计数器。
    ipv4RxTotal: formatBytes((Number(runtime.rxBytes) || 0) * 0.7),
    ipv4TxTotal: formatBytes((Number(runtime.txBytes) || 0) * 0.7),
    ipv6RxTotal: formatBytes((Number(runtime.rxBytes) || 0) * 0.3),
    ipv6TxTotal: formatBytes((Number(runtime.txBytes) || 0) * 0.3),
    connections: Number(runtime.activeConnections) || 0,
    weight: Number(runtime.currentWeight) || 0,
    health: getDialHealth(instance),
    lastDownTime: runtime.lastDisconnectTime,
    lastDownReason: runtime.lastDisconnectReason,
  }
}
