<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>IPv6 地址状态</h2>
      <p>查看所有线路的 IPv6 链路本地地址、公网地址、PD 前缀、DNS、网关、延迟等运行时信息</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CardToolbar class="toolbar">
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="scroll"
                  :data="list"
                  v-loading="loading"
                  size="default"
                  border
                  stripe
      
                >
                  <el-table-column prop="name" label="线路" min-width="140" fixed />
                  <el-table-column label="链路本地地址" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ getLinkLocal(row) || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6 公网地址" min-width="220">
                    <template #default="{ row }">
                      <span class="mono">{{ getGlobalAddrs(row).join(', ') || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6-PD 前缀" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ getPdPrefix(row) || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="前缀长度" min-width="100">
                    <template #default="{ row }">
                      {{ getPdLength(row) || '—' }}
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6 DNS" min-width="180">
                    <template #default="{ row }">
                      <span class="mono">{{ getDns(row).join(', ') || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6 网关" min-width="180">
                    <template #default="{ row }">
                      <span class="mono">{{ getGateway(row) || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="延迟" min-width="90">
                    <template #default="{ row }">
                      {{ getLatency(row) ? getLatency(row) + ' ms' : '—' }}
                    </template>
                  </el-table-column>
                  <el-table-column label="状态" min-width="130">
                    <template #default="{ row }">
                      <el-tag :type="statusTagType(row)" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="isOnline(row) && hasPd(row)" />
                          <Warning v-else-if="isOnline(row) && !hasPd(row)" />
                          <CircleClose v-else />
                        </el-icon>
                        {{ statusText(row) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="操作" fixed="right">
                    <template #default="{ row }">
                      <el-button link type="primary" @click="openDetail(row)">查看详情</el-button>
                    </template>
                  </el-table-column>
                </StandardTable>
      
                <StandardModal size="standard"
                  v-model="detailVisible"
                  :title="`IPv6 详情 — ${current?.name || ''}`"
                >
                  <el-descriptions v-if="current" :column="1" border>
                    <el-descriptions-item label="线路">{{ current.name }}</el-descriptions-item>
                    <el-descriptions-item label="IPv6 状态">
                      <el-tag :type="statusTagType(current)" effect="light">{{ statusText(current) }}</el-tag>
                    </el-descriptions-item>
                    <el-descriptions-item label="链路本地地址">
                      <span class="mono">{{ getLinkLocal(current) || '—' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="公网地址">
                      <span class="mono">{{ getGlobalAddrs(current).join('\n') || '—' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="PD 前缀">
                      <span class="mono">{{ getPdPrefix(current) || '—' }}/{{ getPdLength(current) || '' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="DNS">
                      <span class="mono">{{ getDns(current).join(', ') || '—' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="网关">
                      <span class="mono">{{ getGateway(current) || '—' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="延迟">{{ getLatency(current) || 0 }} ms</el-descriptions-item>
                    <el-descriptions-item label="丢包率">{{ getPacketLoss(current) || 0 }}%</el-descriptions-item>
                  </el-descriptions>
                </StandardModal>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheck, CircleClose, Warning } from '@element-plus/icons-vue'
import { dialInstanceService } from '../../services/dataService.js'

const list = ref([])
const loading = ref(false)
const detailVisible = ref(false)
const current = ref(null)

function getIpv6(row) {
  return row?.runtimeStatus?.ipv6 || {}
}

function getLinkLocal(row) {
  return getIpv6(row).linkLocalAddress
}

function getGlobalAddrs(row) {
  return getIpv6(row).globalAddresses || []
}

function getPdPrefix(row) {
  const pds = getIpv6(row).delegatedPrefixes || []
  return pds.length > 0 ? pds[0].prefix : ''
}

function getPdLength(row) {
  const pds = getIpv6(row).delegatedPrefixes || []
  return pds.length > 0 ? pds[0].length : ''
}

function getDns(row) {
  return getIpv6(row).dnsServers || []
}

function getGateway(row) {
  return getIpv6(row).gateway
}

function getLatency(row) {
  return getIpv6(row).latency
}

function getPacketLoss(row) {
  return getIpv6(row).packetLoss
}

function isOnline(row) {
  return getIpv6(row).state === 'online'
}

function hasPd(row) {
  return getIpv6(row).hasUsablePd
}

function statusText(row) {
  if (!isOnline(row)) return '离线'
  if (!hasPd(row)) return '无 PD'
  return '在线'
}

function statusTagType(row) {
  if (!isOnline(row)) return 'info'
  if (!hasPd(row)) return 'warning'
  return 'success'
}

function openDetail(row) {
  current.value = row
  detailVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    list.value = await dialInstanceService.list()
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.mono { font-family: monospace; font-size: 13px; word-break: break-all; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-table) { font-size: 14px; }
</style>
