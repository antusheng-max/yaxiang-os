<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>汇聚统计</h2>
      <p>查看宽带线路与双栈线路汇聚的运行统计、流量与健康分布</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <CardToolbar class="toolbar">
            <el-button @click="loadData">刷新</el-button>
          </CardToolbar>
      
          <el-row :gutter="16" v-loading="loading">
            <el-col :span="6">
              <SectionCard shadow="never" class="stat-card">
                <div class="stat-label">线路总数</div>
                <div class="stat-value">{{ stats.total }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="6">
              <SectionCard shadow="never" class="stat-card stat-success">
                <div class="stat-label">在线数</div>
                <div class="stat-value">{{ stats.online }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="6">
              <SectionCard shadow="never" class="stat-card stat-info">
                <div class="stat-label">离线数</div>
                <div class="stat-value">{{ stats.offline }}</div>
              </SectionCard>
            </el-col>
            <el-col :span="6">
              <SectionCard shadow="never" class="stat-card">
                <div class="stat-label">汇聚组数量</div>
                <div class="stat-value">{{ stats.groups }}</div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <el-row :gutter="16">
            <el-col :span="12">
              <SectionCard shadow="never">
                <template #header>
                  <span class="card-title">IPv4 总流量</span>
                </template>
                <div class="traffic-block">
                  <div class="traffic-item">
                    <span class="traffic-label">下行</span>
                    <el-progress
                      :percentage="v4DownPct"
                      :format="() => stats.ipv4RxTotal || '0'"
                      :stroke-width="18"
                      color="#409eff"
                    />
                  </div>
                  <div class="traffic-item">
                    <span class="traffic-label">上行</span>
                    <el-progress
                      :percentage="v4UpPct"
                      :format="() => stats.ipv4TxTotal || '0'"
                      :stroke-width="18"
                      color="#67c23a"
                    />
                  </div>
                </div>
              </SectionCard>
            </el-col>
            <el-col :span="12">
              <SectionCard shadow="never">
                <template #header>
                  <span class="card-title">IPv6 总流量</span>
                </template>
                <div class="traffic-block">
                  <div class="traffic-item">
                    <span class="traffic-label">下行</span>
                    <el-progress
                      :percentage="v6DownPct"
                      :format="() => stats.ipv6RxTotal || '0'"
                      :stroke-width="18"
                      color="#409eff"
                    />
                  </div>
                  <div class="traffic-item">
                    <span class="traffic-label">上行</span>
                    <el-progress
                      :percentage="v6UpPct"
                      :format="() => stats.ipv6TxTotal || '0'"
                      :stroke-width="18"
                      color="#67c23a"
                    />
                  </div>
                </div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <el-row :gutter="16">
            <el-col :span="8">
              <SectionCard shadow="never">
                <template #header><span class="card-title">总连接数</span></template>
                <el-statistic :value="stats.connections" />
              </SectionCard>
            </el-col>
            <el-col :span="16">
              <SectionCard shadow="never">
                <template #header><span class="card-title">健康状态分布</span></template>
                <div class="health-dist">
                  <div v-for="h in healthDist" :key="h.key" class="health-bar-item">
                    <div class="health-bar-label">
                      <el-tag :type="h.tagType" size="small">{{ h.label }}</el-tag>
                    </div>
                    <div class="health-bar-track">
                      <div class="health-bar-fill" :style="{ width: h.pct + '%', background: h.color }"></div>
                    </div>
                    <div class="health-bar-count">{{ h.count }}</div>
                  </div>
                </div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <SectionCard shadow="never">
            <template #header><span class="card-title">各线路连接数分布</span></template>
            <StandardTable layout-mode="fill" :data="lineConnDist" size="default" border stripe>
              <el-table-column prop="name" label="线路名称" min-width="140" />
              <el-table-column label="状态" min-width="120">
                <template #default="{ row }">
                  <el-tag :type="statusTag(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="连接数" min-width="240">
                <template #default="{ row }">
                  <div class="conn-bar">
                    <div class="conn-bar-fill" :style="{ width: row.pct + '%' }"></div>
                    <span class="conn-bar-text">{{ row.connections }}</span>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="connections" label="数值" min-width="80" />
            </StandardTable>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  dialInstanceService,
  aggregationGroupService
} from '../../services/dataService.js'
import { toDialStatusRow } from '../../models/networkViewModels.js'

const loading = ref(false)
const instances = ref([])
const groups = ref([])

const stats = ref({
  total: 0,
  online: 0,
  offline: 0,
  groups: 0,
  connections: 0,
  ipv4RxTotal: '0',
  ipv4TxTotal: '0',
  ipv6RxTotal: '0',
  ipv6TxTotal: '0'
})

const maxTraffic = 100

const v4DownPct = computed(() => Math.min(100, parseTraffic(stats.value.ipv4RxTotal) / maxTraffic * 100))
const v4UpPct = computed(() => Math.min(100, parseTraffic(stats.value.ipv4TxTotal) / maxTraffic * 100))
const v6DownPct = computed(() => Math.min(100, parseTraffic(stats.value.ipv6RxTotal) / maxTraffic * 100))
const v6UpPct = computed(() => Math.min(100, parseTraffic(stats.value.ipv6TxTotal) / maxTraffic * 100))

function parseTraffic(v) {
  if (!v) return 0
  const s = String(v)
  const num = parseFloat(s)
  if (s.endsWith('G')) return num * 1024
  if (s.endsWith('M')) return num
  if (s.endsWith('K')) return num / 1024
  return num
}

const healthDist = computed(() => {
  const counts = { ok: 0, warning: 0, fail: 0, unknown: 0 }
  instances.value.forEach(i => {
    const h = i.health || 'unknown'
    counts[h] = (counts[h] || 0) + 1
  })
  const total = instances.value.length || 1
  return [
    { key: 'ok', label: '健康', count: counts.ok, pct: counts.ok / total * 100, color: '#67c23a', tagType: 'success' },
    { key: 'warning', label: '降级', count: counts.warning, pct: counts.warning / total * 100, color: '#e6a23c', tagType: 'warning' },
    { key: 'fail', label: '异常', count: counts.fail, pct: counts.fail / total * 100, color: '#f56c6c', tagType: 'danger' },
    { key: 'unknown', label: '未知', count: counts.unknown, pct: counts.unknown / total * 100, color: '#909399', tagType: 'info' }
  ]
})

const lineConnDist = computed(() => {
  const arr = instances.value.map(i => ({
    name: i.name,
    status: i.status,
    connections: i.connections || 0
  }))
  const max = Math.max(...arr.map(a => a.connections), 1)
  arr.forEach(a => { a.pct = a.connections / max * 100 })
  return arr
})

const statusText = (s) => ({
  dualStack: '双栈在线', ipv4Only: '仅 IPv4', ipv6NoPd: 'IPv6 无 PD',
  offline: '离线', disabled: '已禁用'
}[s] || s)
const statusTag = (s) => ({
  dualStack: 'success', ipv4Only: 'warning', ipv6NoPd: 'warning', offline: 'info', disabled: 'info'
}[s] || 'info')

async function loadData() {
  loading.value = true
  try {
    const [d, g] = await Promise.all([
      dialInstanceService.list(),
      aggregationGroupService.list()
    ])
    const rows = d.map(toDialStatusRow)
    instances.value = rows
    groups.value = g
    let online = 0, offline = 0, connections = 0
    let v4rx = 0, v4tx = 0, v6rx = 0, v6tx = 0
    rows.forEach(i => {
      if (['dualStack', 'ipv4Only', 'ipv6NoPd', 'ipv6Only'].includes(i.status)) online++
      else offline++
      connections += i.connections || 0
      v4rx += parseTraffic(i.ipv4RxTotal)
      v4tx += parseTraffic(i.ipv4TxTotal)
      v6rx += parseTraffic(i.ipv6RxTotal)
      v6tx += parseTraffic(i.ipv6TxTotal)
    })
    stats.value = {
      total: d.length,
      online,
      offline,
      groups: g.length,
      connections,
      ipv4RxTotal: formatTraffic(v4rx),
      ipv4TxTotal: formatTraffic(v4tx),
      ipv6RxTotal: formatTraffic(v6rx),
      ipv6TxTotal: formatTraffic(v6tx)
    }
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

function formatTraffic(mb) {
  if (mb >= 1024) return (mb / 1024).toFixed(2) + 'G'
  if (mb >= 1) return mb.toFixed(1) + 'M'
  return (mb * 1024).toFixed(0) + 'K'
}

onMounted(loadData)
</script>

<style scoped>
.stat-card { border-radius: 4px; }
.stat-card .stat-label { font-size: 13px; color: #666; margin-bottom: 6px; }
.stat-card .stat-value { font-size: 28px; font-weight: 600; }
.stat-success .stat-value { color: #67c23a; }
.stat-info .stat-value { color: #909399; }
.card-title { font-size: 14px; font-weight: 600; }
.traffic-block { display: flex; flex-direction: column; gap: 16px; }
.traffic-item { display: flex; align-items: center; gap: 12px; }
.traffic-label { width: 40px; font-size: 13px; color: #606266; }
.traffic-item :deep(.el-progress) { flex: 1; }
.health-dist { display: flex; flex-direction: column; gap: 12px; }
.health-bar-item { display: flex; align-items: center; gap: 12px; }
.health-bar-label { width: 60px; }
.health-bar-track { flex: 1; height: 16px; background: #f0f2f5; border-radius: 8px; overflow: hidden; }
.health-bar-fill { height: 100%; transition: width .3s; }
.health-bar-count { width: 40px; text-align: right; font-size: 14px; font-weight: 600; }
.conn-bar { position: relative; height: 18px; background: #f0f2f5; border-radius: 4px; overflow: hidden; }
.conn-bar-fill { height: 100%; background: #409eff; }
.conn-bar-text { position: absolute; right: 8px; top: 0; line-height: 18px; font-size: 12px; color: #303133; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
</style>
