<template>
  <div v-loading="loading" class="loading-state" data-layout="loading-state">
    <slot />
  </div>
</template>

<script setup>
defineProps({
  loading: { type: Boolean, default: false },
})
</script>

<style scoped>
.loading-state {
  width: 100%;
  min-width: 0;
  min-height: 120px;
}
</style>
