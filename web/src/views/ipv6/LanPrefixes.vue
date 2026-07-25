<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>LAN 前缀管理</h2>
      <p>查看各 LAN 网络的 IPv6 配置、前缀、网关、RA 模式、DHCPv6 与归属汇聚组</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-alert
                  type="info"
                  :closable="false"
                  show-icon
      
                >
                  当 LAN 绑定到汇聚组时，IPv6 前缀由汇聚组管理，此页面只读展示。
                </el-alert>
      
                <CardToolbar class="toolbar">
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="fill"
                  :data="list"
                  v-loading="loading"
                  size="default"
                  border
                  stripe
      
                >
                  <el-table-column prop="name" label="LAN 名称" min-width="140" fixed />
                  <el-table-column label="设备" min-width="140">
                    <template #default="{ row }">{{ getDeviceName(row.deviceId) }}</template>
                  </el-table-column>
                  <el-table-column label="IPv6 模式" min-width="140">
                    <template #default="{ row }">
                      <el-tag :type="row.ipv6Config?.mode === 'aggregation_managed' ? 'success' : 'info'" effect="light">
                        <el-icon class="status-icon">
                          <Connection v-if="row.ipv6Config?.mode === 'aggregation_managed'" />
                          <Edit v-else />
                        </el-icon>
                        {{ ipv6ModeText(row.ipv6Config?.mode) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6 前缀" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ row.ipv6Config?.prefix || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="IPv6 网关" min-width="180">
                    <template #default="{ row }">
                      <span class="mono">{{ row.ipv6Config?.gateway || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="RA 模式" min-width="120">
                    <template #default="{ row }">
                      <template v-if="row.raConfig?.enabled">
                        {{ raModeText(row.raConfig.mode) }}
                      </template>
                      <template v-else>未启用</template>
                    </template>
                  </el-table-column>
                  <el-table-column label="DHCPv6" min-width="100">
                    <template #default="{ row }">
                      <el-tag :type="row.dhcpv6Config?.enabled ? 'success' : 'info'" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="row.dhcpv6Config?.enabled" />
                          <CircleClose v-else />
                        </el-icon>
                        {{ row.dhcpv6Config?.enabled ? '启用' : '禁用' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="所属汇聚组" min-width="140">
                    <template #default="{ row }">{{ getGroupName(row.aggregationGroupId) }}</template>
                  </el-table-column>
                  <el-table-column label="状态" min-width="120">
                    <template #default="{ row }">
                      <el-tag :type="row.aggregationGroupId ? 'success' : 'info'" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="row.aggregationGroupId" />
                          <InfoFilled v-else />
                        </el-icon>
                        {{ row.aggregationGroupId ? '汇聚组管理' : '独立配置' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                </StandardTable>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  CircleCheck, CircleClose, Connection, Edit, InfoFilled,
} from '@element-plus/icons-vue'
import { lanService, aggregationGroupService, physicalPortService } from '../../services/dataService.js'

const list = ref([])
const groups = ref([])
const ports = ref([])
const loading = ref(false)

function getGroupName(id) {
  if (!id) return '—'
  const g = groups.value.find(x => x.id === id)
  return g ? g.name : '—'
}

function getDeviceName(id) {
  if (!id) return '—'
  const p = ports.value.find(x => x.id === id)
  return p ? p.name : id
}

function ipv6ModeText(mode) {
  return {
    manual: '手动',
    aggregation_managed: '由汇聚组管理',
    slaac: 'SLAAC',
    disabled: '禁用',
  }[mode] || mode || '—'
}

function raModeText(mode) {
  return {
    router: 'Router',
    managed: 'Managed',
    other: 'Other',
    relay: 'Relay',
  }[mode] || mode || '—'
}

async function loadData() {
  loading.value = true
  try {
    const [lans, g, p] = await Promise.all([
      lanService.list(),
      aggregationGroupService.list(),
      physicalPortService.list(),
    ])
    list.value = lans
    groups.value = g
    ports.value = p
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
