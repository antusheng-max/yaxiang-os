<template>
  <PageContainer>
    <PageHeader
      title="地域分析"
      description="按目标IP归属省份统计流量、连接数与平均连接时长，本地省份固定为江西省"
    >
      <template #actions>
        <el-tag type="warning" effect="plain">演示数据</el-tag>
        <el-select v-model="protocol" size="small" class="filter-select">
          <el-option label="IPv4 + IPv6" value="all" />
          <el-option label="仅 IPv4" value="ipv4" />
          <el-option label="仅 IPv6" value="ipv6" />
        </el-select>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <AnalyticsMetricGrid :items="metricItems" :column-span="4" />

      <el-row :gutter="16">
        <el-col :xs="24" :lg="16">
          <SectionCard shadow="never">
            <template #header>各省上传和下载流量排名</template>
            <AnalyticsChart :option="rankingOption" :height="360" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="8">
          <SectionCard shadow="never">
            <template #header>省内与出省比例</template>
            <AnalyticsChart :option="ratioOption" :height="360" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>省份明细</template>
        <StandardTable layout-mode="fill" :data="analysis.rows || []" border stripe>
          <el-table-column label="省份" min-width="150">
            <template #default="{ row }">
              <span>{{ row.province }}</span>
              <el-tag v-if="row.local" size="small" type="success" class="inline-tag">省内</el-tag>
              <el-tag v-if="!row.recognized" size="small" type="warning" class="inline-tag">单独统计</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="上传流量" min-width="130">
            <template #default="{ row }">{{ formatBytes(row.uploadBytes) }}</template>
          </el-table-column>
          <el-table-column label="下载流量" min-width="130">
            <template #default="{ row }">{{ formatBytes(row.downloadBytes) }}</template>
          </el-table-column>
          <el-table-column label="总流量" min-width="130">
            <template #default="{ row }">{{ formatBytes(row.totalBytes) }}</template>
          </el-table-column>
          <el-table-column prop="connections" label="连接数" min-width="110" />
          <el-table-column label="平均连接时长" min-width="130">
            <template #default="{ row }">{{ formatDuration(row.averageDurationSeconds) }}</template>
          </el-table-column>
          <el-table-column label="占比" width="110">
            <template #default="{ row }">{{ formatPercent(row.sharePercent, 2) }}</template>
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
import { geoTrafficService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes, formatDuration, formatPercent } from '../../utils/trafficFormat.js'

const loading = ref(false)
const protocol = ref('all')
const analysis = ref({ rows: [] })

const metricItems = computed(() => [
  { label: '本地省份', value: analysis.value.localProvince || '江西省', tone: 'primary' },
  { label: '流量最多省份', value: analysis.value.mostProvince || '-' },
  { label: '流量最少省份', value: analysis.value.leastProvince || '-' },
  { label: '省内流量', value: formatBytes(analysis.value.localBytes), tone: 'success' },
  { label: '出省流量', value: formatBytes(analysis.value.outboundBytes), tone: 'warning' },
  { label: '出省率', value: formatPercent(analysis.value.outboundRate), tone: 'warning' },
  { label: '已识别流量', value: formatBytes(analysis.value.identifiedBytes) },
  { label: '未识别地区', value: formatBytes(analysis.value.unknownBytes), tone: 'danger' },
])

const rankingOption = computed(() => {
  const rows = [...(analysis.value.rows || [])].slice(0, 10).reverse()
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    legend: { data: ['上传', '下载'], bottom: 0 },
    grid: { top: 20, left: 20, right: 24, bottom: 44, containLabel: true },
    xAxis: { type: 'value', name: 'TB' },
    yAxis: { type: 'category', data: rows.map((item) => item.province) },
    series: [
      {
        name: '上传',
        type: 'bar',
        stack: 'traffic',
        data: rows.map((item) => Number((item.uploadBytes / 1024 ** 4).toFixed(3))),
      },
      {
        name: '下载',
        type: 'bar',
        stack: 'traffic',
        data: rows.map((item) => Number((item.downloadBytes / 1024 ** 4).toFixed(3))),
      },
    ],
  }
})

const ratioOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}<br/>{d}%' },
  legend: { bottom: 0 },
  series: [{
    type: 'pie',
    radius: ['45%', '72%'],
    center: ['50%', '45%'],
    label: { formatter: '{b}\n{d}%' },
    data: [
      { name: '江西省内', value: analysis.value.localBytes || 0 },
      { name: '已识别出省', value: analysis.value.outboundBytes || 0 },
      { name: '未识别地区', value: analysis.value.unknownBytes || 0 },
    ],
  }],
}))

async function loadData() {
  loading.value = true
  try {
    const result = await geoTrafficService.getAnalysis({ protocol: protocol.value, window: '24h' })
    analysis.value = result.data
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
watch(protocol, loadData)
</script>

<style scoped>
.filter-select {
  width: 140px;
}

.inline-tag {
  margin-left: 8px;
}
</style>

