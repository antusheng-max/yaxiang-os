<template>
  <el-row :gutter="16" class="analytics-metric-grid">
    <el-col
      v-for="item in items"
      :key="item.label"
      :xs="12"
      :sm="8"
      :md="columnSpan"
    >
      <SectionCard shadow="never" class="analytics-metric-card">
        <div class="analytics-metric-label">{{ item.label }}</div>
        <div class="analytics-metric-value" :class="item.tone ? `is-${item.tone}` : ''">
          {{ item.value }}
        </div>
        <div v-if="item.hint" class="analytics-metric-hint">{{ item.hint }}</div>
      </SectionCard>
    </el-col>
  </el-row>
</template>

<script setup>
defineProps({
  items: { type: Array, default: () => [] },
  columnSpan: { type: Number, default: 4 },
})
</script>

<style scoped>
.analytics-metric-grid {
  width: 100%;
}

.analytics-metric-card {
  height: calc(100% - var(--layout-section-gap));
}

.analytics-metric-label {
  color: var(--lh-text-secondary);
  font-size: 12px;
  line-height: 20px;
}

.analytics-metric-value {
  margin-top: 4px;
  color: var(--lh-text);
  font-size: 22px;
  font-weight: 700;
  line-height: 30px;
}

.analytics-metric-value.is-primary { color: var(--lh-primary); }
.analytics-metric-value.is-success { color: #67c23a; }
.analytics-metric-value.is-warning { color: #e6a23c; }
.analytics-metric-value.is-danger { color: #f56c6c; }

.analytics-metric-hint {
  margin-top: 4px;
  color: #909399;
  font-size: 12px;
}
</style>

