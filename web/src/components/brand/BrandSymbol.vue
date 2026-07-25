<template>
  <img
    v-if="useImage"
    :src="BRAND.assets.symbol"
    :alt="decorative ? undefined : `${BRAND.brandName}Logo`"
    :aria-hidden="decorative ? 'true' : undefined"
    class="brand-symbol-img"
    :style="imgStyle"
    @error="onImageError"
  />
  <span
    v-else
    class="brand-symbol"
    :class="{ inverse }"
    :style="symbolStyle"
    :aria-label="decorative ? undefined : `${BRAND.brandName}字标`"
    :aria-hidden="decorative ? 'true' : undefined"
  >{{ fallbackText }}</span>
</template>

<script setup>
import { computed, ref } from 'vue'
import BRAND from '../../config/brand.js'

const props = defineProps({
  size: { type: [Number, String], default: 32 },
  inverse: { type: Boolean, default: false },
  decorative: { type: Boolean, default: true },
})

const useImage = ref(true)
const fallbackText = ref('亚')

const dimension = computed(() => (
  typeof props.size === 'number' || /^\d+$/.test(String(props.size))
    ? `${props.size}px`
    : String(props.size)
))

const imgStyle = computed(() => ({
  width: dimension.value,
  height: dimension.value,
  display: 'inline-block',
  objectFit: 'contain',
}))

const symbolStyle = computed(() => ({
  width: dimension.value,
  height: dimension.value,
  fontSize: dimension.value,
}))

function onImageError() {
  useImage.value = false
}
</script>

<style scoped>
.brand-symbol-img {
  flex: 0 0 auto;
  vertical-align: middle;
}

.brand-symbol {
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  color: #1677ff;
  font-family: "Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", sans-serif;
  font-weight: 800;
  line-height: 1;
}

.brand-symbol.inverse {
  color: #fff;
}
</style>
