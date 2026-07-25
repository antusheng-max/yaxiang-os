<template>
  <PageContainer>
    <PageHeader title="重启关机" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>重启与关机</span></template>
            <el-row :gutter="20">
              <el-col :span="8">
                <SectionCard shadow="hover" style="text-align:center">
                  <h4>重启系统</h4>
                  <p style="color:#909399;font-size:13px">重启路由器，所有连接将短暂中断</p>
                  <el-button type="warning" @click="doReboot">重启</el-button>
                </SectionCard>
              </el-col>
              <el-col :span="8">
                <SectionCard shadow="hover" style="text-align:center">
                  <h4>关机</h4>
                  <p style="color:#909399;font-size:13px">安全关闭系统</p>
                  <el-button type="danger" @click="doShutdown">关机</el-button>
                </SectionCard>
              </el-col>
              <el-col :span="8">
                <SectionCard shadow="hover" style="text-align:center">
                  <h4>重启网络</h4>
                  <p style="color:#909399;font-size:13px">仅重启网络服务，不重启系统</p>
                  <el-button type="primary" @click="doRestartNet">重启网络</el-button>
                </SectionCard>
              </el-col>
            </el-row>
            <el-divider />
            <el-descriptions :column="2" border>
              <el-descriptions-item label="运行时间">15天 3小时 22分</el-descriptions-item>
              <el-descriptions-item label="系统负载">0.15 / 0.12 / 0.08</el-descriptions-item>
              <el-descriptions-item label="CPU温度">52°C</el-descriptions-item>
              <el-descriptions-item label="内存使用">186MB / 512MB</el-descriptions-item>
            </el-descriptions>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ElMessage, ElMessageBox } from 'element-plus'

function doReboot() {
  ElMessageBox.confirm('确定要重启系统吗？', '确认', { type: 'warning' }).then(() => {
    ElMessage.info('系统正在重启...')
  }).catch(() => {})
}
function doShutdown() {
  ElMessageBox.confirm('确定要关机吗？', '确认', { type: 'warning' }).then(() => {
    ElMessage.info('系统正在关机...')
  }).catch(() => {})
}
function doRestartNet() {
  ElMessage.info('网络服务正在重启...')
  setTimeout(() => ElMessage.success('网络服务重启完成'), 2000)
}
</script>
