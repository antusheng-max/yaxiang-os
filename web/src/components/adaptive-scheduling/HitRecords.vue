<template>
  <div>
    <AnalyticsMetricGrid :items="hitMetricItems" :column-span="6" />
    <SectionCard shadow="never">
      <template #header>最近规则命中</template>
      <StandardTable layout-mode="fill" :data="hitRecords" border stripe>
        <el-table-column prop="time" label="时间" min-width="95" />
        <el-table-column label="命中规则" min-width="180">
          <template #default="{ row }">{{ ruleLabel(row.ruleId) }}</template>
        </el-table-column>
        <el-table-column prop="ipVersion" label="IP版本" min-width="85" />
        <el-table-column prop="businessType" label="业务类型" min-width="110" />
        <el-table-column label="进入线路池" min-width="175">
          <template #default="{ row }">{{ poolLabel(row.poolId) }}</template>
        </el-table-column>
        <el-table-column label="选择线路" min-width="155">
          <template #default="{ row }">{{ lineLabel(row.lineId) }}</template>
        </el-table-column>
        <el-table-column label="流量" min-width="95" align="right">
          <template #default="{ row }">{{ formatBytes(row.bytes) }}</template>
        </el-table-column>
        <el-table-column prop="result" label="结果" min-width="160" />
      </StandardTable>
    </SectionCard>
    <SectionCard shadow="never">
      <template #header>规则修改记录</template>
      <StandardTable layout-mode="fill" :data="changeLogs" border stripe>
        <el-table-column prop="time" label="时间" min-width="150" />
        <el-table-column prop="ruleName" label="规则名称" min-width="190" />
        <el-table-column prop="action" label="操作" min-width="90" />
        <el-table-column prop="detail" label="说明" min-width="260" />
      </StandardTable>
    </SectionCard>
  </div>
</template>

<script setup>
import AnalyticsMetricGrid from '../AnalyticsMetricGrid.vue'
defineProps({
  hitMetricItems: { type: Array, required: true },
  hitRecords: { type: Array, required: true },
  changeLogs: { type: Array, required: true },
  ruleLabel: { type: Function, required: true },
  poolLabel: { type: Function, required: true },
  lineLabel: { type: Function, required: true },
  formatBytes: { type: Function, required: true },
})
</script>
