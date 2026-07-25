<template>
  <div class="crud-table">
    <CardToolbar v-if="title || hasAdd">
      <span class="crud-title">{{ title }}</span>
      <el-button v-if="hasAdd" type="primary" size="small" @click="openAdd">添加</el-button>
    </CardToolbar>
    <StandardTable :data="data" :layout-mode="layoutMode" border stripe size="small">
      <el-table-column
        v-for="col in resolvedColumns" :key="col.prop"
        :prop="col.prop"
        :label="col.label"
        :width="col.resolvedWidth"
        :min-width="col.resolvedMinWidth"
      >
        <template #default="{ row }">
          <template v-if="col.type === 'tag'">
            <el-tag :type="col.tagType ? col.tagType(row[col.prop]) : autoTagType(row[col.prop])" size="small">{{ row[col.prop] }}</el-tag>
          </template>
          <template v-else-if="col.type === 'switch'">
            <el-switch v-model="row[col.prop]" size="small" />
          </template>
          <template v-else-if="col.type === 'progress'">
            <el-progress :percentage="Number(row[col.prop]) || 0" :stroke-width="14" />
          </template>
          <template v-else>{{ row[col.prop] }}</template>
        </template>
      </el-table-column>
      <el-table-column v-if="showActions" label="操作" :width="actionWidth" fixed="right">
        <template #default="{ row }">
          <el-button v-if="hasEdit" size="small" type="primary" link @click="openEdit(row)">编辑</el-button>
          <el-button v-for="btn in extraButtons" :key="btn.label" size="small" :type="btn.type || 'primary'" link @click="btn.handler(row)">{{ btn.label }}</el-button>
          <el-button v-if="hasDelete" size="small" type="danger" link @click="removeRow(row)">删除</el-button>
        </template>
      </el-table-column>
    </StandardTable>

    <StandardModal v-model="dialogVisible" :title="dialogTitle" size="standard" @submit="save">
      <el-form :model="form" :label-width="isMobileDialog ? '100px' : '130px'">
        <el-form-item v-for="field in formFields" :key="field.prop" :label="field.label" :required="field.required">
          <el-select v-if="field.type === 'select'" v-model="form[field.prop]" style="width:100%">
            <el-option v-for="opt in field.options" :key="opt" :label="opt" :value="opt" />
          </el-select>
          <el-input v-else v-model="form[field.prop]" :placeholder="field.placeholder || ''" :type="field.type === 'textarea' ? 'textarea' : 'text'" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </StandardModal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import CardToolbar from './CardToolbar.vue'
import StandardTable from './StandardTable.vue'
import StandardModal from './StandardModal.vue'

const props = defineProps({
  title: { type: String, default: '' },
  columns: { type: Array, required: true },
  data: { type: Array, required: true },
  formFields: { type: Array, default: () => [] },
  extraButtons: { type: Array, default: () => [] },
  layoutMode: {
    type: String,
    default: 'fill',
    validator: (value) => ['fill', 'scroll'].includes(value),
  },
})

const emit = defineEmits(['add', 'edit', 'delete'])

const resolvedColumns = computed(() => {
  const columns = props.columns.map((column) => ({
    ...column,
    resolvedWidth: column.width,
    resolvedMinWidth: column.minWidth,
  }))

  if (props.layoutMode !== 'fill' || !columns.length) return columns

  const existingFlexibleColumn = columns.find((column) => (
    column.width == null
    && column.fixed == null
  ))
  if (existingFlexibleColumn) return columns

  const explicitFlexibleIndex = columns.findIndex((column) => column.flex === true)
  const fallbackFlexibleIndex = columns.findIndex((column) => (
    column.flex !== false
    && column.fixed == null
    && column.type !== 'tag'
    && column.type !== 'switch'
    && column.type !== 'progress'
  ))
  const flexibleIndex = explicitFlexibleIndex >= 0
    ? explicitFlexibleIndex
    : Math.max(fallbackFlexibleIndex, 0)
  const flexibleColumn = columns[flexibleIndex]

  flexibleColumn.resolvedWidth = undefined
  flexibleColumn.resolvedMinWidth = flexibleColumn.minWidth
    ?? flexibleColumn.width
    ?? 160

  return columns
})

const hasAdd = computed(() => props.formFields.length > 0)
const hasEdit = computed(() => props.formFields.length > 0)
const hasDelete = computed(() => props.formFields.length > 0)
const showActions = computed(() => hasEdit.value || hasDelete.value || props.extraButtons.length > 0)

const actionWidth = computed(() => {
  let w = 0
  if (hasEdit.value) w += 55
  if (hasDelete.value) w += 55
  w += props.extraButtons.length * 55
  return Math.min(Math.max(w, 140), 160)
})

const windowWidth = ref(window.innerWidth)
function onResize() { windowWidth.value = window.innerWidth }
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))
const isMobileDialog = computed(() => windowWidth.value < 500)
const dialogVisible = ref(false)
const isEdit = ref(false)
let editRow = null

const dialogTitle = computed(() => (isEdit.value ? '编辑' : '添加') + (props.title ? ' - ' + props.title : ''))
const form = reactive({})

function autoTagType(val) {
  if (['ACCEPT', '在线', '已连接', '运行中', '正常', '健康', '活跃', '已生效', '是', '启用', 'UP', '已挂载', '已分配', '就绪'].includes(val)) return 'success'
  if (['REJECT', 'DROP', '离线', '断开', '已停止', '失败', '故障', '禁用', 'DOWN', '否', '未连接', '未启动', '未安装'].includes(val)) return 'danger'
  if (['备用', '拨号中', '警告', '检测中'].includes(val)) return 'warning'
  return 'info'
}

function openAdd() {
  isEdit.value = false
  editRow = null
  Object.keys(form).forEach(k => delete form[k])
  props.formFields.forEach(f => { form[f.prop] = '' })
  dialogVisible.value = true
}

function openEdit(row) {
  isEdit.value = true
  editRow = row
  Object.keys(form).forEach(k => delete form[k])
  props.formFields.forEach(f => { form[f.prop] = row[f.prop] ?? '' })
  dialogVisible.value = true
}

function save() {
  const formData = { ...form }
  if (isEdit.value) {
    emit('edit', editRow, formData)
  } else {
    emit('add', formData)
  }
  dialogVisible.value = false
}

function removeRow(row) {
  ElMessageBox.confirm('确认删除该条目？', '删除确认', { type: 'warning' })
    .then(() => emit('delete', row))
    .catch(() => {})
}
</script>

<style scoped>
.crud-table { width: 100%; min-width: 0; }
.crud-title { font-size: 15px; font-weight: 600; }
</style>
