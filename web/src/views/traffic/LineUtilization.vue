<template>
  <PageContainer>
    <PageHeader
      title="线路利用率"
      description="查看10条PPPoE双栈线路的实时负载、剩余能力、质量评分与调度权重"
    >
      <template #actions>
        <el-tag type="warning" effect="plain">演示数据</el-tag>
        <el-button size="small" @click="loadData">刷新评分</el-button>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <AnalyticsMetricGrid :items="metricItems" :column-span="4" />

      <el-row :gutter="16">
        <el-col :xs="24" :lg="16">
          <SectionCard shadow="never">
            <template #header>各线路上行利用率与剩余能力</template>
            <AnalyticsChart :option="utilizationOption" :height="360" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="8">
          <SectionCard shadow="never">
            <template #header>健康状态分布</template>
            <AnalyticsChart :option="healthOption" :height="360" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>线路实时质量明细</template>
        <StandardTable
          layout-mode="scroll"
          class="line-quality-table"
          :data="lines"
          border
          stripe
        >
          <el-table-column prop="name" label="线路名称" width="180" fixed="left" />
          <el-table-column prop="carrier" label="运营商" width="110" />
          <el-table-column prop="vlan" label="VLAN" width="80" />
          <el-table-column label="IPv4状态" width="100">
            <template #default="{ row }">
              <el-tag :type="row.ipv4Healthy ? 'success' : 'danger'" size="small">{{ row.ipv4Status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="IPv6状态" width="100">
            <template #default="{ row }">
              <el-tag :type="row.ipv6Healthy ? 'success' : 'danger'" size="small">{{ row.ipv6Status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="配置上行" width="110">
            <template #default="{ row }">{{ formatRate(row.configuredUploadMbps) }}</template>
          </el-table-column>
          <el-table-column label="当前上传" width="110">
            <template #default="{ row }">{{ formatRate(row.currentUploadMbps) }}</template>
          </el-table-column>
          <el-table-column label="当前下载" width="110">
            <template #default="{ row }">{{ formatRate(row.currentDownloadMbps) }}</template>
          </el-table-column>
          <el-table-column label="上行利用率" width="180">
            <template #default="{ row }">
              <el-progress
                :percentage="row.utilizationPercent"
                :status="row.utilizationPercent >= 90 ? 'exception' : undefined"
                :stroke-width="12"
              />
            </template>
          </el-table-column>
          <el-table-column label="剩余上行能力" width="130">
            <template #default="{ row }">{{ formatRate(row.availableUploadMbps) }}</template>
          </el-table-column>
          <el-table-column prop="activeConnections" label="活跃连接数" width="110" />
          <el-table-column prop="latencyMs" label="平均延迟(ms)" width="115" />
          <el-table-column prop="jitterMs" label="抖动(ms)" width="95" />
          <el-table-column prop="packetLossPercent" label="丢包率(%)" width="95" />
          <el-table-column prop="reconnectCount24h" label="24h断线" width="95" />
          <el-table-column label="综合评分" width="100">
            <template #default="{ row }">
              <strong :class="scoreClass(row.totalScore)">{{ row.totalScore.toFixed(1) }}</strong>
            </template>
          </el-table-column>
          <el-table-column prop="rank" label="排名" width="80" />
          <el-table-column prop="currentWeight" label="当前权重" width="100" />
          <el-table-column label="健康状态" width="110" fixed="right">
            <template #default="{ row }">
              <el-tag :type="healthTagType(row.healthState)" size="small">{{ row.healthState }}</el-tag>
            </template>
          </el-table-column>
        </StandardTable>
      </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import AnalyticsChart from '../../components/AnalyticsChart.vue'
import AnalyticsMetricGrid from '../../components/AnalyticsMetricGrid.vue'
import { lineQualityService } from '../../services/trafficAnalyticsServices.js'
import { formatPercent, formatRate, healthTagType } from '../../utils/trafficFormat.js'

const loading = ref(false)
const lines = ref([])

const metricItems = computed(() => {
  const total = lines.value.length || 1
  const healthy = lines.value.filter((line) => ['优秀', '良好'].includes(line.healthState)).length
  const averageUtilization = lines.value.reduce((sum, line) => sum + line.utilizationPercent, 0) / total
  const availableUpload = lines.value.reduce((sum, line) => sum + line.availableUploadMbps, 0)
  const connections = lines.value.reduce((sum, line) => sum + line.activeConnections, 0)
  const averageScore = lines.value.reduce((sum, line) => sum + line.totalScore, 0) / total
  return [
    { label: '线路总数', value: String(lines.value.length), hint: '10条PPPoE线路' },
    { label: '优秀 / 良好', value: `${healthy} 条`, tone: 'success' },
    { label: '平均上行利用率', value: formatPercent(averageUtilization), tone: averageUtilization >= 80 ? 'danger' : 'primary' },
    { label: '总体剩余上行能力', value: formatRate(availableUpload), tone: 'success' },
    { label: '活跃连接总数', value: connections.toLocaleString() },
    { label: '线路平均评分', value: averageScore.toFixed(1), tone: 'primary' },
  ]
})

const utilizationOption = computed(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  legend: { data: ['已使用上行', '剩余上行'], bottom: 0 },
  grid: { top: 18, left: 20, right: 20, bottom: 58, containLabel: true },
  xAxis: { type: 'category', data: lines.value.map((line) => line.name), axisLabel: { rotate: 30 } },
  yAxis: { type: 'value', name: 'Mbps', max: 100 },
  series: [
    {
      name: '已使用上行',
      type: 'bar',
      stack: 'upload',
      data: lines.value.map((line) => line.currentUploadMbps),
      itemStyle: {
        color: (params) => lines.value[params.dataIndex]?.utilizationPercent >= 90 ? '#f56c6c' : '#1677ff',
      },
    },
    {
      name: '剩余上行',
      type: 'bar',
      stack: 'upload',
      data: lines.value.map((line) => line.availableUploadMbps),
      itemStyle: { color: '#c6e2ff' },
    },
  ],
}))

const healthOption = computed(() => {
  const counts = lines.value.reduce((result, line) => {
    result[line.healthState] = (result[line.healthState] || 0) + 1
    return result
  }, {})
  return {
    tooltip: { trigger: 'item', formatter: '{b}<br/>{c}条（{d}%）' },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie',
      radius: ['42%', '70%'],
      center: ['50%', '45%'],
      data: Object.entries(counts).map(([name, value]) => ({ name, value })),
    }],
  }
})

function scoreClass(score) {
  if (score >= 85) return 'score-excellent'
  if (score >= 70) return 'score-good'
  if (score >= 55) return 'score-warning'
  return 'score-danger'
}

async function loadData() {
  loading.value = true
  try {
    const result = await lineQualityService.listLines()
    lines.value = result.data
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.line-quality-table {
  --standard-table-scroll-width: 2200px;
}

.score-excellent { color: #67c23a; }
.score-good { color: #409eff; }
.score-warning { color: #e6a23c; }
.score-danger { color: #f56c6c; }
</style>

