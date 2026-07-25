<template>
  <header class="page-header" data-layout="page-header">
    <div class="page-header__content">
      <slot>
        <h2 v-if="title">{{ title }}</h2>
        <p v-if="description">{{ description }}</p>
      </slot>
    </div>
    <div v-if="$slots.actions" class="page-header__actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<script setup>
defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
})
</script>

<style scoped>
.page-header {
  width: 100%;
  min-width: 0;
  min-height: var(--layout-header-height);
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 16px;
  margin: 0 0 var(--layout-section-gap);
}

.page-header__content {
  min-width: 0;
}

.page-header__actions {
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}

.page-header :deep(h1),
.page-header :deep(h2) {
  margin: 0;
  font-size: 20px;
  line-height: 28px;
  font-weight: 600;
  color: var(--lh-text);
}

.page-header :deep(p) {
  margin: 4px 0 0;
  font-size: 13px;
  line-height: 20px;
  color: var(--lh-text-secondary);
}

.page-header :deep(.header-actions),
.page-header :deep(.page-actions) {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}
</style>
