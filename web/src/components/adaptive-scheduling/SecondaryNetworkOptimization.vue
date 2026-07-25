<template>
  <div>
    <el-alert type="success" show-icon :closable="false" title="次网络优化使用更激进的加压策略，允许更高队列延迟和一定程度的丢包重传，优先追求历史最高有效上传。" style="margin-bottom: 16px" />
    <el-alert type="warning" show-icon :closable="false" title="只有在有效吞吐停止增长或下降时才明显回退。延迟和稳定性是约束指标，不再是首要目标。" style="margin-bottom: 16px" />
    <AnalyticsMetricGrid :items="subProbeSummaryMetrics" :column-span="6" />
    <SectionCard shadow="never">
      <template #header>次网络优化线路排名（按突破贡献排序）</template>
      <StandardTable layout-mode="scroll" :data="subProbeRanking" border stripe>
        <el-table-column type="index" label="排名" width="60" align="center" />
        <el-table-column prop="lineName" label="线路名称" min-width="120" />
        <el-table-column label="协议" width="70"><template #default="{ row }">{{ row.ipFamily === 'ipv4' ? 'IPv4' : 'IPv6' }}</template></el-table-column>
        <el-table-column label="持续极限" width="100" align="right"><template #default="{ row }">{{ row.sustainedMaximumMbps }} Mbps</template></el-table-column>
        <el-table-column label="突破率" width="90" align="center"><template #default="{ row }"><span :style="{ color: row.breakthroughPercent > 100 ? '#67c23a' : '#909399', fontWeight: 700 }">{{ row.breakthroughPercent }}%</span></template></el-table-column>
        <el-table-column label="突破贡献" width="100" align="right"><template #default="{ row }"><span :style="{ color: row.contribution > 0 ? '#67c23a' : '#909399' }">{{ row.contribution > 0 ? '+' : '' }}{{ row.contribution }} Mbps</span></template></el-table-column>
        <el-table-column label="当前有效" width="100" align="right"><template #default="{ row }">{{ row.currentEffectiveUploadMbps }} Mbps</template></el-table-column>
      </StandardTable>
    </SectionCard>
  </div>
</template>

<script setup>
import AnalyticsMetricGrid from '../AnalyticsMetricGrid.vue'
defineProps({
  subProbeSummaryMetrics: { type: Array, required: true },
  subProbeRanking: { type: Array, required: true },
})
</script>
