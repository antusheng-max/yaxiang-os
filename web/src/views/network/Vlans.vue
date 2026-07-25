<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>VLAN管理</h2>
      <p>查看和管理所有 VLAN — 通过接入通道创建和管理，数据由接入通道自动汇总</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never" class="section-card">
            <div class="card-header-actions">
              <div class="header-left">
                <span class="header-title">VLAN列表</span>
                <span class="header-count">（共 {{ vlanList.length }} 个）</span>
              </div>
              <div class="header-right">
                <el-button @click="$router.go(0)">
                  <el-icon><Refresh /></el-icon>刷新
                </el-button>
                <el-button type="primary" @click="$router.push('/network/access-channels')">管理接入通道</el-button>
              </div>
            </div>
      
            <!-- 表格 fill 模式，100% 宽度 -->
            <StandardTable layout-mode="fill" :data="vlanList" border stripe size="default">
              <el-table-column label="VLAN ID" min-width="100">
                <template #default="{ row }">
                  <template v-if="row.vlanId">{{ row.vlanId }}</template>
                  <el-tag v-else size="small" type="info">Untagged</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="channelName" label="通道名称" min-width="160" />
              <el-table-column label="物理端口" min-width="120">
                <template #default="{ row }">{{ row.portName }}</template>
              </el-table-column>
              <el-table-column prop="deviceName" label="底层设备" min-width="160" />
              <el-table-column label="标签模式">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.tagMode==='dot1q' ? 'primary' : 'info'">{{ row.tagMode==='dot1q' ? '802.1Q' : 'Untagged' }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="线路数量">
                <template #default="{ row }">{{ row.dialCount }}</template>
              </el-table-column>
              <el-table-column label="状态">
                <template #default="{ row }">
                  <span class="status-tag">
                    <span :class="['status-dot', row.status==='up' ? 'online' : 'offline']"></span>
                    {{ row.status==='up' ? '活跃' : '离线' }}
                  </span>
                </template>
              </el-table-column>
            </StandardTable>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed } from 'vue'
import { accessChannelService, physicalPortService } from '../../services/dataService.js'

const vlanList = computed(() => accessChannelService.list().map(ch => {
  const port = physicalPortService.get(ch.physicalPortId)
  return {
    vlanId: ch.vlanId,
    channelName: ch.name,
    portName: port?.name || '—',
    deviceName: ch.deviceName,
    tagMode: ch.tagMode,
    dialCount: accessChannelService.countDialInstances(ch.id),
    status: ch.status,
  }
}))
</script>

<style scoped>
.section-card { margin-bottom: 16px; }
.card-header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.header-left { display: flex; align-items: baseline; gap: 4px; }
.header-title { font-size: 15px; font-weight: 600; }
.header-count { font-size: 13px; color: var(--lh-text-secondary); }
.header-right { display: flex; gap: 8px; }
</style>
