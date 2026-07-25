<template>
  <div
    class="card-content"
    :class="{ 'card-content--flush': padding === 'none' }"
  >
    <div class="card-content__inner" data-layout="card-content">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({
  padding: { type: String, default: 'standard' },
})
</script>

<style scoped>
.card-content {
  width: 100%;
  min-width: 0;
  padding:
    var(--layout-card-padding-y)
    var(--layout-card-padding-x);
}

.card-content--flush {
  padding: 0;
}

.card-content__inner {
  width: 100%;
  min-width: 0;
}
</style>
