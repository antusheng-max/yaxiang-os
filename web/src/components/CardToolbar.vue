<template>
  <div class="card-toolbar" data-layout="toolbar">
    <slot />
  </div>
</template>

<style scoped>
.card-toolbar {
  width: 100%;
  min-width: 0;
  min-height: var(--layout-toolbar-height);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 var(--layout-section-gap);
}
</style>
