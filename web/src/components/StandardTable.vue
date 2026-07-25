<template>
  <div
    class="standard-table"
    :class="`standard-table--${layoutMode}`"
    :data-layout-mode="layoutMode"
    data-layout="standard-table"
  >
    <div class="standard-table__viewport">
      <el-table
        v-bind="$attrs"
        :table-layout="layoutMode === 'fill' ? 'fixed' : 'auto'"
        style="width: 100%"
      >
        <slot />
      </el-table>
    </div>
  </div>
</template>

<script setup>
defineOptions({ inheritAttrs: false })

defineProps({
  layoutMode: {
    type: String,
    default: 'fill',
    validator: (value) => ['fill', 'scroll'].includes(value),
  },
})
</script>

<style scoped>
.standard-table,
.standard-table__viewport,
.standard-table :deep(.el-table),
.standard-table :deep(.el-table__inner-wrapper),
.standard-table :deep(.el-table__header-wrapper),
.standard-table :deep(.el-table__body-wrapper),
.standard-table :deep(.el-scrollbar),
.standard-table :deep(.el-scrollbar__wrap),
.standard-table :deep(.el-scrollbar__view) {
  width: 100%;
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
}

.standard-table--fill .standard-table__viewport {
  overflow-x: hidden;
}

.standard-table--scroll .standard-table__viewport {
  overflow-x: auto;
}

.standard-table--scroll :deep(.el-table) {
  min-width: var(--standard-table-scroll-width, 1200px);
}
</style>
