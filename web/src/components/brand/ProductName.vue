<template>
  <span class="product-name">{{ text }}</span>
</template>

<script setup>
import { computed } from 'vue'
import BRAND from '../../config/brand.js'

const props = defineProps({
  variant: {
    type: String,
    default: 'brand',
    validator: (value) => [
      'brand',
      'product',
      'gateway',
      'installer',
      'console',
      'english',
      'shortEnglish',
      'installerEnglish',
    ].includes(value),
  },
})

const labels = {
  brand: BRAND.brandName,
  product: BRAND.productName,
  gateway: BRAND.gatewayName,
  installer: BRAND.installerName,
  console: BRAND.consoleName,
  english: BRAND.englishName,
  shortEnglish: BRAND.shortEnglishName,
  installerEnglish: BRAND.installerEnglishName,
}

const text = computed(() => labels[props.variant])
</script>

<style scoped>
.product-name {
  display: inline;
  font: inherit;
  color: inherit;
}
</style>
