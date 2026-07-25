/**
 * 亚象网络操作系统 — 统一数据服务层
 * 提供 Mock 和真实后端的抽象接口
 * 页面组件不直接读取硬编码数组，统一通过此层访问数据
 */

import { usePersistentRef } from '../composables/usePersistentRef.js'
import {
  normalizeIpv6DnsStrategy,
  normalizeNoPdHandling,
} from '../models/dualStackAggregation.js'

// ===== 运行模式 =====
const APP_MODE = import.meta.env.VITE_APP_MODE || 'mock' // 'mock' | 'real'

// 生产安全: 不静态导入dev-mock，使用空数组作为默认值
// Mock数据通过动态import()按需加载
const _mockDefaults = {
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
}

export function isMockMode() {
  return APP_MODE === 'mock'
}

export function getAppMode() {
  return APP_MODE
}

// ===== 持久化数据仓库 =====
const _ports = usePersistentRef('svc:physicalPorts', _mockDefaults.mockPhysicalPorts)
const _channels = usePersistentRef('svc:accessChannels', _mockDefaults.mockAccessChannels)
const _dials = usePersistentRef('svc:dialInstances', _mockDefaults.mockDialInstances)
const _groups = usePersistentRef('svc:aggregationGroups', _mockDefaults.mockAggregationGroups)
const _lans = usePersistentRef('svc:lanNetworks', _mockDefaults.mockLanNetworks)
const _policies = usePersistentRef('svc:schedulingPolicies', _mockDefaults.mockSchedulingPolicies)
const _healthPolicies = usePersistentRef('svc:healthCheckPolicies', _mockDefaults.mockHealthCheckPolicies)
const _prefixMappings = usePersistentRef('svc:prefixMappings', _mockDefaults.mockPrefixMappings)
const _pendingChanges = usePersistentRef('svc:pendingChanges', _mockDefaults.mockPendingChanges)

// ===== 工具函数 =====
function _find(arr, id) { return arr.value.find(i => i.id === id) }
function _filter(arr, key, val) { return arr.value.filter(i => i[key] === val) }
function _remove(arr, id) {
  const idx = arr.value.findIndex(i => i.id === id)
  if (idx >= 0) { arr.value.splice(idx, 1); return true }
  return false
}
function _addPending(type, target, description) {
  _pendingChanges.value.push({
    id: genId('pc'), type, target, description, timestamp: new Date().toISOString()
  })
}

function _emptyRuntimeStatus() {
  return {
    pppoeState: 'disconnected',
    sessionId: '-',
    uptime: '-',
    ipv4: {
      state: 'offline', address: '-', peerAddress: '-', gateway: '-',
      dnsServers: [], latency: 0, packetLoss: 0,
    },
    ipv6: {
      state: 'offline', linkLocalAddress: '-', globalAddresses: [],
      delegatedPrefixes: [], gateway: '-', dnsServers: [], latency: 0,
      packetLoss: 0, hasUsablePd: false,
    },
    rxRate: 0,
    txRate: 0,
    rxBytes: 0,
    txBytes: 0,
    activeConnections: 0,
    currentWeight: 0,
    healthState: 'offline',
    lastDisconnectTime: '-',
    lastDisconnectReason: '-',
  }
}

function _resolvePhysicalPortId(value) {
  if (value == null || value === '') return ''
  const direct = _ports.value.find(port => port.id === value || port.name === value)
  if (direct) return direct.id

  const name = String(value).startsWith('eth') ? String(value) : `eth${value}`
  return _ports.value.find(port => port.name === name)?.id || ''
}

const LINE_PROFILE_BY_VLAN = Object.freeze({
  101: { carrier: '中国电信', configuredUploadMbps: 50 },
  103: { carrier: '中国联通', configuredUploadMbps: 50 },
  105: { carrier: '中国移动', configuredUploadMbps: 100 },
  107: { carrier: '中国电信', configuredUploadMbps: 50 },
  109: { carrier: '中国广电', configuredUploadMbps: 30 },
  111: { carrier: '中国联通', configuredUploadMbps: 50 },
})

function _normalizeAccessChannel(data) {
  const {
    portId, vlan, mode, ...rest
  } = data || {}
  const physicalPortId = _resolvePhysicalPortId(rest.physicalPortId ?? portId)
  const port = _find(_ports, physicalPortId)
  const vlanId = rest.vlanId ?? vlan ?? null
  const tagMode = rest.tagMode || mode || (vlanId == null ? 'untagged' : 'dot1q')

  return {
    ...rest,
    physicalPortId,
    tagMode,
    vlanId,
    deviceName: rest.deviceName || (
      port ? `${port.name}${vlanId == null ? '' : `.${vlanId}`}` : ''
    ),
    mtu: Number(rest.mtu) || 1500,
    macMode: rest.macMode || 'shared',
    status: rest.status || 'down',
  }
}

function _normalizeDialInstance(data) {
  const {
    channelId, account, password, autoRedial, mac, groupId,
    ipv4Auto, ipv4PeerDns, ipv4Dns, ipv4DefaultRoute, ipv4Metric,
    ipv6Enabled, ipv6cp, dhcpv6Client, iaNa, iaPd, pdLength,
    ipv6PeerDns, ipv6DefaultRoute, pdAutoUpdate,
    ...rest
  } = data || {}
  const accessChannelId = rest.accessChannelId || channelId || ''
  const channel = _find(_channels, accessChannelId)
  const lineProfile = LINE_PROFILE_BY_VLAN[channel?.vlanId] || {}

  return {
    ...rest,
    accessChannelId,
    username: rest.username || account || '',
    passwordConfigured: rest.passwordConfigured ?? Boolean(password),
    carrier: rest.carrier || lineProfile.carrier || '其他运营商',
    configuredUploadMbps: Number(
      rest.configuredUploadMbps ?? lineProfile.configuredUploadMbps ?? 100,
    ),
    macMode: rest.macMode || 'auto',
    macAddress: rest.macAddress ?? mac ?? '',
    hostUniqMode: rest.hostUniqMode || 'auto',
    hostUniq: rest.hostUniq || '',
    serviceName: rest.serviceName || '',
    mtu: Number(rest.mtu) || 1492,
    enabled: rest.enabled ?? true,
    autoDial: rest.autoDial ?? true,
    redialOnDisconnect: rest.redialOnDisconnect ?? autoRedial ?? true,
    redialInterval: Number(rest.redialInterval) || 10,
    ipv4Config: {
      autoAcquire: rest.ipv4Config?.autoAcquire ?? ipv4Auto ?? true,
      acquireDns: rest.ipv4Config?.acquireDns ?? ipv4PeerDns ?? true,
      customDns: rest.ipv4Config?.customDns ?? ipv4Dns ?? '',
      defaultRoute: rest.ipv4Config?.defaultRoute ?? ipv4DefaultRoute ?? true,
      metric: rest.ipv4Config?.metric ?? ipv4Metric ?? 10,
    },
    ipv6Config: {
      enabled: rest.ipv6Config?.enabled ?? ipv6Enabled ?? true,
      enableIpv6cp: rest.ipv6Config?.enableIpv6cp ?? ipv6cp ?? true,
      dhcpv6Client: rest.ipv6Config?.dhcpv6Client ?? dhcpv6Client ?? true,
      iaNa: rest.ipv6Config?.iaNa ?? iaNa ?? 'auto',
      iaPd: rest.ipv6Config?.iaPd ?? iaPd ?? 'auto',
      prefixLength: rest.ipv6Config?.prefixLength ?? pdLength ?? 'auto',
      acquireDns: rest.ipv6Config?.acquireDns ?? ipv6PeerDns ?? true,
      defaultRoute: rest.ipv6Config?.defaultRoute ?? ipv6DefaultRoute ?? true,
      autoUpdatePrefix: rest.ipv6Config?.autoUpdatePrefix ?? pdAutoUpdate ?? true,
    },
    runtimeStatus: rest.runtimeStatus || _emptyRuntimeStatus(),
    aggregationGroupId: rest.aggregationGroupId || groupId || '',
  }
}

function _normalizeAggregationGroup(data) {
  const {
    memberIds, bindLan, bindLanPort, schedulePolicyId, healthPolicyId,
    ipv4Enabled, ipv4Mode, ipv4Schedule, ipv4Sticky, ipv4ReturnKeep,
    ipv4FailRemove, ipv4RecoverAdd, ipv4TcpPolicy, ipv4UdpPolicy,
    excludeMgmt, excludeTargets, ipv6Enabled, ipv6Mode, lanPrefix, lanGw,
    nptv6, nat66Fallback, ipv6SrcBind, ipv6Sticky, ipv6ReturnKeep,
    pdRebuild, noPdHandle, ipv6DnsPolicy, raMode, runtime,
    ...rest
  } = data || {}

  const lanNetworkId = rest.lanNetworkId
    || _lans.value.find(lan => lan.id === bindLan || lan.name === bindLan)?.id
    || ''
  const lanPhysicalPortId = rest.lanPhysicalPortId
    || _resolvePhysicalPortId(bindLanPort)
  const rawIpv6Mode = rest.ipv6Settings?.mode || ipv6Mode || 'stable_prefix'
  const ipv6ModeAliases = {
    nptv6: 'stable_prefix',
    native: 'native_multi_prefix',
    nat66: 'nat66_compat',
  }
  const normalizedIpv6Mode = ipv6ModeAliases[rawIpv6Mode] || rawIpv6Mode
  const rawNoPdHandling = rest.ipv6Settings?.noPdLineHandling || noPdHandle || 'auto_best'
  const noPdHandlingVersion = Number(rest.ipv6Settings?.noPdHandlingVersion || 0)
  const normalizedNoPdHandling = noPdHandlingVersion >= 2
    ? normalizeNoPdHandling(rawNoPdHandling)
    : 'auto_best'

  return {
    ...rest,
    memberDialInstanceIds: rest.memberDialInstanceIds || memberIds || [],
    lanNetworkId,
    lanPhysicalPortId,
    schedulingPolicyId: rest.schedulingPolicyId || schedulePolicyId || '',
    healthCheckPolicyId: rest.healthCheckPolicyId || healthPolicyId || '',
    ipv4Settings: {
      enabled: rest.ipv4Settings?.enabled ?? ipv4Enabled ?? true,
      mode: rest.ipv4Settings?.mode || ipv4Mode || 'nat_multiwan',
      scheduleMode: rest.ipv4Settings?.scheduleMode || ipv4Schedule || 'weighted',
      sessionPersistence: rest.ipv4Settings?.sessionPersistence ?? ipv4Sticky ?? true,
      returnPathKeep: rest.ipv4Settings?.returnPathKeep ?? ipv4ReturnKeep ?? true,
      autoRemoveFailed: rest.ipv4Settings?.autoRemoveFailed ?? ipv4FailRemove ?? true,
      autoRejoin: rest.ipv4Settings?.autoRejoin ?? ipv4RecoverAdd ?? true,
      tcpSessionPolicy: rest.ipv4Settings?.tcpSessionPolicy || ipv4TcpPolicy || 'source_hash',
      udpSessionPolicy: rest.ipv4Settings?.udpSessionPolicy || ipv4UdpPolicy || 'source_hash',
      excludeMgmtTraffic: rest.ipv4Settings?.excludeMgmtTraffic ?? excludeMgmt ?? true,
      customExcludedTargets: rest.ipv4Settings?.customExcludedTargets || excludeTargets || '',
    },
    ipv6Settings: {
      enabled: rest.ipv6Settings?.enabled ?? ipv6Enabled ?? true,
      mode: normalizedIpv6Mode,
      lanInternalPrefix: rest.ipv6Settings?.lanInternalPrefix || lanPrefix || '',
      lanGateway: rest.ipv6Settings?.lanGateway || lanGw || '',
      nptv6Enabled: normalizedIpv6Mode === 'stable_prefix',
      nat66Fallback: normalizedIpv6Mode === 'nat66_compat',
      sourceAddressBinding: rest.ipv6Settings?.sourceAddressBinding ?? ipv6SrcBind ?? true,
      ipv6SessionPersistence: rest.ipv6Settings?.ipv6SessionPersistence ?? ipv6Sticky ?? true,
      ipv6ReturnPathKeep: rest.ipv6Settings?.ipv6ReturnPathKeep ?? ipv6ReturnKeep ?? true,
      autoRebuildOnPrefixChange: rest.ipv6Settings?.autoRebuildOnPrefixChange ?? pdRebuild ?? true,
      noPdLineHandling: normalizedNoPdHandling,
      noPdHandlingVersion: 2,
      ipv6DnsStrategy: normalizeIpv6DnsStrategy(
        rest.ipv6Settings?.ipv6DnsStrategy || ipv6DnsPolicy || 'wan_follow',
      ),
      customIpv6DnsServers: rest.ipv6Settings?.customIpv6DnsServers || '',
      raMode: rest.ipv6Settings?.raMode || raMode || 'both',
    },
    runtimeStatus: rest.runtimeStatus || runtime || {},
  }
}

function _normalizePolicy(data) {
  const { stickyTime, refGroups, ...rest } = data || {}
  const algorithmAliases = {
    avg: 'round_robin',
    least: 'least_conn_weighted',
    bandwidth: 'bandwidth_aware',
    src: 'source_hash',
    dst: 'destination_hash',
  }
  return {
    ...rest,
    algorithm: algorithmAliases[rest.algorithm] || rest.algorithm || 'least_conn_weighted',
    defaultWeight: Number(rest.defaultWeight) || 100,
    tcpPolicy: rest.tcpPolicy || 'source_hash',
    udpPolicy: rest.udpPolicy || 'source_hash',
    ipv4Policy: rest.ipv4Policy || 'enabled',
    ipv6Policy: rest.ipv6Policy || 'enabled',
    sessionStickyTime: rest.sessionStickyTime ?? stickyTime ?? 300,
    referencedByGroups: Array.isArray(rest.referencedByGroups)
      ? rest.referencedByGroups
      : [],
  }
}

function _normalizeHealthPolicy(data) {
  const {
    type, failThreshold, recoverThreshold, ipv4Target, ipv6Target,
    independent, refGroups, ...rest
  } = data || {}
  return {
    ...rest,
    checkType: rest.checkType || type || 'icmp',
    interval: Number(rest.interval) || 5,
    timeout: Number(rest.timeout) || 3,
    consecutiveFailures: rest.consecutiveFailures ?? failThreshold ?? 3,
    consecutiveRecovery: rest.consecutiveRecovery ?? recoverThreshold ?? 2,
    ipv4Targets: Array.isArray(rest.ipv4Targets)
      ? rest.ipv4Targets
      : String(ipv4Target || '').split(',').map(item => item.trim()).filter(Boolean),
    ipv6Targets: Array.isArray(rest.ipv6Targets)
      ? rest.ipv6Targets
      : String(ipv6Target || '').split(',').map(item => item.trim()).filter(Boolean),
    checkIpv4: rest.checkIpv4 ?? true,
    checkIpv6: rest.checkIpv6 ?? true,
    separateRemoval: rest.separateRemoval ?? independent ?? true,
    referencedByGroups: Array.isArray(rest.referencedByGroups)
      ? rest.referencedByGroups
      : [],
  }
}

function _syncGroupReferences() {
  _policies.value.forEach(policy => {
    policy.referencedByGroups = _groups.value
      .filter(group => group.schedulingPolicyId === policy.id)
      .map(group => group.id)
  })
  _healthPolicies.value.forEach(policy => {
    policy.referencedByGroups = _groups.value
      .filter(group => group.healthCheckPolicyId === policy.id)
      .map(group => group.id)
  })
}

_channels.value = _channels.value.map(_normalizeAccessChannel)
_dials.value = _dials.value.map(_normalizeDialInstance)
_policies.value = _policies.value.map(_normalizePolicy)
_healthPolicies.value = _healthPolicies.value.map(_normalizeHealthPolicy)
_groups.value = _groups.value.map(_normalizeAggregationGroup)
_syncGroupReferences()

// ===== 物理端口服务 =====
export const physicalPortService = {
  list: () => _ports.value,
  get: (id) => _find(_ports, id),
  getByName: (name) => _ports.value.find(p => p.name === name),
  create: (data) => {
    const item = { ...data, id: data.id || genId('port') }
    _ports.value.push(item)
    if (isMockMode()) _addPending('create', 'physical_port', `新建物理端口 ${item.name}`)
    return item
  },
  update: (id, data) => {
    const idx = _ports.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _ports.value[idx] = { ..._ports.value[idx], ...data }
      if (isMockMode()) _addPending('update', 'physical_port', `修改物理端口 ${_ports.value[idx].name}`)
      return _ports.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_ports, id)
    if (!item) return false
    // 检查是否有接入通道依赖
    const channels = _filter(_channels, 'physicalPortId', id)
    if (channels.length > 0) {
      throw new Error(`物理端口 ${item.name} 仍承载 ${channels.length} 个接入通道，无法删除`)
    }
    const ok = _remove(_ports, id)
    if (ok && isMockMode()) _addPending('delete', 'physical_port', `删除物理端口 ${item.name}`)
    return ok
  },
  countChannels: (portId) => _filter(_channels, 'physicalPortId', portId).length,
  countDialInstances: (portId) => {
    const channels = _filter(_channels, 'physicalPortId', portId)
    const channelIds = channels.map(c => c.id)
    return _dials.value.filter(d => channelIds.includes(d.accessChannelId)).length
  },
}

// ===== 接入通道服务 =====
export const accessChannelService = {
  list: () => _channels.value,
  get: (id) => _find(_channels, id),
  getByPort: (portId) => _filter(_channels, 'physicalPortId', portId),
  create: (data) => {
    const item = _normalizeAccessChannel({ ...data, id: data.id || genId('ch') })
    _channels.value.push(item)
    if (isMockMode()) _addPending('create', 'access_channel', `新建接入通道 ${item.name}`)
    return item
  },
  batchCreateVlans: (portId, vlanIds) => {
    const port = _find(_ports, portId)
    if (!port) throw new Error('物理端口不存在')
    const created = []
    vlanIds.forEach(vlanId => {
      const existing = _channels.value.find(c => c.physicalPortId === portId && c.vlanId === vlanId)
      if (existing) return
      const item = {
        id: genId('ch'), name: `channel-${vlanId}`, physicalPortId: portId,
        tagMode: 'dot1q', vlanId, deviceName: `${port.name}.${vlanId}`,
        mtu: 1500, macMode: 'shared', status: 'down'
      }
      _channels.value.push(item)
      created.push(item)
    })
    if (isMockMode()) _addPending('create', 'access_channel', `批量新建 ${created.length} 个接入通道`)
    return created
  },
  update: (id, data) => {
    const idx = _channels.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _channels.value[idx] = _normalizeAccessChannel({ ..._channels.value[idx], ...data, id })
      if (isMockMode()) _addPending('update', 'access_channel', `修改接入通道 ${_channels.value[idx].name}`)
      return _channels.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_channels, id)
    if (!item) return false
    const dials = _filter(_dials, 'accessChannelId', id)
    if (dials.length > 0) {
      throw new Error(`接入通道 ${item.name} 仍承载 ${dials.length} 条线路，无法删除`)
    }
    const ok = _remove(_channels, id)
    if (ok && isMockMode()) _addPending('delete', 'access_channel', `删除接入通道 ${item.name}`)
    return ok
  },
  countDialInstances: (channelId) => _filter(_dials, 'accessChannelId', channelId).length,
}

// ===== PPPoE 拨号实例服务 =====
export const dialInstanceService = {
  list: () => _dials.value,
  get: (id) => _find(_dials, id),
  getByChannel: (channelId) => _filter(_dials, 'accessChannelId', channelId),
  getByGroup: (groupId) => _filter(_dials, 'aggregationGroupId', groupId),
  create: (data) => {
    const item = _normalizeDialInstance({ ...data, id: data.id || genId('di') })
    _dials.value.push(item)
    if (isMockMode()) _addPending('create', 'dial_instance', `添加宽带线路 ${item.name}`)
    return item
  },
  batchCreate: (items) => {
    const created = items.map(data => {
      const item = _normalizeDialInstance({ ...data, id: data.id || genId('di') })
      _dials.value.push(item)
      return item
    })
    if (isMockMode()) _addPending('create', 'dial_instance', `批量添加 ${created.length} 条宽带线路`)
    return created
  },
  update: (id, data) => {
    const idx = _dials.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _dials.value[idx] = _normalizeDialInstance({ ..._dials.value[idx], ...data, id })
      if (isMockMode()) _addPending('update', 'dial_instance', `修改线路 ${_dials.value[idx].name}`)
      return _dials.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_dials, id)
    if (!item) return false
    if (item.aggregationGroupId) {
      const group = _find(_groups, item.aggregationGroupId)
      if (group) {
        throw new Error(`线路 ${item.name} 属于双栈线路汇聚 ${group.name}，请先从汇聚中移除`)
      }
    }
    const ok = _remove(_dials, id)
    if (ok && isMockMode()) _addPending('delete', 'dial_instance', `删除线路 ${item.name}`)
    return ok
  },
  // 统计
  getStats: () => {
    const all = _dials.value
    return {
      total: all.length,
      dualStackOnline: all.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state === 'online').length,
      ipv4Only: all.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state !== 'online').length,
      ipv6NoPd: all.filter(d => d.runtimeStatus?.ipv6?.state === 'online' && !d.runtimeStatus?.ipv6?.hasUsablePd).length,
      offline: all.filter(d => d.runtimeStatus?.pppoeState === 'disconnected').length,
      totalConnections: all.reduce((s, d) => s + (d.runtimeStatus?.activeConnections || 0), 0),
      totalRxMbps: all.reduce((s, d) => s + (d.runtimeStatus?.rxRate || 0), 0).toFixed(1),
      totalTxMbps: all.reduce((s, d) => s + (d.runtimeStatus?.txRate || 0), 0).toFixed(1),
    }
  }
}

// ===== 汇聚组服务 =====
export const aggregationGroupService = {
  list: () => _groups.value,
  get: (id) => _find(_groups, id),
  create: (data) => {
    const item = _normalizeAggregationGroup({ ...data, id: data.id || genId('ag') })
    _groups.value.push(item)
    // 将成员拨号实例的 aggregationGroupId 设为此组
    item.memberDialInstanceIds.forEach(did => {
      const di = _find(_dials, did)
      if (di) di.aggregationGroupId = item.id
    })
    _syncGroupReferences()
    if (isMockMode()) _addPending('create', 'aggregation_group', `新建汇聚组 ${item.name}`)
    return item
  },
  update: (id, data) => {
    const idx = _groups.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      const old = _groups.value[idx]
      const updated = _normalizeAggregationGroup({ ...old, ...data, id })
      _groups.value[idx] = updated
      // 更新成员的 aggregationGroupId
      if (updated.memberDialInstanceIds) {
        // 移除旧成员
        old.memberDialInstanceIds?.forEach(did => {
          if (!updated.memberDialInstanceIds.includes(did)) {
            const di = _find(_dials, did)
            if (di) di.aggregationGroupId = ''
          }
        })
        // 加入新成员
        updated.memberDialInstanceIds.forEach(did => {
          const di = _find(_dials, did)
          if (di) di.aggregationGroupId = id
        })
      }
      _syncGroupReferences()
      if (isMockMode()) _addPending('update', 'aggregation_group', `修改汇聚组 ${updated.name}`)
      return updated
    }
    return null
  },
  remove: (id) => {
    const item = _find(_groups, id)
    if (!item) return false
    // 解绑成员
    item.memberDialInstanceIds?.forEach(did => {
      const di = _find(_dials, did)
      if (di) di.aggregationGroupId = ''
    })
    // 解绑 LAN
    const lan = _lans.value.find(l => l.aggregationGroupId === id)
    if (lan) lan.aggregationGroupId = ''
    const ok = _remove(_groups, id)
    _syncGroupReferences()
    if (ok && isMockMode()) _addPending('delete', 'aggregation_group', `删除汇聚组 ${item.name}`)
    return ok
  },
  getMemberDetails: (groupId) => {
    const group = _find(_groups, groupId)
    if (!group) return []
    return group.memberDialInstanceIds?.map(did => _find(_dials, did)).filter(Boolean) || []
  },
}

// ===== LAN 网络服务 =====
export const lanService = {
  list: () => _lans.value,
  get: (id) => _find(_lans, id),
  create: (data) => {
    const item = { ...data, id: data.id || genId('lan') }
    _lans.value.push(item)
    if (isMockMode()) _addPending('create', 'lan_network', `新建LAN ${item.name}`)
    return item
  },
  update: (id, data) => {
    const idx = _lans.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _lans.value[idx] = { ..._lans.value[idx], ...data }
      if (isMockMode()) _addPending('update', 'lan_network', `修改LAN ${_lans.value[idx].name}`)
      return _lans.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_lans, id)
    if (!item) return false
    if (item.aggregationGroupId) {
      const group = _find(_groups, item.aggregationGroupId)
      if (group) throw new Error(`LAN ${item.name} 已绑定到汇聚组 ${group.name}，请先解绑`)
    }
    const ok = _remove(_lans, id)
    if (ok && isMockMode()) _addPending('delete', 'lan_network', `删除LAN ${item.name}`)
    return ok
  },
}

// ===== 调度策略服务 =====
export const policyService = {
  list: () => _policies.value,
  get: (id) => _find(_policies, id),
  create: (data) => {
    const item = _normalizePolicy({
      ...data,
      id: data.id || genId('sp'),
      referencedByGroups: [],
    })
    _policies.value.push(item)
    if (isMockMode()) _addPending('create', 'scheduling_policy', `新建调度策略 ${item.name}`)
    return item
  },
  update: (id, data) => {
    const idx = _policies.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _policies.value[idx] = _normalizePolicy({ ..._policies.value[idx], ...data, id })
      _syncGroupReferences()
      if (isMockMode()) _addPending('update', 'scheduling_policy', `修改调度策略 ${_policies.value[idx].name}`)
      return _policies.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_policies, id)
    if (!item) return false
    const referencedByGroups = _groups.value.filter(group => group.schedulingPolicyId === id)
    if (referencedByGroups.length > 0) {
      const groupNames = referencedByGroups.map(group => group.name).join(', ')
      throw new Error(`调度策略被以下汇聚组引用：${groupNames}，无法删除`)
    }
    const ok = _remove(_policies, id)
    if (ok && isMockMode()) _addPending('delete', 'scheduling_policy', `删除调度策略 ${item.name}`)
    return ok
  },
}

// ===== 健康检测策略服务 =====
export const healthCheckService = {
  list: () => _healthPolicies.value,
  get: (id) => _find(_healthPolicies, id),
  create: (data) => {
    const item = _normalizeHealthPolicy({
      ...data,
      id: data.id || genId('hcp'),
      referencedByGroups: [],
    })
    _healthPolicies.value.push(item)
    if (isMockMode()) _addPending('create', 'health_policy', `新建健康检测策略 ${item.name}`)
    return item
  },
  update: (id, data) => {
    const idx = _healthPolicies.value.findIndex(i => i.id === id)
    if (idx >= 0) {
      _healthPolicies.value[idx] = _normalizeHealthPolicy({
        ..._healthPolicies.value[idx],
        ...data,
        id,
      })
      _syncGroupReferences()
      if (isMockMode()) _addPending('update', 'health_policy', `修改健康检测策略 ${_healthPolicies.value[idx].name}`)
      return _healthPolicies.value[idx]
    }
    return null
  },
  remove: (id) => {
    const item = _find(_healthPolicies, id)
    if (!item) return false
    if (_groups.value.some(group => group.healthCheckPolicyId === id)) {
      throw new Error(`健康检测策略仍被汇聚组引用，无法删除`)
    }
    const ok = _remove(_healthPolicies, id)
    if (ok && isMockMode()) _addPending('delete', 'health_policy', `删除健康检测策略 ${item.name}`)
    return ok
  },
}

// ===== IPv6 前缀映射服务 =====
export const ipv6PrefixService = {
  list: () => _prefixMappings.value,
  get: (id) => _find(_prefixMappings, id),
  getByDialInstance: (diId) => _filter(_prefixMappings, 'dialInstanceId', diId),
  getByGroup: (groupId) => _filter(_prefixMappings, 'aggregationGroupId', groupId),
}

// ===== 运行时状态服务 =====
export const runtimeStatusService = {
  getDialInstanceStatus: (diId) => {
    const di = _find(_dials, diId)
    return di?.runtimeStatus || null
  },
  getGroupStatus: (groupId) => {
    const group = _find(_groups, groupId)
    if (!group) return null
    const members = (group.memberDialInstanceIds || []).map(did => _find(_dials, did)).filter(Boolean)
    return {
      ipv4OnlineMembers: members.filter(d => d.runtimeStatus?.ipv4?.state === 'online').length,
      ipv6OnlineMembers: members.filter(d => d.runtimeStatus?.ipv6?.state === 'online').length,
      membersWithPd: members.filter(d => d.runtimeStatus?.ipv6?.hasUsablePd).length,
      nptv6Count: _filter(_prefixMappings, 'aggregationGroupId', groupId).filter(pm => pm.translationMode === 'nptv6').length,
      nat66FallbackCount: _filter(_prefixMappings, 'aggregationGroupId', groupId).filter(pm => pm.translationMode === 'nat66_fallback').length,
      currentIpv4Connections: members.reduce((s, d) => s + (d.runtimeStatus?.activeConnections || 0), 0),
      currentIpv6Connections: Math.round(members.reduce((s, d) => s + (d.runtimeStatus?.activeConnections || 0), 0) * 0.3),
      totalRxMbps: members.reduce((s, d) => s + (d.runtimeStatus?.rxRate || 0), 0).toFixed(1),
      totalTxMbps: members.reduce((s, d) => s + (d.runtimeStatus?.txRate || 0), 0).toFixed(1),
      failedMembers: members.filter(d => d.runtimeStatus?.pppoeState !== 'connected').length,
      totalMembers: members.length,
    }
  },
  getRecentDisconnects: () => mockRecentDisconnects,
}

// ===== 配置应用服务 =====
export const configurationApplyService = {
  getPendingChanges: () => _pendingChanges.value,
  getPendingCount: () => _pendingChanges.value.length,
  clearPending: () => { _pendingChanges.value = [] },
  discard: (id) => _remove(_pendingChanges, id),
  applyOne: (id) => {
    const item = _find(_pendingChanges, id)
    if (!item) return { success: false, message: '待应用项不存在' }
    _remove(_pendingChanges, id)
    return { success: true, appliedCount: 1, message: `已应用：${item.description}` }
  },
  applyAll: () => {
    // Mock 模式：模拟应用成功
    if (isMockMode()) {
      const count = _pendingChanges.value.length
      _pendingChanges.value = []
      return { success: true, appliedCount: count, message: `已应用 ${count} 项配置变更（演示模式）` }
    }
    // 真实模式：后端接口待接入
    return { success: false, appliedCount: 0, message: '后端接口待接入：configurationApplyService.applyAll() 需要对接 OpenWrt ubus/UCI 接口' }
  },
  rollback: () => {
    if (isMockMode()) {
      _pendingChanges.value = []
      return { success: true, message: '已回滚配置变更（演示模式）' }
    }
    return { success: false, message: '后端接口待接入：rollback 需要对接 OpenWrt 配置快照恢复接口' }
  },
}

// ===== 重置所有 Mock 数据 =====
export function resetAllMockData() {
  _ports.value = JSON.parse(JSON.stringify(mockPhysicalPorts))
  _channels.value = JSON.parse(JSON.stringify(mockAccessChannels)).map(_normalizeAccessChannel)
  _dials.value = JSON.parse(JSON.stringify(mockDialInstances)).map(_normalizeDialInstance)
  _groups.value = JSON.parse(JSON.stringify(mockAggregationGroups)).map(_normalizeAggregationGroup)
  _lans.value = JSON.parse(JSON.stringify(mockLanNetworks))
  _policies.value = JSON.parse(JSON.stringify(mockSchedulingPolicies)).map(_normalizePolicy)
  _healthPolicies.value = JSON.parse(JSON.stringify(mockHealthCheckPolicies)).map(_normalizeHealthPolicy)
  _prefixMappings.value = JSON.parse(JSON.stringify(mockPrefixMappings))
  _pendingChanges.value = []
  _syncGroupReferences()
}

// ===== 物理端口硬件发现服务 =====
export const physicalPortDiscoveryService = {
  // 真实硬件驱动清单（Mock 模式模拟）
  _hardwareRegistry: {
    eth0: { name: 'eth0', macAddress: 'AA:BB:CC:DD:EE:01', driver: 'e1000e', pciAddress: '0000:00:1f.6', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
    eth1: { name: 'eth1', macAddress: 'AA:BB:CC:DD:EE:02', driver: 'ixgbe', pciAddress: '0000:01:00.0', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
    eth2: { name: 'eth2', macAddress: 'AA:BB:CC:DD:EE:03', driver: 'ixgbe', pciAddress: '0000:02:00.0', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
    eth3: { name: 'eth3', macAddress: 'AA:BB:CC:DD:EE:04', driver: 'ixgbe', pciAddress: '0000:03:00.0', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
    eth4: { name: 'eth4', macAddress: 'AA:BB:CC:DD:EE:05', driver: 'r8169', pciAddress: '0000:04:00.0', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
    eth5: { name: 'eth5', macAddress: 'AA:BB:CC:DD:EE:06', driver: 'r8169', pciAddress: '0000:05:00.0', isPhysical: true, isVlan: false, isBridge: false, isBond: false, isVirtual: false },
  },

  /**
   * 扫描系统物理网络设备
   * Mock模式：返回硬件清单
   * 真实模式：返回"后端接口待接入"
   */
  async discoverPhysicalPorts() {
    if (isMockMode()) {
      // 模拟扫描延迟
      await new Promise(r => setTimeout(r, 600))
      const liveStates = {
        eth0: { linkState: 'up', speedMbps: 1000, duplex: 'full', mtu: 1500, rxBytes: 12850000000, txBytes: 3520000000, rxErrors: 0, txErrors: 0 },
        eth1: { linkState: 'up', speedMbps: 10000, duplex: 'full', mtu: 1500, rxBytes: 96300000000, txBytes: 22100000000, rxErrors: 2, txErrors: 0 },
        eth2: { linkState: 'up', speedMbps: 10000, duplex: 'full', mtu: 1500, rxBytes: 85100000000, txBytes: 18700000000, rxErrors: 5, txErrors: 1 },
        eth3: { linkState: 'down', speedMbps: null, duplex: null, mtu: 1500, rxBytes: 0, txBytes: 0, rxErrors: 0, txErrors: 0 },
        eth4: { linkState: 'down', speedMbps: null, duplex: null, mtu: 1500, rxBytes: 0, txBytes: 0, rxErrors: 0, txErrors: 0 },
        eth5: { linkState: 'down', speedMbps: null, duplex: null, mtu: 1500, rxBytes: 0, txBytes: 0, rxErrors: 0, txErrors: 0 },
      }
      const result = []
      for (const [name, hw] of Object.entries(this._hardwareRegistry)) {
        const live = liveStates[name] || {}
        result.push({
          ...hw,
          ...live,
          source: 'mock',
        })
      }
      return { success: true, ports: result, count: result.length, source: 'Mock模拟' }
    }
    // 真实模式：后端接口待接入
    return { success: false, ports: [], count: 0, source: '后端接口待接入', error: 'OpenWrt ubus/ethtool 适配层未实现' }
  },

  /**
   * 刷新物理端口状态并与已有配置合并
   */
  async refreshPhysicalPorts() {
    const discovery = await this.discoverPhysicalPorts()
    if (!discovery.success) return discovery

    // 合并已有角色配置
    const existingPorts = physicalPortService.list()
    const merged = discovery.ports.map(dp => {
      const existing = existingPorts.find(p => p.name === dp.name)
      if (existing) {
        // 保留用户角色配置，更新硬件状态
        return {
          id: existing.id,
          ...dp,
          role: existing.role || 'unassigned',
          accessMode: existing.accessMode || 'none',
          allowedVlans: existing.allowedVlans || [],
          lanNetworkId: existing.lanNetworkId || '',
          source: 'mock',
        }
      }
      return { id: genId('port'), ...dp, role: 'unassigned', accessMode: 'none', allowedVlans: [], lanNetworkId: '', source: 'mock' }
    })

    // 更新持久化数据
    _ports.value = merged
    return { success: true, ports: merged, count: merged.length, source: 'Mock模拟', refreshed: true }
  },

  /**
   * 获取单个设备详细信息
   */
  getPhysicalPortDetails(deviceName) {
    const hw = this._hardwareRegistry[deviceName]
    if (hw) {
      return {
        ...hw,
        source: isMockMode() ? 'Mock模拟' : '系统检测',
      }
    }
    return null
  },
}
