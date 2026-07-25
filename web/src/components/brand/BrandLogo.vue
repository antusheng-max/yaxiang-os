<template>
  <span
    class="brand-logo"
    :class="[`mode-${mode}`, { inverse }]"
    :aria-label="accessibleLabel"
  >
    <BrandSymbol v-if="mode === 'symbol'" :size="symbolSize" :inverse="inverse" />
    <span v-else class="brand-copy">
      <ProductName :variant="mode === 'installer' ? 'installer' : 'brand'" class="brand-primary" />
      <ProductName
        v-if="mode === 'installer'"
        variant="installerEnglish"
        class="brand-secondary"
      />
    </span>
  </span>
</template>

<script setup>
import { computed } from 'vue'
import BRAND from '../../config/brand.js'
import BrandSymbol from './BrandSymbol.vue'
import ProductName from './ProductName.vue'

const props = defineProps({
  mode: {
    type: String,
    default: 'full',
    validator: (value) => ['full', 'symbol', 'installer'].includes(value),
  },
  inverse: { type: Boolean, default: false },
  symbolSize: { type: [Number, String], default: 32 },
})

const accessibleLabel = computed(() => (
  props.mode === 'installer' ? `${BRAND.installerName}，${BRAND.installerEnglishName}` : BRAND.brandName
))
</script>

<style scoped>
.brand-logo {
  display: inline-flex;
  align-items: center;
  min-width: 0;
  color: #14345c;
  line-height: 1;
}

.brand-logo.inverse {
  color: #fff;
}

.brand-copy {
  display: inline-flex;
  min-width: 0;
  flex-direction: column;
  justify-content: center;
  gap: 3px;
}

.brand-primary {
  font-size: 18px;
  font-weight: 750;
  letter-spacing: 0.04em;
  white-space: nowrap;
}

.brand-secondary {
  color: #74b9ff;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.12em;
  white-space: nowrap;
}

.mode-installer {
  align-items: center;
}

.mode-installer .brand-primary {
  font-size: 17px;
}

.mode-symbol {
  justify-content: center;
}
</style>
