<template>
  <SectionCard shadow="never">
    <template #header>IPv6独立调度状态</template>
    <ProtocolSchedulingTable protocol-label="IPv6" :rows="ipv6Rows" :thresholds="thresholds" />
  </SectionCard>
</template>

<script setup>
import ProtocolSchedulingTable from '../scheduling/ProtocolSchedulingTable.vue'
defineProps({ ipv6Rows: { type: Array, required: true }, thresholds: { type: Object, required: true } })
</script>
