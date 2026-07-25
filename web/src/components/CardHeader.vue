<template>
  <div class="card-header" data-layout="card-header">
    <div class="card-header__content"><slot /></div>
    <div v-if="$slots.actions" class="card-header__actions"><slot name="actions" /></div>
  </div>
</template>

<style scoped>
.card-header {
  width: 100%;
  min-width: 0;
  min-height: var(--layout-header-height);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.card-header__content {
  min-width: 0;
  font-weight: 600;
}

.card-header__actions {
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}
</style>
