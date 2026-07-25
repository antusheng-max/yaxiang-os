<template>
  <el-card
    v-bind="$attrs"
    class="section-card"
    data-layout="section-card"
    :body-style="{ padding: '0' }"
  >
    <template v-if="$slots.header" #header>
      <CardHeader><slot name="header" /></CardHeader>
    </template>
    <CardContent :padding="contentPadding">
      <slot />
    </CardContent>
  </el-card>
</template>

<script setup>
import CardHeader from './CardHeader.vue'
import CardContent from './CardContent.vue'

defineOptions({ inheritAttrs: false })

defineProps({
  contentPadding: { type: String, default: 'standard' },
})
</script>

<style scoped>
.section-card {
  width: 100%;
  min-width: 0;
  margin: 0 0 var(--layout-section-gap);
  border-radius: var(--layout-radius);
}

.section-card.page-section-frame {
  margin: 0;
  border: 0;
  background: transparent;
  box-shadow: none;
}

.section-card :deep(.el-card__header) {
  width: 100%;
  min-width: 0;
  min-height: var(--layout-header-height);
  padding: 0 var(--layout-card-padding-x);
}

.section-card :deep(.el-card__body) {
  width: 100%;
  min-width: 0;
}
</style>
