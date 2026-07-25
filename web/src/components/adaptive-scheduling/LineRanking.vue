<template>
  <SectionCard shadow="never">
    <template #header>
      <HeaderHelp label="线路能力自动识别结果" text="调度资格来自实际参数、互联网连通性、健康检查、公网可达性和回程路径验证。" />
    </template>
    <StandardTable layout-mode="scroll" :data="capabilityRows" border stripe class="capability-table">
      <el-table-column prop="lineName" label="线路名称" min-width="155" fixed="left" />
      <el-table-column prop="carrier" label="运营商" min-width="100" />
      <el-table-column label="接入方式" min-width="145">
        <template #default="{ row }">
          <div>{{ row.accessMeta.shortLabel }}</div>
          <small>{{ row.physicalPort }}<template v-if="row.vlanId"> · VLAN {{ row.vlanId }}</template></small>
        </template>
      </el-table-column>
      <el-table-column label="IPv4资格" min-width="110">
        <template #default="{ row }">
          <el-tag :type="row.ipv4SchedulingEligible ? 'success' : 'danger'" size="small">
            {{ row.ipv4SchedulingEligible ? '可参与调度' : '暂不参与' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="IPv6能力" min-width="170">
        <template #default="{ row }">
          <el-tag :type="row.ipv6Meta.tagType" size="small">{{ row.ipv6Meta.label }}</el-tag>
          <small>{{ row.ipv6Meta.explanation }}</small>
        </template>
      </el-table-column>
      <el-table-column label="IPv6资格" min-width="110">
        <template #default="{ row }">
          <el-tag :type="row.ipv6SchedulingEligible ? 'success' : 'danger'" size="small">
            {{ row.ipv6SchedulingEligible ? '可参与调度' : '暂不参与' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="出站资格" min-width="110">
        <template #default="{ row }">IPv4 {{ yesNo(row.cdnIpv4OutboundEligible) }} / IPv6 {{ yesNo(row.cdnIpv6OutboundEligible) }}</template>
      </el-table-column>
      <el-table-column label="入站资格" min-width="110">
        <template #default="{ row }">IPv4 {{ yesNo(row.cdnIpv4InboundEligible) }} / IPv6 {{ yesNo(row.cdnIpv6InboundEligible) }}</template>
      </el-table-column>
      <el-table-column label="质量评分" min-width="90" align="center">
        <template #default="{ row }">{{ row.qualityScore.toFixed(1) }}</template>
      </el-table-column>
      <el-table-column label="操作" min-width="105" fixed="right">
        <template #default="{ row }">
          <el-button type="primary" link @click="$emit('openCapability', row)">能力详情</el-button>
        </template>
      </el-table-column>
    </StandardTable>
  </SectionCard>
</template>

<script setup>
defineProps({
  capabilityRows: { type: Array, required: true },
  yesNo: { type: Function, required: true },
})
defineEmits(['openCapability'])
</script>
