<template>
  <PageContainer>
    <PageHeader
      title="宽带线路"
      description="添加和管理运营商宽带线路。每个宽带账号会自动生成一条可参与IPv4、IPv6汇聚和智能调度的线路。"
    />

    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
        <CardToolbar class="toolbar">
          <el-button type="primary" @click="openCreate">+ 添加宽带</el-button>
          <el-button @click="loadData">刷新</el-button>
        </CardToolbar>

        <StandardTable
          layout-mode="scroll"
          class="line-table"
          :data="list"
          v-loading="loading"
          size="default"
          border
          stripe
        >
          <el-table-column prop="name" label="线路名称" width="145" fixed="left" />
          <el-table-column prop="carrier" label="运营商" width="110" />
          <el-table-column label="接入口" width="105">
            <template #default="{ row }">{{ getAccessPort(row.accessChannelId) }}</template>
          </el-table-column>
          <el-table-column label="VLAN" width="80">
            <template #default="{ row }">{{ getVlanId(row.accessChannelId) }}</template>
          </el-table-column>
          <el-table-column label="账号" width="175" show-overflow-tooltip>
            <template #default="{ row }">{{ row.maskedUsername }}</template>
          </el-table-column>
          <el-table-column label="IPv4状态" width="105">
            <template #default="{ row }">
              <el-tag :type="protocolTagType(row.ipv4LineStatus)" size="small">
                {{ protocolStatusText(row.ipv4LineStatus) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="IPv6状态" width="105">
            <template #default="{ row }">
              <el-tag :type="protocolTagType(row.ipv6LineStatus)" size="small">
                {{ protocolStatusText(row.ipv6LineStatus) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="配置上行带宽" width="125" align="right">
            <template #default="{ row }">{{ row.configuredUploadMbps }} Mbps</template>
          </el-table-column>
          <el-table-column label="实时上传" width="105" align="right">
            <template #default="{ row }">{{ row.currentUploadMbps.toFixed(1) }} Mbps</template>
          </el-table-column>
          <el-table-column label="当前利用率" width="145">
            <template #default="{ row }">
              <el-progress
                :percentage="Math.min(100, row.uploadUtilizationPercent)"
                :stroke-width="8"
                :status="row.uploadUtilizationPercent >= 93 ? 'warning' : undefined"
              />
            </template>
          </el-table-column>
          <el-table-column label="线路质量" width="100">
            <template #default="{ row }">
              <el-tag :type="qualityTagType(row.lineQuality)" size="small">{{ row.lineQuality }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="当前权重" width="95" align="center">
            <template #default="{ row }">{{ row.runtimeStatus?.currentWeight || 0 }}</template>
          </el-table-column>
          <el-table-column label="操作" width="185" fixed="right" align="center">
            <template #default="{ row }">
              <div class="row-actions">
                <el-button link type="primary" @click="openDetails(row)">详情</el-button>
                <el-button link @click="openEdit(row)">编辑</el-button>
                <el-button link type="danger" @click="removeItem(row)">删除</el-button>
              </div>
            </template>
          </el-table-column>
        </StandardTable>
      </SectionCard>
    </SectionCard>

    <StandardDrawer
      v-model="detailDrawer"
      :title="selectedLine ? `线路详情 — ${selectedLine.name}` : '线路详情'"
      size="large"
      destroy-on-close
    >
      <template v-if="selectedLine">
        <div class="detail-summary">
          <div>
            <div class="detail-title">{{ selectedLine.name }}</div>
            <div class="detail-subtitle">{{ selectedLine.carrier }} · {{ selectedLine.maskedUsername }}</div>
          </div>
          <div class="detail-tags">
            <el-tag :type="protocolTagType(selectedLine.ipv4LineStatus)">
              IPv4 {{ protocolStatusText(selectedLine.ipv4LineStatus) }}
            </el-tag>
            <el-tag :type="protocolTagType(selectedLine.ipv6LineStatus)">
              IPv6 {{ protocolStatusText(selectedLine.ipv6LineStatus) }}
            </el-tag>
          </div>
        </div>

        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="接入通道">
            {{ getChannelName(selectedLine.accessChannelId) }}
          </el-descriptions-item>
          <el-descriptions-item label="技术接口名称">
            {{ getTechnicalInterface(selectedLine.accessChannelId) }}
          </el-descriptions-item>
          <el-descriptions-item label="MAC 模式">
            {{ macModeText(selectedLine.macMode) }}
          </el-descriptions-item>
          <el-descriptions-item label="MTU">{{ selectedLine.mtu || '—' }}</el-descriptions-item>
          <el-descriptions-item label="IPv4 地址">
            {{ selectedLine.runtimeStatus?.ipv4?.address || '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="IPv4 DNS">
            {{ selectedLine.runtimeStatus?.ipv4?.dnsServers?.join(', ') || '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="IPv6 地址">
            {{ selectedLine.runtimeStatus?.ipv6?.globalAddresses?.join(', ') || '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="IPv6 DNS">
            {{ selectedLine.runtimeStatus?.ipv6?.dnsServers?.join(', ') || '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="IPv6-PD">
            {{ formatPd(selectedLine) }}
          </el-descriptions-item>
          <el-descriptions-item label="在线时间">
            {{ selectedLine.runtimeStatus?.uptime || '—' }}
          </el-descriptions-item>
        </el-descriptions>

        <div class="detail-section-title">线路能力与实时状态</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="配置上行带宽">
            {{ selectedLine.configuredUploadMbps }} Mbps
          </el-descriptions-item>
          <el-descriptions-item label="实时上传">
            {{ selectedLine.currentUploadMbps.toFixed(1) }} Mbps
          </el-descriptions-item>
          <el-descriptions-item label="当前利用率">
            {{ selectedLine.uploadUtilizationPercent.toFixed(1) }}%
          </el-descriptions-item>
          <el-descriptions-item label="线路质量">{{ selectedLine.lineQuality }}</el-descriptions-item>
          <el-descriptions-item label="当前权重">
            {{ selectedLine.runtimeStatus?.currentWeight || 0 }}
          </el-descriptions-item>
          <el-descriptions-item label="活动连接">
            {{ selectedLine.runtimeStatus?.activeConnections || 0 }}
          </el-descriptions-item>
        </el-descriptions>
      </template>

      <template #footer>
        <el-button @click="detailDrawer = false">关闭</el-button>
        <el-button type="primary" @click="editSelectedLine">编辑线路</el-button>
      </template>
    </StandardDrawer>

    <StandardModal
      v-model="dialogVisible"
      size="standard"
      :title="isEdit ? '编辑线路' : '添加宽带'"
    >
      <el-form :model="form" label-width="160px" label-position="right">
        <el-divider content-position="left">基础设置</el-divider>
        <el-form-item label="线路名称" required>
          <el-input v-model="form.name" placeholder="例如：电信宽带-01" />
        </el-form-item>
        <el-form-item label="运营商" required>
          <el-select v-model="form.carrier">
            <el-option label="中国电信" value="中国电信" />
            <el-option label="中国联通" value="中国联通" />
            <el-option label="中国移动" value="中国移动" />
            <el-option label="中国广电" value="中国广电" />
            <el-option label="其他运营商" value="其他运营商" />
          </el-select>
        </el-form-item>
        <el-form-item label="接入通道" required>
          <el-select v-model="form.channelId" placeholder="选择接入通道">
            <el-option
              v-for="channel in channels"
              :key="channel.id"
              :label="`${getAccessPort(channel.id)} / VLAN ${getVlanId(channel.id)}`"
              :value="channel.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="宽带账号" required>
          <el-input v-model="form.account" placeholder="运营商提供的账号" />
        </el-form-item>
        <el-form-item label="宽带密码" required>
          <el-input
            v-model="form.password"
            type="password"
            show-password
            placeholder="编辑时留空表示保持现有密码"
          />
        </el-form-item>
        <el-form-item label="配置上行带宽" required>
          <el-input-number v-model="form.configuredUploadMbps" :min="1" :max="100000" />
          <span class="unit">Mbps</span>
        </el-form-item>
        <el-form-item label="服务名">
          <el-input v-model="form.serviceName" placeholder="通常无需填写" />
        </el-form-item>
        <el-form-item label="AC 名称">
          <el-input v-model="form.acName" placeholder="通常无需填写" />
        </el-form-item>
        <el-form-item label="MTU">
          <el-input-number v-model="form.mtu" :min="1280" :max="1500" controls-position="right" />
        </el-form-item>
        <el-form-item label="MRU">
          <el-input-number v-model="form.mru" :min="1280" :max="1500" controls-position="right" />
        </el-form-item>
        <el-form-item label="开机自动连接">
          <el-switch v-model="form.autoDial" />
        </el-form-item>
        <el-form-item label="断线自动重连">
          <el-switch v-model="form.autoRedial" />
        </el-form-item>
        <el-form-item label="重连间隔(秒)">
          <el-input-number v-model="form.redialInterval" :min="1" :max="3600" controls-position="right" />
        </el-form-item>

        <el-divider content-position="left">MAC 设置</el-divider>
        <el-form-item label="MAC 模式">
          <el-radio-group v-model="form.macMode">
            <el-radio value="shared">共用通道 MAC</el-radio>
            <el-radio value="auto">自动生成独立 MAC</el-radio>
            <el-radio value="manual">手动指定 MAC</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.macMode === 'manual'" label="手动 MAC">
          <el-input v-model="form.mac" placeholder="例如 00:11:22:33:44:55" />
        </el-form-item>

        <el-divider content-position="left">线路标识</el-divider>
        <el-form-item label="Host-Uniq 模式">
          <el-radio-group v-model="form.hostUniqMode">
            <el-radio value="auto">自动</el-radio>
            <el-radio value="manual">手动</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.hostUniqMode === 'manual'" label="手动 Host-Uniq">
          <el-input v-model="form.hostUniq" />
        </el-form-item>

        <el-divider content-position="left">IPv4 设置</el-divider>
        <el-form-item label="自动获取 IP"><el-switch v-model="form.ipv4Auto" /></el-form-item>
        <el-form-item label="获取运营商 DNS"><el-switch v-model="form.ipv4PeerDns" /></el-form-item>
        <el-form-item label="自定义 DNS"><el-input v-model="form.ipv4Dns" /></el-form-item>
        <el-form-item label="默认路由"><el-switch v-model="form.ipv4DefaultRoute" /></el-form-item>
        <el-form-item label="路由度量">
          <el-input-number v-model="form.ipv4Metric" :min="0" :max="9999" controls-position="right" />
        </el-form-item>

        <el-divider content-position="left">IPv6 设置</el-divider>
        <el-form-item label="启用 IPv6"><el-switch v-model="form.ipv6Enabled" /></el-form-item>
        <el-form-item label="启用 IPv6CP"><el-switch v-model="form.ipv6cp" /></el-form-item>
        <el-form-item label="DHCPv6 客户端"><el-switch v-model="form.dhcpv6Client" /></el-form-item>
        <el-form-item label="IA_NA">
          <el-select v-model="form.iaNa">
            <el-option label="自动" value="auto" />
            <el-option label="强制" value="force" />
            <el-option label="禁用" value="disable" />
          </el-select>
        </el-form-item>
        <el-form-item label="IA_PD">
          <el-select v-model="form.iaPd">
            <el-option label="自动" value="auto" />
            <el-option label="强制" value="force" />
            <el-option label="禁用" value="disable" />
          </el-select>
        </el-form-item>
        <el-form-item label="请求前缀长度">
          <el-select v-model="form.pdLength">
            <el-option label="自动" value="auto" />
            <el-option label="/48" :value="48" />
            <el-option label="/56" :value="56" />
            <el-option label="/60" :value="60" />
            <el-option label="/64" :value="64" />
          </el-select>
        </el-form-item>
        <el-form-item label="获取 IPv6 DNS"><el-switch v-model="form.ipv6PeerDns" /></el-form-item>
        <el-form-item label="默认 IPv6 路由"><el-switch v-model="form.ipv6DefaultRoute" /></el-form-item>
        <el-form-item label="前缀变化自动更新"><el-switch v-model="form.pdAutoUpdate" /></el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </StandardModal>
  </PageContainer>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import {
  dialInstanceService,
  accessChannelService,
  physicalPortService,
} from '../../services/dataService.js'
import { toDialStatusRow } from '../../models/networkViewModels.js'

const list = ref([])
const channels = ref([])
const physicalPorts = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const detailDrawer = ref(false)
const selectedLine = ref(null)

const defaultForm = () => ({
  id: null,
  name: '',
  carrier: '中国电信',
  configuredUploadMbps: 50,
  channelId: null,
  account: '',
  password: '',
  serviceName: '',
  acName: '',
  mtu: 1492,
  mru: 1492,
  autoDial: true,
  autoRedial: true,
  redialInterval: 10,
  macMode: 'shared',
  mac: '',
  hostUniqMode: 'auto',
  hostUniq: '',
  ipv4Auto: true,
  ipv4PeerDns: true,
  ipv4Dns: '',
  ipv4DefaultRoute: true,
  ipv4Metric: 100,
  ipv6Enabled: true,
  ipv6cp: true,
  dhcpv6Client: true,
  iaNa: 'auto',
  iaPd: 'auto',
  pdLength: 'auto',
  ipv6PeerDns: true,
  ipv6DefaultRoute: true,
  pdAutoUpdate: true,
})
const form = reactive(defaultForm())

function protocolStatusText(status) {
  return {
    online: '正常',
    limited: '受限',
    abnormal: '异常',
    offline: '离线',
    disabled: '已停用',
  }[status] || '未知'
}

function protocolTagType(status) {
  return {
    online: 'success',
    limited: 'warning',
    abnormal: 'danger',
    offline: 'info',
    disabled: 'info',
  }[status] || 'info'
}

function qualityTagType(quality) {
  return {
    优秀: 'success',
    良好: 'primary',
    一般: 'warning',
    较差: 'danger',
    离线: 'info',
  }[quality] || 'info'
}

function macModeText(mode) {
  return {
    shared: '共用通道 MAC',
    auto: '自动生成',
    manual: '手动指定',
  }[mode] || '—'
}

function getChannel(id) {
  return channels.value.find(channel => channel.id === id)
}

function getChannelName(id) {
  return getChannel(id)?.name || '—'
}

function getAccessPort(channelId) {
  const channel = getChannel(channelId)
  const port = physicalPorts.value.find(item => item.id === channel?.physicalPortId)
  if (!port) return '—'
  if (port.alias) return port.alias
  const samePurposePorts = physicalPorts.value.filter(item => item.role === port.role)
  const sequence = samePurposePorts.findIndex(item => item.id === port.id) + 1
  const purpose = {
    wan: '宽带入口',
    mgmt: '管理口',
    lan: '局域网口',
    unassigned: '未分配网口',
  }[port.role] || '接入口'
  return samePurposePorts.length > 1 ? `${purpose} ${sequence}` : purpose
}

function getTechnicalInterface(channelId) {
  return getChannel(channelId)?.deviceName || '—'
}

function getVlanId(channelId) {
  const vlanId = getChannel(channelId)?.vlanId
  return vlanId == null ? '无' : vlanId
}

function formatPd(row) {
  const prefixes = row.runtimeStatus?.ipv6?.delegatedPrefixes || []
  return prefixes.length
    ? prefixes.map(item => `${item.prefix}/${item.length}`).join(', ')
    : '—'
}

async function loadData() {
  loading.value = true
  try {
    const [dialItems, channelItems, portItems] = await Promise.all([
      dialInstanceService.list(),
      accessChannelService.list(),
      physicalPortService.list(),
    ])
    channels.value = channelItems
    physicalPorts.value = portItems
    list.value = dialItems.map(toDialStatusRow)
  } catch (error) {
    ElMessage.error('加载失败：' + error.message)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, defaultForm())
  isEdit.value = false
  dialogVisible.value = true
}

function fillForm(row) {
  Object.assign(form, defaultForm(), {
    id: row.id,
    name: row.name,
    carrier: row.carrier,
    configuredUploadMbps: row.configuredUploadMbps,
    channelId: row.accessChannelId,
    account: row.username,
    password: '',
    serviceName: row.serviceName,
    acName: row.acName || '',
    mtu: row.mtu,
    mru: row.mru || row.mtu,
    autoDial: row.autoDial,
    autoRedial: row.redialOnDisconnect,
    redialInterval: row.redialInterval,
    macMode: row.macMode,
    mac: row.macAddress,
    hostUniqMode: row.hostUniqMode,
    hostUniq: row.hostUniq,
    ipv4Auto: row.ipv4Config?.autoAcquire,
    ipv4PeerDns: row.ipv4Config?.acquireDns,
    ipv4Dns: row.ipv4Config?.customDns,
    ipv4DefaultRoute: row.ipv4Config?.defaultRoute,
    ipv4Metric: row.ipv4Config?.metric,
    ipv6Enabled: row.ipv6Config?.enabled,
    ipv6cp: row.ipv6Config?.enableIpv6cp,
    dhcpv6Client: row.ipv6Config?.dhcpv6Client,
    iaNa: row.ipv6Config?.iaNa,
    iaPd: row.ipv6Config?.iaPd,
    pdLength: row.ipv6Config?.prefixLength,
    ipv6PeerDns: row.ipv6Config?.acquireDns,
    ipv6DefaultRoute: row.ipv6Config?.defaultRoute,
    pdAutoUpdate: row.ipv6Config?.autoUpdatePrefix,
  })
}

function openEdit(row) {
  fillForm(row)
  isEdit.value = true
  dialogVisible.value = true
}

function openDetails(row) {
  selectedLine.value = row
  detailDrawer.value = true
}

function editSelectedLine() {
  if (!selectedLine.value) return
  const row = selectedLine.value
  detailDrawer.value = false
  openEdit(row)
}

async function save() {
  const existing = isEdit.value ? dialInstanceService.get(form.id) : null
  if (
    !form.name
    || !form.carrier
    || !form.channelId
    || !form.account
    || !form.configuredUploadMbps
    || (!form.password && !existing?.passwordConfigured)
  ) {
    ElMessage.warning('请填写必填项')
    return
  }

  const payload = {
    name: form.name,
    carrier: form.carrier,
    configuredUploadMbps: form.configuredUploadMbps,
    accessChannelId: form.channelId,
    username: form.account,
    password: form.password,
    passwordConfigured: existing?.passwordConfigured || Boolean(form.password),
    serviceName: form.serviceName,
    acName: form.acName,
    mtu: form.mtu,
    mru: form.mru,
    enabled: existing?.enabled ?? true,
    autoDial: form.autoDial,
    redialOnDisconnect: form.autoRedial,
    redialInterval: form.redialInterval,
    macMode: form.macMode,
    macAddress: form.mac,
    hostUniqMode: form.hostUniqMode,
    hostUniq: form.hostUniq,
    ipv4Config: {
      autoAcquire: form.ipv4Auto,
      acquireDns: form.ipv4PeerDns,
      customDns: form.ipv4Dns,
      defaultRoute: form.ipv4DefaultRoute,
      metric: form.ipv4Metric,
    },
    ipv6Config: {
      enabled: form.ipv6Enabled,
      enableIpv6cp: form.ipv6cp,
      dhcpv6Client: form.dhcpv6Client,
      iaNa: form.iaNa,
      iaPd: form.iaPd,
      prefixLength: form.pdLength,
      acquireDns: form.ipv6PeerDns,
      defaultRoute: form.ipv6DefaultRoute,
      autoUpdatePrefix: form.pdAutoUpdate,
    },
  }

  try {
    if (isEdit.value) {
      await dialInstanceService.update(form.id, payload)
      ElMessage.success('线路已保存')
    } else {
      await dialInstanceService.create(payload)
      ElMessage.success('宽带已添加')
    }
    dialogVisible.value = false
    loadData()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

async function removeItem(row) {
  try {
    await dialInstanceService.remove(row.id)
    ElMessage.success('已删除线路 ' + row.name)
    loadData()
  } catch (error) {
    ElMessage.error('删除失败：' + error.message)
  }
}

onMounted(loadData)
</script>

<style scoped>
.line-table {
  --standard-table-scroll-width: 1580px;
}

.row-actions,
.detail-summary,
.detail-tags {
  display: flex;
  align-items: center;
}

.row-actions,
.detail-tags {
  gap: 4px;
  white-space: nowrap;
}

.detail-summary {
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 18px;
}

.detail-title {
  font-size: 18px;
  font-weight: 600;
}

.detail-subtitle {
  margin-top: 4px;
  color: var(--lh-text-secondary);
  font-size: 13px;
}

.detail-section-title {
  margin: 20px 0 8px;
  font-size: 14px;
  font-weight: 600;
}

.unit {
  margin-left: 8px;
  color: var(--lh-text-secondary);
  font-size: 12px;
}

:deep(.el-table td) {
  padding: 8px 0;
}

:deep(.el-table) {
  font-size: 14px;
}

@media (max-width: 767px) {
  .detail-summary {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
