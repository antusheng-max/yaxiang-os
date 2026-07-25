<template>
  <SectionCard shadow="never">
    <template #header>探测调整记录</template>
    <StandardTable layout-mode="scroll" :data="probeHistory" border stripe>
      <el-table-column prop="time" label="时间" width="170" fixed="left" />
      <el-table-column prop="lineName" label="线路" min-width="120" />
      <el-table-column label="协议" width="70">
        <template #default="{ row }">{{ row.ipFamily === 'ipv4' ? 'IPv4' : 'IPv6' }}</template>
      </el-table-column>
      <el-table-column label="修改前目标" width="110" align="right">
        <template #default="{ row }">{{ row.targetBefore }} Mbps</template>
      </el-table-column>
      <el-table-column label="修改后目标" width="110" align="right">
        <template #default="{ row }">
          <span :style="{ color: row.targetAfter > row.targetBefore ? '#67c23a' : row.targetAfter < row.targetBefore ? '#f56c6c' : '#909399' }">
            {{ row.targetAfter }} Mbps
          </span>
        </template>
      </el-table-column>
      <el-table-column label="修改前权重" width="100" align="center">
        <template #default="{ row }">{{ row.weightBefore }}</template>
      </el-table-column>
      <el-table-column label="修改后权重" width="100" align="center">
        <template #default="{ row }">{{ row.weightAfter }}</template>
      </el-table-column>
      <el-table-column label="突破率" width="80" align="center">
        <template #default="{ row }">{{ row.breakthroughPercent }}%</template>
      </el-table-column>
      <el-table-column label="调整原因" min-width="200">
        <template #default="{ row }">{{ row.reason }}</template>
      </el-table-column>
      <el-table-column label="触发指标" min-width="200">
        <template #default="{ row }"><code style="font-size: 12px; color: var(--el-text-color-secondary)">{{ row.triggerMetrics }}</code></template>
      </el-table-column>
      <el-table-column label="调整结果" min-width="200">
        <template #default="{ row }">{{ row.result }}</template>
      </el-table-column>
    </StandardTable>
  </SectionCard>
</template>

<script setup>
defineProps({ probeHistory: { type: Array, required: true } })
</script>
