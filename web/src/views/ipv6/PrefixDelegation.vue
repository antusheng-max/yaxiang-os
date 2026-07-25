<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>PD 前缀管理</h2>
      <p>查看所有线路从运营商获取的 IPv6-PD 前缀、生命周期、归属汇聚及转换方式</p>
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
                  <el-table-column label="线路" min-width="140" fixed>
                    <template #default="{ row }">{{ getDiName(row.dialInstanceId) }}</template>
                  </el-table-column>
                  <el-table-column label="WAN IPv6 地址" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ row.wanIpv6Address || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="PD 前缀" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ row.pdPrefix || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="前缀长度" min-width="100">
                    <template #default="{ row }">{{ row.prefixLength || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="首选生命周期" min-width="120">
                    <template #default="{ row }">{{ formatLifetime(row.preferredLifetime) }}</template>
                  </el-table-column>
                  <el-table-column label="有效生命周期" min-width="120">
                    <template #default="{ row }">{{ formatLifetime(row.validLifetime) }}</template>
                  </el-table-column>
                  <el-table-column label="获取时间" min-width="160">
                    <template #default="{ row }">{{ row.obtainedAt || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="上次变化时间" min-width="160">
                    <template #default="{ row }">{{ row.lastChangedAt || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="归属汇聚组" min-width="140">
                    <template #default="{ row }">{{ getGroupName(row.aggregationGroupId) }}</template>
                  </el-table-column>
                  <el-table-column label="转换方式" min-width="130">
                    <template #default="{ row }">
                      <el-tag :type="translationTagType(row.translationMode)" effect="light">
                        <el-icon class="status-icon">
                          <Share v-if="row.translationMode === 'nptv6'" />
                          <Connection v-else-if="row.translationMode === 'nat66_fallback'" />
                          <Minus v-else />
                        </el-icon>
                        {{ translationText(row.translationMode) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="状态" min-width="120">
                    <template #default="{ row }">
                      <el-tag :type="statusTagType(row.status)" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="row.status === 'active'" />
                          <Warning v-else-if="row.status === 'no_pd'" />
                          <CircleClose v-else />
                        </el-icon>
                        {{ statusText(row.status) }}
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
import { CircleCheck, CircleClose, Warning, Share, Connection, Minus } from '@element-plus/icons-vue'
import { ipv6PrefixService, dialInstanceService, aggregationGroupService } from '../../services/dataService.js'

const list = ref([])
const dials = ref([])
const groups = ref([])
const loading = ref(false)

function getDiName(id) {
  if (!id) return '—'
  const d = dials.value.find(x => x.id === id)
  return d ? d.name : '—'
}

function getGroupName(id) {
  if (!id) return '—'
  const g = groups.value.find(x => x.id === id)
  return g ? g.name : '—'
}

function formatLifetime(sec) {
  if (!sec || sec <= 0) return '—'
  if (sec < 60) return `${sec} 秒`
  if (sec < 3600) return `${Math.floor(sec / 60)} 分钟`
  return `${Math.floor(sec / 3600)} 小时`
}

function translationText(mode) {
  return {
    nptv6: 'NPTv6',
    nat66_fallback: 'NAT66 回退',
    none: '无',
  }[mode] || mode
}

function translationTagType(mode) {
  return {
    nptv6: 'success',
    nat66_fallback: 'warning',
    none: 'info',
  }[mode] || 'info'
}

function statusText(s) {
  return {
    active: '有效',
    no_pd: '无 PD',
    ipv6_offline: 'IPv6 离线',
    expired: '已过期',
  }[s] || s
}

function statusTagType(s) {
  return {
    active: 'success',
    no_pd: 'warning',
    ipv6_offline: 'info',
    expired: 'danger',
  }[s] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    const [pm, d, g] = await Promise.all([
      ipv6PrefixService.list(),
      dialInstanceService.list(),
      aggregationGroupService.list(),
    ])
    list.value = pm
    dials.value = d
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
.mono { font-family: monospace; font-size: 13px; word-break: break-all; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-table) { font-size: 14px; }
</style>
