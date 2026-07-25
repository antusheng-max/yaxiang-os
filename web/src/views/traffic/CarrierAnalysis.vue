<template>
  <PageContainer>
    <PageHeader
      title="运营商分析"
      description="按目标IP运营商与实际出口WAN运营商判断本网和跨网流量"
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
      <AnalyticsMetricGrid :items="metricItems" :column-span="6" />

      <el-row :gutter="16">
        <el-col :xs="24" :lg="16">
          <SectionCard shadow="never">
            <template #header>各运营商流量排名</template>
            <AnalyticsChart :option="rankingOption" :height="340" />
          </SectionCard>
        </el-col>
        <el-col :xs="24" :lg="8">
          <SectionCard shadow="never">
            <template #header>本网与跨网比例</template>
            <AnalyticsChart :option="onNetOption" :height="340" />
          </SectionCard>
        </el-col>
      </el-row>

      <SectionCard shadow="never">
        <template #header>各WAN本网、跨网及跨运营商质量</template>
        <StandardTable
          layout-mode="scroll"
          class="carrier-wan-table"
          :data="analysis.wanRows || []"
          border
          stripe
        >
          <el-table-column prop="lineName" label="WAN线路" width="180" fixed="left" />
          <el-table-column prop="carrier" label="出口运营商" width="120" />
          <el-table-column label="本网流量" width="140">
            <template #default="{ row }">{{ formatBytes(row.onNetBytes) }}</template>
          </el-table-column>
          <el-table-column label="跨网流量" width="140">
            <template #default="{ row }">{{ formatBytes(row.crossNetBytes) }}</template>
          </el-table-column>
          <el-table-column label="本网率" width="100">
            <template #default="{ row }">{{ formatPercent(row.onNetRate) }}</template>
          </el-table-column>
          <el-table-column label="IPv4流量" width="140">
            <template #default="{ row }">{{ formatBytes(row.ipv4Bytes) }}</template>
          </el-table-column>
          <el-table-column label="IPv6流量" width="140">
            <template #default="{ row }">{{ formatBytes(row.ipv6Bytes) }}</template>
          </el-table-column>
          <el-table-column label="访问不同运营商的平均延迟 / 丢包" min-width="720">
            <template #default="{ row }">
              <div class="peer-metrics">
                <span v-for="peer in row.peerMetrics" :key="peer.carrier" class="peer-metric">
                  <strong>{{ peer.carrier }}</strong>
                  {{ peer.latencyMs }}ms / {{ peer.packetLossPercent }}%
                </span>
              </div>
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
import { carrierTrafficService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes, formatPercent } from '../../utils/trafficFormat.js'

const loading = ref(false)
const protocol = ref('all')
const analysis = ref({ ranking: [], wanRows: [] })

const metricItems = computed(() => [
  { label: '本网流量', value: formatBytes(analysis.value.onNetBytes), tone: 'success' },
  { label: '跨网流量', value: formatBytes(analysis.value.crossNetBytes), tone: 'warning' },
  { label: '本网率', value: formatPercent(analysis.value.onNetRate), tone: 'primary' },
  { label: '出口WAN数量', value: String(analysis.value.wanRows?.length || 0) },
])

const rankingOption = computed(() => {
  const rows = [...(analysis.value.ranking || [])].reverse()
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { top: 16, left: 20, right: 24, bottom: 24, containLabel: true },
    xAxis: { type: 'value', name: 'TB' },
    yAxis: { type: 'category', data: rows.map((item) => item.carrier) },
    series: [{
      name: '总流量',
      type: 'bar',
      data: rows.map((item) => Number((item.totalBytes / 1024 ** 4).toFixed(3))),
      itemStyle: {
        color: (params) => params.dataIndex === rows.length - 1 ? '#1677ff' : '#73a8e8',
      },
    }],
  }
})

const onNetOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}<br/>{d}%' },
  legend: { bottom: 0 },
  series: [{
    type: 'pie',
    radius: ['46%', '72%'],
    center: ['50%', '45%'],
    label: { formatter: '{b}\n{d}%' },
    data: [
      { name: '本网流量', value: analysis.value.onNetBytes || 0 },
      { name: '跨网流量', value: analysis.value.crossNetBytes || 0 },
    ],
  }],
}))

async function loadData() {
  loading.value = true
  try {
    const result = await carrierTrafficService.getAnalysis({ protocol: protocol.value, window: '24h' })
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

.carrier-wan-table {
  --standard-table-scroll-width: 1680px;
}

.peer-metrics {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 12px;
}

.peer-metric {
  color: var(--lh-text-secondary);
  font-size: 12px;
  white-space: nowrap;
}

.peer-metric strong {
  color: var(--lh-text);
}
</style>

