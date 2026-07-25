<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>汇聚组状态</h2>
      <p>查看各汇聚组的运行时状态，包括成员在线情况、PD 获取、连接数、流量与故障线路</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <CardToolbar class="toolbar">
            <el-button @click="loadData">刷新</el-button>
          </CardToolbar>
      
          <div v-loading="loading" class="cards-grid">
            <SectionCard
              v-for="g in groups"
              :key="g.id"
              shadow="hover"
              class="group-card"
            >
              <template #header>
                <div class="card-header">
                  <div class="card-title">
                    <span class="group-name">{{ g.name }}</span>
                    <el-tag :type="g.enabled ? 'success' : 'info'" effect="light" size="small">
                      <el-icon class="status-icon">
                        <CircleCheck v-if="g.enabled" />
                        <CircleClose v-else />
                      </el-icon>
                      {{ g.enabled ? '启用' : '禁用' }}
                    </el-tag>
                  </div>
                  <el-tag
                    :type="getStatus(g.id)?.failedMembers > 0 ? 'danger' : 'success'"
                    effect="light"
                    size="small"
                  >
                    <el-icon class="status-icon">
                      <CircleCheck v-if="getStatus(g.id)?.failedMembers === 0" />
                      <Warning v-else />
                    </el-icon>
                    {{ getStatus(g.id)?.failedMembers > 0 ? '有故障' : '正常' }}
                  </el-tag>
                </div>
              </template>
      
              <div v-if="getStatus(g.id)" class="card-body">
                <div class="info-row">
                  <span class="info-label">成员数</span>
                  <span class="info-value">{{ getStatus(g.id).totalMembers }}</span>
                </div>
                <el-divider class="mini-divider" />
                <div class="info-row">
                  <span class="info-label">IPv4 在线</span>
                  <span class="info-value">
                    {{ getStatus(g.id).ipv4OnlineMembers }} / {{ getStatus(g.id).totalMembers }}
                  </span>
                </div>
                <div class="info-row">
                  <span class="info-label">IPv6 在线</span>
                  <span class="info-value">
                    {{ getStatus(g.id).ipv6OnlineMembers }} / {{ getStatus(g.id).totalMembers }}
                  </span>
                </div>
                <div class="info-row">
                  <span class="info-label">获得 PD 数</span>
                  <span class="info-value">{{ getStatus(g.id).membersWithPd }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">NPTv6 数</span>
                  <span class="info-value">{{ getStatus(g.id).nptv6Count }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">NAT66 回退数</span>
                  <span class="info-value">{{ getStatus(g.id).nat66FallbackCount }}</span>
                </div>
                <el-divider class="mini-divider" />
                <div class="info-row">
                  <span class="info-label">当前 IPv4 连接数</span>
                  <span class="info-value">{{ getStatus(g.id).currentIpv4Connections }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">当前 IPv6 连接数</span>
                  <span class="info-value">{{ getStatus(g.id).currentIpv6Connections }}</span>
                </div>
                <el-divider class="mini-divider" />
                <div class="info-row">
                  <span class="info-label">总上下行</span>
                  <span class="info-value rate-text">
                    ↓{{ getStatus(g.id).totalRxMbps }} ↑{{ getStatus(g.id).totalTxMbps }} Mbps
                  </span>
                </div>
                <div class="info-row">
                  <span class="info-label">故障线路数</span>
                  <span class="info-value">
                    <el-tag
                      :type="getStatus(g.id).failedMembers > 0 ? 'danger' : 'success'"
                      effect="light"
                      size="small"
                    >
                      {{ getStatus(g.id).failedMembers }}
                    </el-tag>
                  </span>
                </div>
              </div>
            </SectionCard>
      
            <EmptyState v-if="!loading && groups.length === 0" description="暂无汇聚组" />
          </div>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheck, CircleClose, Warning } from '@element-plus/icons-vue'
import { aggregationGroupService, runtimeStatusService } from '../../services/dataService.js'

const groups = ref([])
const loading = ref(false)
const statusCache = ref({})

function getStatus(groupId) {
  return statusCache.value[groupId]
}

async function loadData() {
  loading.value = true
  try {
    const gs = await aggregationGroupService.list()
    groups.value = gs
    const cache = {}
    for (const g of gs) {
      cache[g.id] = runtimeStatusService.getGroupStatus(g.id)
    }
    statusCache.value = cache
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
}
.group-card { font-size: 14px; }
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.card-title {
  display: flex;
  align-items: center;
  gap: 8px;
}
.group-name { font-size: 16px; font-weight: 600; }
.card-body { font-size: 14px; }
.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 0;
}
.info-label { color: #666; font-size: 14px; }
.info-value { font-weight: 500; font-size: 14px; }
.mini-divider { margin: 8px 0; }
.rate-text { font-family: monospace; font-size: 13px; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-card__header) { padding: 12px 16px; }
:deep(.el-card__body) { padding: 12px 16px; }
</style>
