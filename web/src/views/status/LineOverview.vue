<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>线路概览</h2>
      <p>查看所有宽带线路的运行状态、双栈在线情况、PD 状态与流量统计</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <div class="stats-row">
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.total }}</div>
              <div class="stat-label">线路总数</div>
            </SectionCard>
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.dualStackOnline }}</div>
              <div class="stat-label">双栈在线</div>
            </SectionCard>
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.ipv4Only }}</div>
              <div class="stat-label">仅 IPv4 在线</div>
            </SectionCard>
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.ipv6NoPd }}</div>
              <div class="stat-label">IPv6 无 PD</div>
            </SectionCard>
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.offline }}</div>
              <div class="stat-label">离线</div>
            </SectionCard>
            <SectionCard class="stat-card" shadow="hover">
              <div class="stat-value">{{ stats.totalConnections }}</div>
              <div class="stat-label">总连接数</div>
            </SectionCard>
          </div>
      
          <CardToolbar class="toolbar">
            <el-radio-group v-model="filter" @change="applyFilter">
              <el-radio-button value="all">全部</el-radio-button>
              <el-radio-button value="dualStack">双栈在线</el-radio-button>
              <el-radio-button value="ipv4Only">仅 IPv4</el-radio-button>
              <el-radio-button value="abnormal">异常</el-radio-button>
            </el-radio-group>
            <el-button @click="loadData">刷新</el-button>
          </CardToolbar>
      
          <StandardTable layout-mode="scroll"
            :data="filteredList"
            v-loading="loading"
            size="default"
            border
            stripe
      
          >
            <el-table-column prop="name" label="线路名称" min-width="140" fixed />
            <el-table-column label="PPPoE 状态" min-width="130">
              <template #default="{ row }">
                <el-tag :type="pppoeTagType(row)" effect="light">
                  <el-icon class="status-icon">
                    <CircleCheck v-if="row.runtimeStatus?.pppoeState === 'connected'" />
                    <CircleClose v-else />
                  </el-icon>
                  {{ pppoeText(row) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="IPv4 状态" min-width="120">
              <template #default="{ row }">
                <el-tag :type="ipv4TagType(row)" effect="light">
                  <el-icon class="status-icon">
                    <CircleCheck v-if="row.runtimeStatus?.ipv4?.state === 'online'" />
                    <CircleClose v-else />
                  </el-icon>
                  {{ row.runtimeStatus?.ipv4?.state === 'online' ? '在线' : '离线' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="IPv6 状态" min-width="120">
              <template #default="{ row }">
                <el-tag :type="ipv6TagType(row)" effect="light">
                  <el-icon class="status-icon">
                    <CircleCheck v-if="row.runtimeStatus?.ipv6?.state === 'online'" />
                    <CircleClose v-else />
                  </el-icon>
                  {{ row.runtimeStatus?.ipv6?.state === 'online' ? '在线' : '离线' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="PD 状态" min-width="130">
              <template #default="{ row }">
                <el-tag :type="pdTagType(row)" effect="light">
                  <el-icon class="status-icon">
                    <CircleCheck v-if="row.runtimeStatus?.ipv6?.hasUsablePd" />
                    <Warning v-else-if="row.runtimeStatus?.ipv6?.state === 'online'" />
                    <CircleClose v-else />
                  </el-icon>
                  {{ pdText(row) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="当前上下行" min-width="140">
              <template #default="{ row }">
                <span class="rate-text">
                  ↓{{ row.runtimeStatus?.rxRate || 0 }} ↑{{ row.runtimeStatus?.txRate || 0 }}
                </span>
              </template>
            </el-table-column>
            <el-table-column label="连接数" min-width="90">
              <template #default="{ row }">{{ row.runtimeStatus?.activeConnections || 0 }}</template>
            </el-table-column>
            <el-table-column label="健康状态" min-width="130">
              <template #default="{ row }">
                <el-tag :type="healthTagType(row)" effect="light">
                  <el-icon class="status-icon">
                    <CircleCheck v-if="row.runtimeStatus?.healthState === 'healthy'" />
                    <Warning v-else-if="row.runtimeStatus?.healthState === 'ipv6_no_pd' || row.runtimeStatus?.healthState === 'ipv4_only'" />
                    <CircleClose v-else />
                  </el-icon>
                  {{ healthText(row) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="汇聚组" min-width="140">
              <template #default="{ row }">{{ getGroupName(row.aggregationGroupId) }}</template>
            </el-table-column>
            <el-table-column label="操作" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="openDetail(row)">查看详情</el-button>
              </template>
            </el-table-column>
          </StandardTable>
      
          <StandardModal size="standard"
            v-model="detailVisible"
            :title="`线路详情 — ${current?.name || ''}`"
          >
            <el-descriptions v-if="current" :column="1" border>
              <el-descriptions-item label="线路名称">{{ current.name }}</el-descriptions-item>
              <el-descriptions-item label="PPPoE 状态">{{ pppoeText(current) }} (会话ID: {{ current.runtimeStatus?.sessionId || '—' }})</el-descriptions-item>
              <el-descriptions-item label="在线时长">{{ current.runtimeStatus?.uptime || '—' }}</el-descriptions-item>
              <el-descriptions-item label="IPv4 地址">
                <span class="mono">{{ current.runtimeStatus?.ipv4?.address || '—' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="IPv4 网关">
                <span class="mono">{{ current.runtimeStatus?.ipv4?.gateway || '—' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="IPv6 公网地址">
                <span class="mono">{{ (current.runtimeStatus?.ipv6?.globalAddresses || []).join(', ') || '—' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="IPv6 PD 前缀">
                <span class="mono">{{ getPdText(current) || '—' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="上下行速率">↓{{ current.runtimeStatus?.rxRate || 0 }} Mbps / ↑{{ current.runtimeStatus?.txRate || 0 }} Mbps</el-descriptions-item>
              <el-descriptions-item label="活跃连接数">{{ current.runtimeStatus?.activeConnections || 0 }}</el-descriptions-item>
              <el-descriptions-item label="当前权重">{{ current.runtimeStatus?.currentWeight || 0 }}</el-descriptions-item>
              <el-descriptions-item label="上次断线时间">{{ current.runtimeStatus?.lastDisconnectTime || '—' }}</el-descriptions-item>
              <el-descriptions-item label="上次断线原因">{{ current.runtimeStatus?.lastDisconnectReason || '—' }}</el-descriptions-item>
            </el-descriptions>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheck, CircleClose, Warning } from '@element-plus/icons-vue'
import { dialInstanceService, aggregationGroupService } from '../../services/dataService.js'

const list = ref([])
const groups = ref([])
const loading = ref(false)
const filter = ref('all')
const detailVisible = ref(false)
const current = ref(null)

const stats = computed(() => {
  const all = list.value
  return {
    total: all.length,
    dualStackOnline: all.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state === 'online').length,
    ipv4Only: all.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state !== 'online').length,
    ipv6NoPd: all.filter(d => d.runtimeStatus?.ipv6?.state === 'online' && !d.runtimeStatus?.ipv6?.hasUsablePd).length,
    offline: all.filter(d => d.runtimeStatus?.pppoeState === 'disconnected').length,
    totalConnections: all.reduce((s, d) => s + (d.runtimeStatus?.activeConnections || 0), 0),
  }
})

const filteredList = computed(() => {
  if (filter.value === 'all') return list.value
  if (filter.value === 'dualStack') {
    return list.value.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state === 'online')
  }
  if (filter.value === 'ipv4Only') {
    return list.value.filter(d => d.runtimeStatus?.ipv4?.state === 'online' && d.runtimeStatus?.ipv6?.state !== 'online')
  }
  if (filter.value === 'abnormal') {
    return list.value.filter(d =>
      d.runtimeStatus?.pppoeState !== 'connected' ||
      d.runtimeStatus?.ipv4?.state !== 'online' ||
      d.runtimeStatus?.ipv6?.state !== 'online' ||
      !d.runtimeStatus?.ipv6?.hasUsablePd
    )
  }
  return list.value
})

function getGroupName(id) {
  if (!id) return '—'
  const g = groups.value.find(x => x.id === id)
  return g ? g.name : '—'
}

function getPdText(row) {
  const pds = row?.runtimeStatus?.ipv6?.delegatedPrefixes || []
  if (pds.length === 0) return ''
  return `${pds[0].prefix}/${pds[0].length}`
}

function pppoeText(row) {
  return row.runtimeStatus?.pppoeState === 'connected' ? '已连接' : '未连接'
}
function pppoeTagType(row) {
  return row.runtimeStatus?.pppoeState === 'connected' ? 'success' : 'info'
}

function ipv4TagType(row) {
  return row.runtimeStatus?.ipv4?.state === 'online' ? 'success' : 'info'
}

function ipv6TagType(row) {
  return row.runtimeStatus?.ipv6?.state === 'online' ? 'success' : 'info'
}

function pdText(row) {
  if (row.runtimeStatus?.ipv6?.state !== 'online') return '—'
  return row.runtimeStatus?.ipv6?.hasUsablePd ? '已获取' : '无 PD'
}

function pdTagType(row) {
  if (row.runtimeStatus?.ipv6?.state !== 'online') return 'info'
  return row.runtimeStatus?.ipv6?.hasUsablePd ? 'success' : 'warning'
}

function healthText(row) {
  return {
    healthy: '健康',
    ipv6_no_pd: 'IPv6 无 PD',
    ipv4_only: '仅 IPv4',
    offline: '离线',
    degraded: '降级',
  }[row.runtimeStatus?.healthState] || row.runtimeStatus?.healthState || '—'
}

function healthTagType(row) {
  return {
    healthy: 'success',
    ipv6_no_pd: 'warning',
    ipv4_only: 'warning',
    offline: 'info',
    degraded: 'danger',
  }[row.runtimeStatus?.healthState] || 'info'
}

function applyFilter() {
  // 筛选由 computed 自动处理
}

function openDetail(row) {
  current.value = row
  detailVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const [d, g] = await Promise.all([
      dialInstanceService.list(),
      aggregationGroupService.list(),
    ])
    list.value = d
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
.stats-row {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 12px;
  margin-bottom: var(--layout-section-gap);
}
.stat-card {
  text-align: center;
}
.stat-value {
  font-size: 28px;
  font-weight: 600;
  line-height: 1.2;
}
.stat-label {
  font-size: 13px;
  color: #888;
  margin-top: 4px;
}
.rate-text { font-family: monospace; font-size: 13px; }
.mono { font-family: monospace; font-size: 13px; word-break: break-all; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-table) { font-size: 14px; }
</style>
