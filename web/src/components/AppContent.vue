<template>
  <main class="app-content" data-layout="app-content">
    <slot />
  </main>
</template>

<style scoped>
.app-content {
  width: 100%;
  min-width: 0;
  height: calc(100vh - var(--layout-header-height));
  height: calc(100dvh - var(--layout-header-height));
  overflow-y: auto;
  overflow-x: hidden;
  background: var(--lh-bg);
}
</style>
