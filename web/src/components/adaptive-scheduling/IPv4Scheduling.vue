<template>
  <SectionCard shadow="never">
    <template #header>IPv4独立调度状态</template>
    <ProtocolSchedulingTable protocol-label="IPv4" :rows="ipv4Rows" :thresholds="thresholds" />
  </SectionCard>
</template>

<script setup>
import ProtocolSchedulingTable from '../scheduling/ProtocolSchedulingTable.vue'
defineProps({ ipv4Rows: { type: Array, required: true }, thresholds: { type: Object, required: true } })
</script>
