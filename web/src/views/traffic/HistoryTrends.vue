<template>
  <PageContainer>
    <PageHeader
      title="历史趋势"
      description="查看流量、出省率、本网率、连接数与线路平均评分的历史变化"
    >
      <template #actions>
        <el-tag type="warning" effect="plain">演示数据</el-tag>
        <el-select v-model="windowKey" size="small" class="window-select">
          <el-option label="最近24小时" value="24h" />
          <el-option label="最近7天" value="7d" />
          <el-option label="最近14天" value="14d" />
        </el-select>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <el-row :gutter="16">
        <el-col :xs="24" :lg="16">
          <SectionCard shadow="never">
            <template #header>上传、下载及双栈流量趋势</template>
            <AnalyticsChart :option="trafficOption" :height="340" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="8">
          <SectionCard shadow="never">
            <template #header>活跃连接数趋势</template>
            <AnalyticsChart :option="connectionsOption" :height="340" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>出省率、本网率、延迟与线路评分</template>
        <AnalyticsChart :option="qualityOption" :height="320" />
      </SectionCard>

      <SectionCard shadow="never">
        <template #header>每日汇总</template>
        <StandardTable layout-mode="fill" :data="history.daily || []" border stripe>
          <el-table-column prop="date" label="日期" min-width="130" />
          <el-table-column label="上传流量" min-width="140">
            <template #default="{ row }">{{ formatBytes(row.uploadBytes) }}</template>
          </el-table-column>
          <el-table-column label="下载流量" min-width="140">
            <template #default="{ row }">{{ formatBytes(row.downloadBytes) }}</template>
          </el-table-column>
          <el-table-column label="出省率" min-width="110">
            <template #default="{ row }">{{ formatPercent(row.outboundRate) }}</template>
          </el-table-column>
          <el-table-column label="本网率" min-width="110">
            <template #default="{ row }">{{ formatPercent(row.onNetRate) }}</template>
          </el-table-column>
          <el-table-column prop="peakConnections" label="峰值连接数" min-width="130" />
          <el-table-column label="线路平均评分" width="130">
            <template #default="{ row }">{{ row.averageScore.toFixed(1) }}</template>
          </el-table-column>
        </StandardTable>
      </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import AnalyticsChart from '../../components/AnalyticsChart.vue'
import { trafficAnalyticsService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes, formatPercent } from '../../utils/trafficFormat.js'

const loading = ref(false)
const windowKey = ref('24h')
const history = ref({ series: [], daily: [] })

const labels = computed(() => history.value.series?.map((item) => item.time) || [])

const trafficOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['上传', '下载', 'IPv4', 'IPv6'], bottom: 0 },
  grid: { top: 20, left: 20, right: 20, bottom: 50, containLabel: true },
  xAxis: { type: 'category', boundaryGap: false, data: labels.value },
  yAxis: { type: 'value', name: 'Mbps' },
  series: [
    { name: '上传', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.uploadMbps) || [] },
    { name: '下载', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.downloadMbps) || [] },
    { name: 'IPv4', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.ipv4Mbps) || [], lineStyle: { type: 'dashed' } },
    { name: 'IPv6', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.ipv6Mbps) || [], lineStyle: { type: 'dashed' } },
  ],
}))

const connectionsOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  grid: { top: 20, left: 20, right: 20, bottom: 28, containLabel: true },
  xAxis: { type: 'category', boundaryGap: false, data: labels.value, axisLabel: { show: false } },
  yAxis: { type: 'value', name: '连接数' },
  series: [{
    type: 'line',
    smooth: true,
    showSymbol: false,
    areaStyle: { opacity: 0.18 },
    data: history.value.series?.map((item) => item.activeConnections) || [],
  }],
}))

const qualityOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['出省率', '本网率', '平均延迟', '线路评分'], bottom: 0 },
  grid: { top: 24, left: 20, right: 24, bottom: 50, containLabel: true },
  xAxis: { type: 'category', boundaryGap: false, data: labels.value },
  yAxis: [
    { type: 'value', name: '% / 分', max: 100 },
    { type: 'value', name: 'ms', splitLine: { show: false } },
  ],
  series: [
    { name: '出省率', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.outboundRate) || [] },
    { name: '本网率', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.onNetRate) || [] },
    { name: '平均延迟', type: 'line', yAxisIndex: 1, smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.averageLatencyMs) || [] },
    { name: '线路评分', type: 'line', smooth: true, showSymbol: false, data: history.value.series?.map((item) => item.averageScore) || [], lineStyle: { width: 3 } },
  ],
}))

async function loadData() {
  loading.value = true
  try {
    const result = await trafficAnalyticsService.getHistory({ window: windowKey.value })
    history.value = result.data
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
watch(windowKey, loadData)
</script>

<style scoped>
.window-select {
  width: 130px;
}
</style>

