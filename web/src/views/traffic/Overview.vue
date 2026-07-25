<template>
  <PageContainer>
    <PageHeader
      title="流量总览"
      description="汇总双栈流量、地域与运营商方向，以及10条线路的实时上行能力"
    >
      <template #actions>
        <el-tag type="warning" effect="plain">演示数据</el-tag>
        <el-radio-group v-model="windowKey" size="small">
          <el-radio-button v-for="item in windows" :key="item.value" :value="item.value">
            {{ item.label }}
          </el-radio-button>
        </el-radio-group>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <AnalyticsMetricGrid :items="metricItems" />

      <el-row :gutter="16">
        <el-col :xs="24" :lg="16">
          <SectionCard shadow="never">
            <template #header>上传与下载趋势</template>
            <AnalyticsChart :option="trafficTrendOption" :height="320" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="8">
          <SectionCard shadow="never">
            <template #header>流量结构</template>
            <AnalyticsChart :option="compositionOption" :height="320" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>10条线路实时贡献</template>
        <StandardTable layout-mode="fill" :data="overview.lineContribution || []" border stripe>
          <el-table-column prop="lineName" label="线路名称" min-width="180" />
          <el-table-column prop="carrier" label="运营商" min-width="120" />
          <el-table-column label="当前上传" min-width="130">
            <template #default="{ row }">{{ formatRate(row.uploadMbps) }}</template>
          </el-table-column>
          <el-table-column label="当前下载" min-width="130">
            <template #default="{ row }">{{ formatRate(row.downloadMbps) }}</template>
          </el-table-column>
          <el-table-column label="上行利用率" min-width="180">
            <template #default="{ row }">
              <el-progress
                :percentage="row.utilizationPercent"
                :status="row.utilizationPercent >= 90 ? 'exception' : undefined"
                :stroke-width="12"
              />
            </template>
          </el-table-column>
          <el-table-column prop="activeConnections" label="活跃连接" min-width="110" />
          <el-table-column label="评分" min-width="100">
            <template #default="{ row }">{{ row.totalScore.toFixed(1) }}</template>
          </el-table-column>
          <el-table-column label="健康状态" width="110">
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
import { computed, onMounted, ref, watch } from 'vue'
import AnalyticsChart from '../../components/AnalyticsChart.vue'
import AnalyticsMetricGrid from '../../components/AnalyticsMetricGrid.vue'
import { trafficAnalyticsService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes, formatPercent, formatRate, healthTagType } from '../../utils/trafficFormat.js'

const loading = ref(false)
const windowKey = ref('5m')
const windows = ref([])
const overview = ref({ trend: {}, lineContribution: [] })

const metricItems = computed(() => [
  { label: '当前总上传', value: formatRate(overview.value.currentUploadMbps), tone: 'primary' },
  { label: '当前总下载', value: formatRate(overview.value.currentDownloadMbps), tone: 'primary' },
  { label: '今日上传', value: formatBytes(overview.value.todayUploadBytes), tone: 'success' },
  { label: '今日下载', value: formatBytes(overview.value.todayDownloadBytes), tone: 'success' },
  { label: 'IPv4流量', value: formatBytes(overview.value.ipv4Bytes) },
  { label: 'IPv6流量', value: formatBytes(overview.value.ipv6Bytes) },
  { label: '省内流量', value: formatBytes(overview.value.localProvinceBytes), hint: '本地省份：江西省' },
  { label: '出省流量', value: formatBytes(overview.value.outboundProvinceBytes), tone: 'warning' },
  { label: '出省率', value: formatPercent(overview.value.outboundRate), tone: 'warning' },
  { label: '本网流量', value: formatBytes(overview.value.onNetBytes) },
  { label: '跨网流量', value: formatBytes(overview.value.crossNetBytes), tone: 'warning' },
  { label: '未识别流量', value: formatBytes(overview.value.unknownBytes), tone: 'danger' },
  { label: '当前连接数', value: Number(overview.value.activeConnections || 0).toLocaleString() },
  {
    label: '10条线路总体上行利用率',
    value: formatPercent(overview.value.overallUploadUtilizationPercent),
    tone: Number(overview.value.overallUploadUtilizationPercent) >= 80 ? 'danger' : 'primary',
  },
])

const trafficTrendOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['上传', '下载', '活跃连接'], bottom: 0 },
  grid: { top: 24, left: 20, right: 30, bottom: 48, containLabel: true },
  xAxis: { type: 'category', boundaryGap: false, data: overview.value.trend?.labels || [] },
  yAxis: [
    { type: 'value', name: 'Mbps' },
    { type: 'value', name: '连接数', splitLine: { show: false } },
  ],
  series: [
    {
      name: '上传',
      type: 'line',
      smooth: true,
      showSymbol: false,
      data: overview.value.trend?.upload || [],
      areaStyle: { opacity: 0.12 },
    },
    {
      name: '下载',
      type: 'line',
      smooth: true,
      showSymbol: false,
      data: overview.value.trend?.download || [],
      areaStyle: { opacity: 0.08 },
    },
    {
      name: '活跃连接',
      type: 'line',
      yAxisIndex: 1,
      smooth: true,
      showSymbol: false,
      data: overview.value.trend?.connections || [],
      lineStyle: { type: 'dashed' },
    },
  ],
}))

const compositionOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}<br/>{d}%' },
  legend: { bottom: 0, type: 'scroll' },
  series: [{
    type: 'pie',
    radius: ['42%', '70%'],
    center: ['50%', '45%'],
    label: { formatter: '{b}\n{d}%' },
    data: [
      { name: '省内', value: overview.value.localProvinceBytes || 0 },
      { name: '出省', value: overview.value.outboundProvinceBytes || 0 },
      { name: '本网', value: overview.value.onNetBytes || 0 },
      { name: '跨网', value: overview.value.crossNetBytes || 0 },
      { name: '未识别', value: overview.value.unknownBytes || 0 },
    ],
  }],
}))

async function loadData() {
  loading.value = true
  try {
    const result = await trafficAnalyticsService.getOverview(windowKey.value)
    overview.value = result.data
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  const result = await trafficAnalyticsService.getWindows()
  windows.value = result.data
  await loadData()
})

watch(windowKey, loadData)
</script>

