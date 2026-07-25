<template>
  <PageContainer>
    <PageHeader title="HealthDetect" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>线路健康检测</span></template>
            <el-form inline>
              <el-form-item><el-button type="primary" @click="runAll">全部检测</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <StandardTable layout-mode="fill" :data="data" border stripe size="small">
            <el-table-column prop="line" label="线路" />
            <el-table-column prop="interface" label="接口" />
            <el-table-column prop="target" label="检测目标" />
            <el-table-column prop="latency" label="延迟" />
            <el-table-column prop="loss" label="丢包率" />
            <el-table-column prop="jitter" label="抖动" />
            <el-table-column prop="score" label="健康分">
              <template #default="{ row }">
                <el-tag :type="row.score >= 90 ? 'success' : row.score >= 60 ? 'warning' : 'danger'" size="small">{{ row.score }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态">
              <template #default="{ row }">
                <el-tag :type="row.status === '健康' ? 'success' : row.status === '检测中' ? 'warning' : 'danger'" size="small">{{ row.status }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="lastCheck" label="上次检测" />
            <el-table-column label="操作" fixed="right">
              <template #default="{ row }">
                <el-button size="small" link type="primary" @click="check(row)">检测</el-button>
              </template>
            </el-table-column>
          </StandardTable>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import { usePersistentRef } from '../../composables/usePersistentRef.js'
import { ElMessage } from 'element-plus'

const data = usePersistentRef('linehub:health', [
  { line: '电信主线', interface: 'wan', target: '202.96.128.86', latency: '8ms', loss: '0%', jitter: '1.2ms', score: 98, status: '健康', lastCheck: '2秒前' },
  { line: '联通备线', interface: 'wan2', target: '202.106.0.20', latency: '12ms', loss: '0.1%', jitter: '2.1ms', score: 92, status: '健康', lastCheck: '2秒前' },
  { line: '电信VLAN', interface: 'wan3', target: '202.96.128.86', latency: '6ms', loss: '0%', jitter: '0.8ms', score: 99, status: '健康', lastCheck: '5秒前' },
  { line: '企业专线', interface: 'wan4', target: '172.16.0.1', latency: '3ms', loss: '0%', jitter: '0.3ms', score: 100, status: '健康', lastCheck: '3秒前' },
])

function check(row) {
  row.status = '检测中'
  setTimeout(() => {
    row.latency = (Math.random() * 15 + 2).toFixed(0) + 'ms'
    row.loss = (Math.random() * 0.5).toFixed(1) + '%'
    row.jitter = (Math.random() * 3).toFixed(1) + 'ms'
    row.score = Math.floor(Math.random() * 15 + 85)
    row.status = '健康'
    row.lastCheck = '刚刚'
    ElMessage.success(`${row.line} 检测完成`)
  }, 1500)
}
function runAll() { data.value.forEach(r => check(r)) }
</script>
