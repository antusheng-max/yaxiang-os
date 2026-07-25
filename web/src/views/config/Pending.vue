<template>
  <PageContainer>
    <PageHeader title="待应用修改" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span>待应用修改</span>
                <div>
                  <el-button type="primary" @click="applyAll">全部应用</el-button>
                  <el-button type="danger" @click="discardAll">全部丢弃</el-button>
                </div>
              </div>
            </template>
            <StandardTable layout-mode="fill" :data="changes" border stripe size="small">
              <el-table-column label="操作类型" width="100">
                <template #default="{ row }">{{ typeText(row.type) }}</template>
              </el-table-column>
              <el-table-column prop="target" label="配置对象" min-width="150" />
              <el-table-column prop="description" label="变更说明" min-width="280" />
              <el-table-column label="修改时间" min-width="170">
                <template #default="{ row }">{{ formatTime(row.timestamp) }}</template>
              </el-table-column>
              <el-table-column label="操作" fixed="right">
                <template #default="{ row }">
                  <el-button size="small" type="primary" link @click="applyOne(row.id)">应用</el-button>
                  <el-button size="small" type="danger" link @click="discardOne(row.id)">丢弃</el-button>
                </template>
              </el-table-column>
            </StandardTable>
            <EmptyState v-if="changes.length === 0" description="没有待应用的修改" />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed } from 'vue'
import { ElMessage } from 'element-plus'
import { configurationApplyService } from '../../services/dataService.js'

const changes = computed(() => configurationApplyService.getPendingChanges())

const typeText = type => ({
  create: '新建',
  update: '修改',
  delete: '删除',
}[type] || type)
const formatTime = value => value ? new Date(value).toLocaleString('zh-CN') : '—'

function applyOne(id) {
  const result = configurationApplyService.applyOne(id)
  result.success ? ElMessage.success(result.message) : ElMessage.error(result.message)
}
function discardOne(id) {
  configurationApplyService.discard(id)
  ElMessage.info('已丢弃该项修改')
}
function applyAll() {
  const result = configurationApplyService.applyAll()
  result.success ? ElMessage.success(result.message) : ElMessage.error(result.message)
}
function discardAll() {
  configurationApplyService.clearPending()
  ElMessage.info('所有修改已丢弃')
}
</script>
