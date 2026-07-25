<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>物理网口</h2>
      <p>查看设备网口的连接状态、用途和当前承载的宽带线路</p>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never" class="section-card">
        <div class="card-header-actions">
          <div class="header-left">
            <span class="header-title">网口列表</span>
            <span class="header-count">共 {{ physicalPorts.length }} 个</span>
          </div>
          <div class="header-right">
            <el-button @click="refreshHardware" :loading="scanning">
              <el-icon><Refresh /></el-icon>
              刷新端口状态
            </el-button>
            <el-button v-if="unassignedCount > 0" @click="manageUnassigned">
              查看未使用网口
            </el-button>
          </div>
        </div>

        <el-alert v-if="scanning" type="info" :closable="false">
          正在刷新网口连接状态，请稍候……
        </el-alert>

        <el-alert
          v-else-if="lastSource === 'Mock模拟'"
          type="info"
          :closable="false"
          class="source-alert"
          title="演示模式：当前网口状态用于界面预览，不代表真实设备状态。"
        />

        <StandardTable layout-mode="fill" :data="physicalPorts" border stripe size="default">
          <el-table-column label="端口" min-width="105" show-overflow-tooltip>
            <template #default="{ row }">
              <div class="port-cell">
                <span class="port-name">{{ row.alias || row.name }}</span>
                <span v-if="row.alias" class="port-device-name">{{ row.name }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="连接状态" min-width="105">
            <template #default="{ row }">
              <span class="status-tag">
                <span :class="['status-dot', row.linkState === 'up' ? 'online' : 'offline']"></span>
                {{ row.linkState === 'up' ? '已连接' : '未连接' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="协商速率" min-width="105">
            <template #default="{ row }">{{ formatSpeed(row.speedMbps) }}</template>
          </el-table-column>
          <el-table-column label="端口用途" min-width="115">
            <template #default="{ row }">
              <el-tag :type="purposeTagType(row)" size="small">{{ purposeLabel(row) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="绑定线路数量" min-width="120" align="center">
            <template #default="{ row }">{{ boundLineCount(row) }}</template>
          </el-table-column>
          <el-table-column label="实时 RX/TX" min-width="180">
            <template #default="{ row }">
              <span class="traffic-rate">{{ portTraffic(row) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="165" align="center">
            <template #default="{ row }">
              <div class="row-actions">
                <el-button size="small" type="primary" link @click="openDetails(row)">端口详情</el-button>
                <el-button size="small" link @click="openConfig(row)">设置</el-button>
              </div>
            </template>
          </el-table-column>
        </StandardTable>
      </SectionCard>
    </SectionCard>

    <StandardDrawer
      v-model="detailDrawer"
      :title="selectedPort ? `端口详情 — ${selectedPort.alias || selectedPort.name}` : '端口详情'"
      size="large"
      destroy-on-close
    >
      <template v-if="selectedPort">
        <div class="detail-summary">
          <div>
            <div class="detail-port-name">{{ selectedPort.alias || selectedPort.name }}</div>
            <div v-if="selectedPort.alias" class="detail-device-name">端口编号：{{ selectedPort.name }}</div>
          </div>
          <div class="detail-tags">
            <el-tag :type="selectedPort.linkState === 'up' ? 'success' : 'info'">
              {{ selectedPort.linkState === 'up' ? '已连接' : '未连接' }}
            </el-tag>
            <el-tag :type="purposeTagType(selectedPort)">{{ purposeLabel(selectedPort) }}</el-tag>
          </div>
        </div>

        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="MAC 地址">{{ selectedPort.macAddress || '—' }}</el-descriptions-item>
          <el-descriptions-item label="驱动">{{ selectedPort.driver || '—' }}</el-descriptions-item>
          <el-descriptions-item label="PCI 地址">{{ selectedPort.pciAddress || '—' }}</el-descriptions-item>
          <el-descriptions-item label="双工">{{ duplexLabel(selectedPort.duplex) }}</el-descriptions-item>
          <el-descriptions-item label="MTU">{{ selectedPort.mtu || '—' }}</el-descriptions-item>
          <el-descriptions-item label="接入模式">{{ accessModeLabel(selectedPort.accessMode) }}</el-descriptions-item>
          <el-descriptions-item label="允许 VLAN">
            {{ selectedPort.allowedVlans?.length ? selectedPort.allowedVlans.join(', ') : '未设置' }}
          </el-descriptions-item>
          <el-descriptions-item label="所属局域网">{{ portLanName(selectedPort) }}</el-descriptions-item>
          <el-descriptions-item label="接入通道">
            {{ channelNames(selectedPort.id) || '无' }}
          </el-descriptions-item>
          <el-descriptions-item label="线路">
            {{ dialNames(selectedPort.id) || '无' }}
          </el-descriptions-item>
        </el-descriptions>

        <div class="technical-toggle">
          <el-button plain @click="showTechnical = !showTechnical">
            <el-icon><View /></el-icon>
            {{ showTechnical ? '收起技术详情' : '查看技术详情' }}
          </el-button>
          <span>供安装和运维工程师排查网口问题</span>
        </div>

        <el-collapse-transition>
          <div v-if="showTechnical" class="technical-panel">
            <el-alert
              type="warning"
              :closable="false"
              title="以下为底层识别和累计计数信息，普通配置无需修改。"
            />
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="系统识别名称">{{ selectedPort.name }}</el-descriptions-item>
              <el-descriptions-item label="数据来源">{{ sourceLabel(selectedPort.source) }}</el-descriptions-item>
              <el-descriptions-item label="物理设备">{{ selectedPort.isPhysical === false ? '否' : '是' }}</el-descriptions-item>
              <el-descriptions-item label="虚拟设备">{{ selectedPort.isVirtual ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="VLAN 设备">{{ selectedPort.isVlan ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="网桥设备">{{ selectedPort.isBridge ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="聚合设备">{{ selectedPort.isBond ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="接收累计">{{ formatBytes(selectedPort.rxBytes) }}</el-descriptions-item>
              <el-descriptions-item label="发送累计">{{ formatBytes(selectedPort.txBytes) }}</el-descriptions-item>
              <el-descriptions-item label="接收错误">{{ selectedPort.rxErrors || 0 }}</el-descriptions-item>
              <el-descriptions-item label="发送错误">{{ selectedPort.txErrors || 0 }}</el-descriptions-item>
            </el-descriptions>
            <div class="raw-data-title">原始端口数据</div>
            <pre class="raw-data">{{ technicalJson(selectedPort) }}</pre>
          </div>
        </el-collapse-transition>
      </template>

      <template #footer>
        <el-button @click="detailDrawer = false">关闭</el-button>
        <el-button type="primary" @click="openConfigFromDetails">设置端口</el-button>
      </template>
    </StandardDrawer>

    <StandardModal
      v-model="configDialog"
      :title="'设置端口 — ' + configForm.name"
      size="standard"
      @submit="saveConfig"
    >
      <el-alert type="info" :closable="false">
        设置端口用途和业务参数不会改变系统自动识别的硬件信息。
      </el-alert>

      <el-form :model="configForm" label-width="120px" class="config-form">
        <el-form-item label="端口别名">
          <el-input v-model="configForm.alias" placeholder="例如：电信宽带入口" />
        </el-form-item>

        <el-form-item label="端口用途" required>
          <template v-if="isServerOutput(configForm.id)">
            <el-input model-value="服务器出口" disabled />
            <div class="form-hint">该用途由“双栈线路汇聚”的服务器出口绑定决定。</div>
          </template>
          <el-select v-else v-model="configForm.role" @change="onRoleChange">
            <el-option label="管理口" value="mgmt" />
            <el-option label="宽带入口" value="wan" />
            <el-option label="普通 LAN" value="lan" />
            <el-option label="未使用" value="unassigned" />
          </el-select>
        </el-form-item>

        <template v-if="configForm.role === 'wan'">
          <el-form-item label="宽带接入方式">
            <el-select v-model="configForm.accessMode">
              <el-option label="单线路接入" value="access" />
              <el-option label="多 VLAN 接入" value="trunk" />
              <el-option label="混合接入" value="hybrid" />
              <el-option label="无标签接入" value="untagged" />
            </el-select>
          </el-form-item>
          <el-form-item label="运营商 VLAN">
            <el-input v-model="configForm.allowedVlansStr" placeholder="多个编号用逗号分隔，例如 101,103,105" />
          </el-form-item>
        </template>

        <template v-if="configForm.role === 'lan' && !isServerOutput(configForm.id)">
          <el-form-item label="所属局域网">
            <el-select v-model="configForm.lanNetworkId" clearable placeholder="暂不绑定">
              <el-option v-for="lan in lans" :key="lan.id" :label="lan.name" :value="lan.id" />
            </el-select>
          </el-form-item>
        </template>

        <el-form-item v-if="configForm.role !== 'unassigned'" label="最大传输单元">
          <el-input-number v-model="configForm.mtu" :min="576" :max="9000" />
          <div class="form-hint">保持默认值即可；仅在运营商或内网环境有明确要求时调整。</div>
        </el-form-item>

        <EmptyState
          v-if="configForm.role === 'unassigned'"
          description="该网口当前不参与宽带或局域网业务"
          :image-size="60"
        />
      </el-form>
    </StandardModal>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  physicalPortService,
  lanService,
  physicalPortDiscoveryService,
  accessChannelService,
  dialInstanceService,
  aggregationGroupService,
} from '../../services/dataService.js'

const validPortNames = ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5']

onMounted(() => {
  try {
    const raw = localStorage.getItem('linehub:svc:physicalPorts')
    if (!raw) return
    const parsed = JSON.parse(raw)
    const cleaned = parsed.filter(port => validPortNames.includes(port.name))
    if (cleaned.length !== parsed.length) {
      localStorage.setItem('linehub:svc:physicalPorts', JSON.stringify(cleaned))
      location.reload()
    }
  } catch {
    // 持久化数据异常时继续使用服务层默认数据。
  }
})

const physicalPorts = ref(physicalPortService.list().filter(port => validPortNames.includes(port.name)))
const lans = ref(lanService.list())
const channels = ref(accessChannelService.list())
const dialInstances = ref(dialInstanceService.list())
const aggregationGroups = ref(aggregationGroupService.list())
const scanning = ref(false)
const lastSource = ref('Mock模拟')

const unassignedCount = computed(() =>
  physicalPorts.value.filter(port => purposeKey(port) === 'unused').length
)

function serverGroupForPort(portId) {
  return aggregationGroups.value.find(group => group.lanPhysicalPortId === portId)
}

function isServerOutput(portId) {
  return Boolean(serverGroupForPort(portId))
}

function purposeKey(port) {
  if (isServerOutput(port.id)) return 'server'
  return {
    mgmt: 'management',
    wan: 'broadband',
    lan: 'lan',
    unassigned: 'unused',
  }[port.role] || 'unused'
}

function purposeLabel(port) {
  return {
    management: '管理口',
    broadband: '宽带入口',
    server: '服务器出口',
    lan: '普通 LAN',
    unused: '未使用',
  }[purposeKey(port)]
}

function purposeTagType(port) {
  return {
    management: 'warning',
    broadband: 'primary',
    server: 'success',
    lan: '',
    unused: 'info',
  }[purposeKey(port)]
}

function formatSpeed(speedMbps) {
  const value = Number(speedMbps) || 0
  if (!value) return '—'
  if (value >= 1000) return `${value / 1000} Gbps`
  return `${value} Mbps`
}

function duplexLabel(duplex) {
  return { full: '全双工', half: '半双工' }[duplex] || '—'
}

function accessModeLabel(mode) {
  return {
    access: '单线路接入',
    trunk: '多 VLAN 接入',
    hybrid: '混合接入',
    untagged: '无标签接入',
    none: '未设置',
  }[mode] || '未设置'
}

function channelsForPort(portId) {
  return channels.value.filter(channel => channel.physicalPortId === portId)
}

function directDialsForPort(portId) {
  const channelIds = new Set(channelsForPort(portId).map(channel => channel.id))
  return dialInstances.value.filter(instance => channelIds.has(instance.accessChannelId))
}

function boundDialsForPort(port) {
  const direct = directDialsForPort(port.id)
  const serverGroup = serverGroupForPort(port.id)
  const groupMembers = serverGroup
    ? dialInstances.value.filter(instance => serverGroup.memberDialInstanceIds?.includes(instance.id))
    : []
  return [...new Map([...direct, ...groupMembers].map(instance => [instance.id, instance])).values()]
}

function boundLineCount(port) {
  return boundDialsForPort(port).length
}

function portTraffic(port) {
  const totals = boundDialsForPort(port).reduce((sum, instance) => {
    sum.rx += Number(instance.runtimeStatus?.rxRate) || 0
    sum.tx += Number(instance.runtimeStatus?.txRate) || 0
    return sum
  }, { rx: 0, tx: 0 })

  if (!totals.rx && !totals.tx) return '—'
  return `↓ ${totals.rx.toFixed(1)} / ↑ ${totals.tx.toFixed(1)} Mbps`
}

function portLanName(port) {
  const lanId = port.lanNetworkId || serverGroupForPort(port.id)?.lanNetworkId
  return lanId ? lanService.get(lanId)?.name || '—' : '未绑定'
}

function channelNames(portId) {
  return channelsForPort(portId).map(channel => channel.name).join('、')
}

function dialNames(portId) {
  return directDialsForPort(portId).map(instance => instance.name).join('、')
}

function formatBytes(bytes) {
  const value = Number(bytes) || 0
  if (value >= 1024 ** 3) return `${(value / 1024 ** 3).toFixed(2)} GB`
  if (value >= 1024 ** 2) return `${(value / 1024 ** 2).toFixed(1)} MB`
  if (value >= 1024) return `${(value / 1024).toFixed(1)} KB`
  return `${value} B`
}

function sourceLabel(source) {
  return source === 'mock' || !source ? '演示数据' : '设备采集'
}

function technicalJson(port) {
  return JSON.stringify(port, null, 2)
}

async function refreshHardware() {
  scanning.value = true
  try {
    const result = await physicalPortDiscoveryService.refreshPhysicalPorts()
    if (result.success) {
      physicalPorts.value = result.ports.filter(port => validPortNames.includes(port.name))
      lastSource.value = result.source
      ElMessage.success(`端口状态已刷新，共发现 ${result.count} 个网口`)
    } else {
      ElMessage.warning(result.error || '暂时无法刷新端口状态')
    }
  } catch (error) {
    ElMessage.error('刷新端口状态失败：' + error.message)
  } finally {
    scanning.value = false
  }
}

function manageUnassigned() {
  ElMessage.info(`当前有 ${unassignedCount.value} 个未使用网口，可通过“设置”分配用途`)
}

const detailDrawer = ref(false)
const selectedPort = ref(null)
const showTechnical = ref(false)

function openDetails(row) {
  selectedPort.value = row
  showTechnical.value = false
  detailDrawer.value = true
}

function openConfigFromDetails() {
  if (!selectedPort.value) return
  const port = selectedPort.value
  detailDrawer.value = false
  openConfig(port)
}

const configDialog = ref(false)
const configForm = reactive({
  id: '',
  name: '',
  macAddress: '',
  driver: '',
  pciAddress: '',
  linkState: '',
  speedMbps: null,
  duplex: '',
  mtu: 1500,
  isPhysical: true,
  role: 'unassigned',
  accessMode: 'none',
  allowedVlans: [],
  allowedVlansStr: '',
  lanNetworkId: '',
  alias: '',
})

function openConfig(row) {
  Object.assign(configForm, {
    id: row.id,
    name: row.name,
    macAddress: row.macAddress,
    driver: row.driver,
    pciAddress: row.pciAddress,
    linkState: row.linkState,
    speedMbps: row.speedMbps,
    duplex: row.duplex,
    mtu: row.mtu,
    isPhysical: row.isPhysical !== false,
    role: row.role || 'unassigned',
    accessMode: row.accessMode || 'none',
    allowedVlans: row.allowedVlans || [],
    allowedVlansStr: (row.allowedVlans || []).join(','),
    lanNetworkId: row.lanNetworkId || '',
    alias: row.alias || '',
  })
  configDialog.value = true
}

function onRoleChange() {
  if (configForm.role !== 'wan') {
    configForm.accessMode = 'none'
    configForm.allowedVlansStr = ''
  }
  if (configForm.role !== 'lan') configForm.lanNetworkId = ''
}

function saveConfig() {
  const vlans = configForm.allowedVlansStr
    ? configForm.allowedVlansStr
      .split(',')
      .map(value => Number.parseInt(value.trim(), 10))
      .filter(value => Number.isInteger(value) && value >= 1 && value <= 4094)
    : []

  physicalPortService.update(configForm.id, {
    alias: configForm.alias,
    role: configForm.role,
    accessMode: configForm.accessMode,
    allowedVlans: vlans,
    mtu: configForm.mtu,
    lanNetworkId: configForm.lanNetworkId,
  })
  physicalPorts.value = physicalPortService.list().filter(port => validPortNames.includes(port.name))
  ElMessage.success(`端口 ${configForm.name} 设置已更新`)
  configDialog.value = false
}
</script>

<style scoped>
.section-card {
  margin-bottom: 16px;
}

.card-header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.header-left,
.header-right,
.detail-summary,
.detail-tags,
.row-actions {
  display: flex;
  align-items: center;
}

.header-left {
  gap: 8px;
}

.header-right,
.detail-tags {
  gap: 8px;
}

.header-title {
  font-size: 15px;
  font-weight: 600;
}

.header-count,
.port-device-name,
.detail-device-name,
.technical-toggle span,
.form-hint {
  color: var(--lh-text-secondary);
  font-size: 12px;
}

.source-alert {
  margin-bottom: 16px;
}

.port-cell {
  display: flex;
  min-width: 0;
  flex-direction: column;
  line-height: 1.35;
}

.port-name {
  overflow: hidden;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.traffic-rate,
.row-actions {
  white-space: nowrap;
}

.detail-summary {
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 18px;
}

.detail-port-name {
  font-size: 18px;
  font-weight: 600;
}

.technical-toggle {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 20px;
}

.technical-panel {
  margin-top: 16px;
}

.technical-panel .el-alert {
  margin-bottom: 12px;
}

.raw-data-title {
  margin: 16px 0 8px;
  font-size: 13px;
  font-weight: 600;
}

.raw-data {
  max-height: 280px;
  margin: 0;
  padding: 12px;
  overflow: auto;
  border-radius: 6px;
  background: var(--el-fill-color-lighter);
  color: var(--el-text-color-regular);
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.55;
  white-space: pre-wrap;
  word-break: break-all;
}

.config-form {
  margin-top: 18px;
}

.form-hint {
  width: 100%;
  margin-top: 4px;
  line-height: 1.5;
}

@media (max-width: 767px) {
  .card-header-actions,
  .detail-summary,
  .technical-toggle {
    align-items: flex-start;
    flex-direction: column;
  }

  .header-right {
    flex-wrap: wrap;
  }
}
</style>
