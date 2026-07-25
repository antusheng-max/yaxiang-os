<template>
  <PageContainer>
    <PageHeader
      title="活跃连接"
      description="查看当前模拟连接的出口线路、目标地域、目标运营商和流量规模"
    >
      <template #actions>
        <el-tag type="warning" effect="plain">演示数据</el-tag>
        <el-button size="small" @click="loadRows">刷新连接</el-button>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <AnalyticsMetricGrid :items="metricItems" :column-span="4" />

      <SectionCard shadow="never">
        <template #header>筛选条件</template>
        <el-form inline class="filter-form">
          <el-form-item label="IP协议">
            <el-select v-model="filters.ipVersion">
              <el-option label="全部" value="all" />
              <el-option label="IPv4" value="IPv4" />
              <el-option label="IPv6" value="IPv6" />
            </el-select>
          </el-form-item>
          <el-form-item label="目标省份">
            <el-select v-model="filters.province">
              <el-option label="全部" value="all" />
              <el-option v-for="item in provinceOptions" :key="item" :label="item" :value="item" />
            </el-select>
          </el-form-item>
          <el-form-item label="目标运营商">
            <el-select v-model="filters.carrier">
              <el-option label="全部" value="all" />
              <el-option v-for="item in carrierOptions" :key="item" :label="item" :value="item" />
            </el-select>
          </el-form-item>
          <el-form-item label="出口线路">
            <el-select v-model="filters.lineId">
              <el-option label="全部" value="all" />
              <el-option
                v-for="item in lineOptions"
                :key="item.lineId"
                :label="item.lineName"
                :value="item.lineId"
              />
            </el-select>
          </el-form-item>
        </el-form>
      </SectionCard>

      <el-row :gutter="16">
        <el-col :xs="24" :lg="12">
          <SectionCard shadow="never">
            <template #header>当前连接地域分布</template>
            <AnalyticsChart :option="provinceOption" :height="300" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="12">
          <SectionCard shadow="never">
            <template #header>协议与应用分布</template>
            <AnalyticsChart :option="protocolOption" :height="300" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>连接明细（当前筛选 {{ rows.length }} 条）</template>
        <StandardTable
          layout-mode="scroll"
          class="flow-table"
          :data="rows"
          border
          stripe
        >
          <el-table-column prop="sourceIp" label="源IP" width="150" fixed="left" />
          <el-table-column prop="sourcePort" label="源端口" width="90" />
          <el-table-column prop="destinationIp" label="目标IP" width="250" />
          <el-table-column prop="destinationPort" label="目标端口" width="100" />
          <el-table-column prop="ipVersion" label="IP协议" width="90" />
          <el-table-column prop="protocol" label="传输协议" width="100" />
          <el-table-column prop="application" label="应用识别" width="110" />
          <el-table-column prop="province" label="目标省份" width="120" />
          <el-table-column prop="carrier" label="目标运营商" width="120" />
          <el-table-column prop="lineName" label="实际出口WAN" width="180" />
          <el-table-column label="上传流量" width="120">
            <template #default="{ row }">{{ formatBytes(row.uploadBytes) }}</template>
          </el-table-column>
          <el-table-column label="下载流量" width="120">
            <template #default="{ row }">{{ formatBytes(row.downloadBytes) }}</template>
          </el-table-column>
          <el-table-column label="连接时长" width="120">
            <template #default="{ row }">{{ formatDuration(row.durationSeconds) }}</template>
          </el-table-column>
          <el-table-column prop="startedAt" label="建立时间" width="170" fixed="right" />
        </StandardTable>
      </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import AnalyticsChart from '../../components/AnalyticsChart.vue'
import AnalyticsMetricGrid from '../../components/AnalyticsMetricGrid.vue'
import { flowTelemetryService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes, formatDuration } from '../../utils/trafficFormat.js'

const loading = ref(false)
const summary = ref({})
const rows = ref([])
const catalogRows = ref([])
const filters = reactive({
  ipVersion: 'all',
  province: 'all',
  carrier: 'all',
  lineId: 'all',
})

const provinceOptions = computed(() => [...new Set(catalogRows.value.map((item) => item.province))])
const carrierOptions = computed(() => [...new Set(catalogRows.value.map((item) => item.carrier))])
const lineOptions = computed(() => {
  const map = new Map(catalogRows.value.map((item) => [item.lineId, item.lineName]))
  return [...map.entries()].map(([lineId, lineName]) => ({ lineId, lineName }))
})

const metricItems = computed(() => [
  { label: '当前模拟连接', value: Number(summary.value.activeConnections || 0).toLocaleString(), tone: 'primary' },
  { label: 'IPv4连接', value: String(summary.value.ipv4Connections || 0) },
  { label: 'IPv6连接', value: String(summary.value.ipv6Connections || 0) },
  { label: '筛选结果', value: `${rows.value.length} 条` },
  { label: '采样上传流量', value: formatBytes(summary.value.uploadBytes), tone: 'success' },
  { label: '采样下载流量', value: formatBytes(summary.value.downloadBytes), tone: 'success' },
  { label: '平均连接时长', value: formatDuration(summary.value.averageDurationSeconds) },
])

const provinceOption = computed(() => {
  const counts = rows.value.reduce((result, item) => {
    result[item.province] = (result[item.province] || 0) + 1
    return result
  }, {})
  return {
    tooltip: { trigger: 'item', formatter: '{b}<br/>{c}条（{d}%）' },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie',
      radius: ['38%', '68%'],
      center: ['50%', '44%'],
      data: Object.entries(counts).map(([name, value]) => ({ name, value })),
    }],
  }
})

const protocolOption = computed(() => {
  const counts = rows.value.reduce((result, item) => {
    const key = `${item.protocol} / ${item.application}`
    result[key] = (result[key] || 0) + 1
    return result
  }, {})
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 10).reverse()
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { top: 12, left: 20, right: 20, bottom: 20, containLabel: true },
    xAxis: { type: 'value', name: '连接数' },
    yAxis: { type: 'category', data: sorted.map(([name]) => name) },
    series: [{ type: 'bar', data: sorted.map(([, value]) => value) }],
  }
})

async function loadRows() {
  loading.value = true
  try {
    const result = await flowTelemetryService.listActiveConnections(filters)
    rows.value = result.data
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  const [summaryResult, catalogResult] = await Promise.all([
    flowTelemetryService.getSummary(),
    flowTelemetryService.listActiveConnections(),
  ])
  summary.value = summaryResult.data
  catalogRows.value = catalogResult.data
  await loadRows()
})

watch(filters, loadRows, { deep: true })
</script>

<style scoped>
.filter-form {
  width: 100%;
}

.filter-form :deep(.el-select) {
  width: 180px;
}

.flow-table {
  --standard-table-scroll-width: 1880px;
}
</style>

