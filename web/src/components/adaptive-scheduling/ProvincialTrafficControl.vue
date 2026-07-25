<template>
  <div>
    <el-alert type="info" show-icon :closable="false" title="出省率依据IP归属数据库估算，可能与运营商内部省际出口统计存在差异。" style="margin-bottom: 16px" />
    <el-alert type="warning" show-icon :closable="false" title="路由系统只能控制现有连接的接受、限制和线路分配，不能将外省客户端转换为本省客户端。" style="margin-bottom: 16px" />
    <AnalyticsMetricGrid :items="provincialMetrics" :column-span="6" />
    <SectionCard shadow="never">
      <template #header><HeaderHelp label="本网控制配置" text="设置本地省份、运营商和目标出省率。" /></template>
      <el-row :gutter="16">
        <el-col :span="6"><el-form-item label="本地省份"><el-input v-model="provincialConfig.localProvince" style="width: 100%" /></el-form-item></el-col>
        <el-col :span="6"><el-form-item label="本地运营商"><el-select v-model="provincialConfig.localCarrier" style="width: 100%"><el-option v-for="c in carrierOptions" :key="c.value" :label="c.label" :value="c.value" /></el-select></el-form-item></el-col>
        <el-col :span="6"><el-form-item label="目标出省率"><el-input-number v-model="provincialConfig.targetCrossProvinceRate" :min="0" :max="100" :step="5" style="width: 100%" /></el-form-item></el-col>
        <el-col :span="6"><el-form-item label="硬上限"><el-input-number v-model="provincialConfig.hardLimitRate" :min="0" :max="100" :step="5" style="width: 100%" /></el-form-item></el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="8"><el-form-item label="控制模式"><el-select v-model="provincialConfig.controlMode" style="width: 100%"><el-option v-for="m in controlModeOptions" :key="m.value" :label="m.label" :value="m.value" /></el-select></el-form-item></el-col>
        <el-col :span="4"><el-form-item label="IPv4"><el-switch v-model="provincialConfig.ipv4Enabled" /></el-form-item></el-col>
        <el-col :span="4"><el-form-item label="IPv6"><el-switch v-model="provincialConfig.ipv6Enabled" /></el-form-item></el-col>
        <el-col :span="8"><el-form-item label="统计窗口"><el-select v-model="provincialConfig.statsTimeWindow" style="width: 100%"><el-option label="实时（1分钟）" :value="60" /><el-option label="控制（5分钟）" :value="300" /><el-option label="趋势（1小时）" :value="3600" /></el-select></el-form-item></el-col>
      </el-row>
    </SectionCard>
    <SectionCard shadow="never">
      <template #header><HeaderHelp label="IPv4 和 IPv6 独立分类统计" text="IPv4和IPv6分别统计同省同网、同省异网、跨省同网、跨省异网和未知流量。" /></template>
      <el-row :gutter="16">
        <el-col :span="12">
          <h4 style="margin: 0 0 8px">IPv4 分类</h4>
          <StandardTable layout-mode="scroll" :data="ipv4Classification" border stripe size="small">
            <el-table-column prop="categoryLabel" label="分类" min-width="100" />
            <el-table-column label="有效流量" min-width="120" align="right"><template #default="{ row }">{{ formatBytes(row.bytes) }}</template></el-table-column>
            <el-table-column label="占比" width="80" align="right"><template #default="{ row }">{{ row.ratio }}%</template></el-table-column>
          </StandardTable>
        </el-col>
        <el-col :span="12">
          <h4 style="margin: 0 0 8px">IPv6 分类</h4>
          <StandardTable layout-mode="scroll" :data="ipv6Classification" border stripe size="small">
            <el-table-column prop="categoryLabel" label="分类" min-width="100" />
            <el-table-column label="有效流量" min-width="120" align="right"><template #default="{ row }">{{ formatBytes(row.bytes) }}</template></el-table-column>
            <el-table-column label="占比" width="80" align="right"><template #default="{ row }">{{ row.ratio }}%</template></el-table-column>
          </StandardTable>
        </el-col>
      </el-row>
    </SectionCard>
    <SectionCard shadow="never">
      <template #header>线路出省率明细</template>
      <StandardTable layout-mode="scroll" :data="provincialLineDetails" border stripe>
        <el-table-column prop="lineName" label="线路名称" min-width="120" fixed="left" />
        <el-table-column label="IPv4出省率" width="100" align="center"><template #default="{ row }"><span :style="{ color: row.ipv4CrossProvinceRate > provincialConfig.targetCrossProvinceRate ? '#f56c6c' : '#606266' }">{{ row.ipv4CrossProvinceRate }}%</span></template></el-table-column>
        <el-table-column label="IPv6出省率" width="100" align="center"><template #default="{ row }"><span :style="{ color: row.ipv6CrossProvinceRate > provincialConfig.targetCrossProvinceRate ? '#f56c6c' : '#606266' }">{{ row.ipv6CrossProvinceRate }}%</span></template></el-table-column>
        <el-table-column label="控制动作" width="140"><template #default="{ row }"><el-tag :type="row.controlAction === 'none' ? 'success' : 'warning'" effect="light" size="small">{{ row.controlActionLabel }}</el-tag></template></el-table-column>
        <el-table-column label="调整原因" min-width="160"><template #default="{ row }">{{ row.adjustmentReason }}</template></el-table-column>
      </StandardTable>
    </SectionCard>
  </div>
</template>

<script setup>
import AnalyticsMetricGrid from '../AnalyticsMetricGrid.vue'
const props = defineProps({
  provincialConfig: { type: Object, required: true },
  provincialMetrics: { type: Array, required: true },
  carrierOptions: { type: Array, required: true },
  controlModeOptions: { type: Array, required: true },
  ipv4Classification: { type: Array, required: true },
  ipv6Classification: { type: Array, required: true },
  provincialLineDetails: { type: Array, required: true },
  formatBytes: { type: Function, required: true },
})
const { provincialConfig } = props
</script>
