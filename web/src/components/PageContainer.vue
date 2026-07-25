<template>
  <div class="page-container">
    <div class="page-container__content" data-layout="page-container">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.page-container {
  width: 100%;
  min-width: 0;
  padding:
    var(--layout-page-padding-top)
    var(--layout-page-padding-x)
    var(--layout-page-padding-bottom);
  margin: 0;
}

.page-container__content {
  width: 100%;
  min-width: 0;
  margin: 0;
}
</style>
