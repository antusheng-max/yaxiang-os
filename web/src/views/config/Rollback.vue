<template>
  <PageContainer>
    <PageHeader title="回滚" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>配置回滚</span></template>
            <el-alert title="回滚将恢复到上一次成功应用的配置状态" type="warning" :closable="false" />
            <el-descriptions :column="2" border>
              <el-descriptions-item label="当前配置版本">v2026.07.22-0915</el-descriptions-item>
              <el-descriptions-item label="上次稳定版本">v2026.07.21-1630</el-descriptions-item>
              <el-descriptions-item label="当前修改数">4 项待应用</el-descriptions-item>
              <el-descriptions-item label="回滚影响">network, firewall, dhcp</el-descriptions-item>
            </el-descriptions>
            <el-button type="danger" @click="rollback">回滚到上一版本</el-button>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ElMessage, ElMessageBox } from 'element-plus'

function rollback() {
  ElMessageBox.confirm('确定回滚到上一版本？当前未应用的修改将丢失。', '确认回滚', { type: 'warning' }).then(() => {
    ElMessage.info('正在回滚...')
    setTimeout(() => ElMessage.success('已回滚到 v2026.07.21-1630'), 2000)
  }).catch(() => {})
}
</script>
