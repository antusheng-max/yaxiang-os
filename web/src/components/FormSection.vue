<template>
  <section class="form-section" data-layout="form-section">
    <header v-if="title || description" class="form-section__header">
      <h3 v-if="title">{{ title }}</h3>
      <p v-if="description">{{ description }}</p>
    </header>
    <slot />
  </section>
</template>

<script setup>
defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
})
</script>

<style scoped>
.form-section {
  width: 100%;
  min-width: 0;
  margin: 0 0 var(--layout-section-gap);
}

.form-section__header {
  margin: 0 0 var(--layout-section-gap);
}

.form-section__header h3,
.form-section__header p {
  margin: 0;
}
</style>
