<template>
  <div>
    <el-alert type="success" show-icon :closable="false" title="亚象以寻找线路实际极限为目标。套餐标称速率只是探测起点；当运营商线路存在额外余量或突发额度时，系统会继续加压并尝试突破标称上行。" style="margin-bottom: 16px" />
    <el-alert type="info" show-icon :closable="false" title="系统无法绕过运营商的硬限速，但会自动发现并使用运营商实际允许的全部容量。" style="margin-bottom: 16px" />
    <AnalyticsMetricGrid :items="probeSummaryMetrics" :column-span="6" />
    <SectionCard shadow="never">
      <template #header><HeaderHelp label="极限探测线路状态" text="标称突破率 = 持续极限 / 套餐标称上行 * 100%。超过100%表示已突破标称速率。" /></template>
      <StandardTable layout-mode="scroll" :data="probeLines" border stripe>
        <el-table-column prop="lineName" label="线路名称" min-width="120" fixed="left" />
        <el-table-column label="协议" width="70"><template #default="{ row }">{{ row.ipFamily === 'ipv4' ? 'IPv4' : 'IPv6' }}</template></el-table-column>
        <el-table-column label="探测状态" width="120"><template #default="{ row }"><el-tag :type="probeStageTagType(row.probeStage)" effect="light" size="small">{{ row.probeStageLabel }}</el-tag></template></el-table-column>
        <el-table-column label="套餐标称" width="90" align="right"><template #default="{ row }">{{ row.advertisedUploadMbps }} Mbps</template></el-table-column>
        <el-table-column label="持续极限" width="100" align="right"><template #default="{ row }"><span style="color: #67c23a; font-weight: 600">{{ row.sustainedMaximumMbps }} Mbps</span></template></el-table-column>
        <el-table-column label="有效上传" width="100" align="right"><template #default="{ row }"><span style="color: #1677ff; font-weight: 600">{{ row.currentEffectiveUploadMbps }} Mbps</span></template></el-table-column>
        <el-table-column label="突破率" width="90" align="center"><template #default="{ row }"><span :style="{ color: row.advertisedBreakthroughPercent > 100 ? '#67c23a' : '#1677ff', fontWeight: 700 }">{{ row.advertisedBreakthroughPercent }}%</span></template></el-table-column>
        <el-table-column label="评分" width="70" align="right"><template #default="{ row }">{{ row.score }}</template></el-table-column>
        <el-table-column label="调整原因" min-width="180"><template #default="{ row }">{{ row.adjustmentReason }}</template></el-table-column>
      </StandardTable>
    </SectionCard>
  </div>
</template>

<script setup>
import AnalyticsMetricGrid from '../AnalyticsMetricGrid.vue'
defineProps({
  probeLines: { type: Array, required: true },
  probeSummaryMetrics: { type: Array, required: true },
  probeStageTagType: { type: Function, required: true },
})
</script>
