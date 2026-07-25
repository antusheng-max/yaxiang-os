<template>
  <el-drawer
    v-model="model"
    v-bind="$attrs"
    :size="drawerSize"
    class="standard-drawer"
    data-layout="standard-drawer"
  >
    <slot />
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
  </el-drawer>
</template>

<script setup>
import { computed } from 'vue'

defineOptions({ inheritAttrs: false })

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  size: { type: String, default: 'standard' },
})
const emit = defineEmits(['update:modelValue'])

const model = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value),
})

const sizes = {
  small: 'var(--layout-modal-small)',
  standard: 'var(--layout-modal-standard)',
  large: 'var(--layout-modal-large)',
  full: 'min(100vw, var(--layout-modal-full))',
}
const drawerSize = computed(() => sizes[props.size] || sizes.standard)
</script>
