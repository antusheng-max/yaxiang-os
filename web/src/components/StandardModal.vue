<template>
  <el-dialog
    v-model="model"
    v-bind="$attrs"
    :title="title"
    :width="dialogWidth"
    :fullscreen="isMobile"
    top="5vh"
    destroy-on-close
    :close-on-click-modal="false"
    class="standard-modal"
    :class="'modal-' + size"
    data-layout="standard-modal"
  >
    <div class="modal-body">
      <slot />
    </div>
    <template #footer>
      <div class="modal-footer">
        <slot name="footer">
          <el-button @click="cancel">取消</el-button>
          <el-button type="primary" :disabled="submitDisabled" @click="submit">确定</el-button>
        </slot>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

defineOptions({ inheritAttrs: false })

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: '' },
  size: { type: String, default: 'standard', validator: v => ['small','standard','large','full'].includes(v) },
  submitDisabled: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue', 'submit', 'cancel'])

const model = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v)
})

function submit() { emit('submit') }
function cancel() { emit('cancel'); model.value = false }

const windowWidth = ref(window.innerWidth)
function onResize() { windowWidth.value = window.innerWidth }
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))
const isMobile = computed(() => windowWidth.value < 600)

const sizeMap = {
  small: 'var(--layout-modal-small)',
  standard: 'var(--layout-modal-standard)',
  large: 'var(--layout-modal-large)',
  full: 'min(calc(100vw - 96px), var(--layout-modal-full))',
}
const dialogWidth = computed(() => sizeMap[props.size] || sizeMap.standard)
</script>

<style scoped>
.standard-modal .modal-body {
  width: 100%;
  min-width: 0;
  padding: 0;
  max-height: calc(100vh - 200px);
  overflow-y: auto;
}
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>

<style>
.standard-modal .el-dialog__header {
  min-height: var(--layout-header-height);
  display: flex;
  align-items: center;
  padding: 0 var(--layout-card-padding-x);
  margin: 0;
  border-bottom: 1px solid var(--lh-border);
}
.standard-modal .el-dialog__body {
  width: 100%;
  min-width: 0;
  padding:
    var(--layout-card-padding-y)
    var(--layout-card-padding-x);
}
.standard-modal .el-dialog__footer {
  min-height: var(--layout-toolbar-height);
  display: flex;
  align-items: center;
  padding: 0 var(--layout-card-padding-x);
  border-top: 1px solid var(--lh-border);
}
.standard-modal .el-form-item {
  margin-bottom: 16px;
}
.standard-modal .el-form-item__label {
  width: 120px;
}
.standard-modal .el-input, .standard-modal .el-select {
  width: 100%;
}
</style>
