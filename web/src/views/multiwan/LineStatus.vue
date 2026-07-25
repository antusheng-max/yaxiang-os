<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>线路状态</h2>
      <p>只读实时显示 PPPoE 线路的连接状态、地址、流量与健康信息</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <el-row :gutter="16" class="stat-row">
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card">
                <div class="stat-label">线路总数</div>
                <div class="stat-value">{{ stats.total }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card stat-success">
                <div class="stat-label">双栈在线</div>
                <div class="stat-value">{{ stats.dualStack }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card stat-warning">
                <div class="stat-label">仅 IPv4 在线</div>
                <div class="stat-value">{{ stats.ipv4Only }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card stat-warning">
                <div class="stat-label">IPv6 无 PD</div>
                <div class="stat-value">{{ stats.ipv6NoPd }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card stat-info">
                <div class="stat-label">离线线路</div>
                <div class="stat-value">{{ stats.offline }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="4">
              <SectionCard shadow="never" class="stat-card">
                <div class="stat-label">总连接数</div>
                <div class="stat-value">{{ stats.connections }}</div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <div class="filter-bar">
            <el-select v-model="filter.status" placeholder="状态筛选" clearable>
              <el-option label="全部" value="" />
              <el-option label="双栈在线" value="dualStack" />
              <el-option label="仅 IPv4" value="ipv4Only" />
              <el-option label="IPv6 无 PD" value="ipv6NoPd" />
              <el-option label="异常" value="abnormal" />
            </el-select>
            <el-select v-model="filter.portId" placeholder="物理端口" clearable>
              <el-option v-for="p in portOptions" :key="p.value" :label="p.label" :value="p.value" />
            </el-select>
            <el-input v-model="filter.vlan" placeholder="VLAN" clearable />
            <el-select v-model="filter.groupId" placeholder="汇聚组" clearable>
              <el-option v-for="g in groups" :key="g.id" :label="g.name" :value="g.id" />
            </el-select>
            <el-button @click="loadData">刷新</el-button>
          </div>
      
          <StandardTable layout-mode="scroll" :data="filtered" v-loading="loading" size="default" border stripe>
            <el-table-column label="PPPoE状态" min-width="120">
              <template #default="{ row }">
                <el-tag :type="statusTagType(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="sessionId" label="Session ID" min-width="110">
              <template #default="{ row }">{{ row.sessionId || '—' }}</template>
            </el-table-column>
            <el-table-column prop="uptime" label="在线时间" min-width="110">
              <template #default="{ row }">{{ row.uptime || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv4Address" label="IPv4 地址" min-width="130">
              <template #default="{ row }">{{ row.ipv4Address || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv4Peer" label="IPv4 对端" min-width="130">
              <template #default="{ row }">{{ row.ipv4Peer || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv4Dns" label="IPv4 DNS" min-width="140">
              <template #default="{ row }">{{ row.ipv4Dns || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv6LinkLocal" label="IPv6 链路本地" min-width="180">
              <template #default="{ row }">{{ row.ipv6LinkLocal || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv6Address" label="IPv6 公网" min-width="180">
              <template #default="{ row }">{{ row.ipv6Address || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv6Pd" label="IPv6-PD 前缀" min-width="180">
              <template #default="{ row }">{{ row.ipv6Pd || '—' }}</template>
            </el-table-column>
            <el-table-column prop="ipv6Dns" label="IPv6 DNS" min-width="160">
              <template #default="{ row }">{{ row.ipv6Dns || '—' }}</template>
            </el-table-column>
            <el-table-column label="IPv4 延迟" min-width="100">
              <template #default="{ row }">{{ row.ipv4Latency != null ? row.ipv4Latency + 'ms' : '—' }}</template>
            </el-table-column>
            <el-table-column label="IPv6 延迟" min-width="100">
              <template #default="{ row }">{{ row.ipv6Latency != null ? row.ipv6Latency + 'ms' : '—' }}</template>
            </el-table-column>
            <el-table-column label="丢包率" min-width="90">
              <template #default="{ row }">{{ row.lossRate != null ? row.lossRate + '%' : '—' }}</template>
            </el-table-column>
            <el-table-column label="RX/TX 实时速率" min-width="160">
              <template #default="{ row }">
                <span class="rate">↓{{ row.rxRate || '0K' }} ↑{{ row.txRate || '0K' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="累计流量" min-width="140">
              <template #default="{ row }">
                <span class="rate">↓{{ row.rxTotal || '0' }} ↑{{ row.txTotal || '0' }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="connections" label="活跃连接数" min-width="100" />
            <el-table-column prop="weight" label="当前权重" min-width="90" />
            <el-table-column label="健康状态" min-width="100">
              <template #default="{ row }">
                <el-tag :type="healthTagType(row.health)" size="small">
                  <el-icon v-if="row.health === 'ok'" class="status-icon"><CircleCheck /></el-icon>
                  <el-icon v-else-if="row.health === 'fail'" class="status-icon"><CircleClose /></el-icon>
                  {{ healthText(row.health) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="lastDownTime" label="最后断线时间" min-width="160">
              <template #default="{ row }">{{ row.lastDownTime || '—' }}</template>
            </el-table-column>
            <el-table-column prop="lastDownReason" label="最后断线原因" min-width="160">
              <template #default="{ row }">{{ row.lastDownReason || '—' }}</template>
            </el-table-column>
          </StandardTable>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheck, CircleClose } from '@element-plus/icons-vue'
import { dialInstanceService, aggregationGroupService, accessChannelService } from '../../services/dataService.js'
import { toDialStatusRow } from '../../models/networkViewModels.js'

const loading = ref(false)
const list = ref([])
const channels = ref([])
const groups = ref([])
const filter = reactive({ status: '', portId: null, vlan: '', groupId: null })

const portOptions = computed(() => {
  const options = new Map()
  channels.value.forEach(channel => {
    if (!channel.physicalPortId) return
    options.set(channel.physicalPortId, channel.deviceName?.split('.')[0] || channel.physicalPortId)
  })
  return [...options].map(([value, label]) => ({ label, value }))
})

const stats = computed(() => {
  const s = { total: list.value.length, dualStack: 0, ipv4Only: 0, ipv6NoPd: 0, offline: 0, connections: 0 }
  list.value.forEach(r => {
    if (r.status === 'dualStack') s.dualStack++
    if (r.status === 'ipv4Only') s.ipv4Only++
    if (r.status === 'ipv6NoPd') s.ipv6NoPd++
    if (r.status === 'offline' || r.status === 'disabled') s.offline++
    s.connections += r.connections || 0
  })
  return s
})

const filtered = computed(() => {
  return list.value.filter(r => {
    if (filter.status === 'abnormal') {
      if (!['ipv4Fail', 'ipv6Fail', 'authFail', 'offline'].includes(r.status)) return false
    } else if (filter.status && r.status !== filter.status) {
      return false
    }
    if (filter.portId != null) {
      const c = channels.value.find(x => x.id === r.channelId)
      if (!c || c.physicalPortId !== filter.portId) return false
    }
    if (filter.vlan) {
      const c = channels.value.find(x => x.id === r.channelId)
      if (!c || String(c.vlanId) !== filter.vlan) return false
    }
    if (filter.groupId && r.groupId !== filter.groupId) return false
    return true
  })
})

const statusText = (s) => ({
  dualStack: '双栈在线',
  ipv4Only: '仅 IPv4',
  ipv6NoPd: 'IPv6 无 PD',
  ipv6Only: '仅 IPv6',
  ipv4Fail: 'IPv4 失败',
  ipv6Fail: 'IPv6 失败',
  authFail: '认证失败',
  dialing: '拨号中',
  redialing: '重拨中',
  disabled: '已禁用',
  offline: '离线'
}[s] || s)

const statusTagType = (s) => ({
  dualStack: 'success',
  ipv4Only: 'warning',
  ipv6NoPd: 'warning',
  ipv6Only: 'warning',
  ipv4Fail: 'danger',
  ipv6Fail: 'danger',
  authFail: 'danger',
  dialing: 'info',
  redialing: 'info',
  disabled: 'info',
  offline: 'info'
}[s] || 'info')

const healthText = (h) => ({ ok: '健康', warning: '降级', fail: '异常', unknown: '未知' }[h] || h)
const healthTagType = (h) => ({ ok: 'success', warning: 'warning', fail: 'danger', unknown: 'info' }[h] || 'info')

async function loadData() {
  loading.value = true
  try {
    const [d, c, g] = await Promise.all([
      dialInstanceService.list(),
      accessChannelService.list(),
      aggregationGroupService.list()
    ])
    list.value = d.map(toDialStatusRow)
    channels.value = c
    groups.value = g
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.stat-row { margin-bottom: 16px; }
.stat-card { border-radius: 4px; }
.stat-card .stat-label { font-size: 13px; color: #666; margin-bottom: 6px; }
.stat-card .stat-value { font-size: 24px; font-weight: 600; color: #303133; }
.stat-success .stat-value { color: #67c23a; }
.stat-warning .stat-value { color: #e6a23c; }
.stat-info .stat-value { color: #909399; }
.filter-bar { margin-bottom: 16px; display: flex; gap: 8px; flex-wrap: wrap; }
.rate { font-family: monospace; font-size: 13px; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
</style>
