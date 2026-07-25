<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>调度策略</h2>
      <p>定义多 WAN 调度算法、协议策略与会话粘性规则，供汇聚组引用</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CardToolbar class="toolbar">
                  <el-button type="primary" @click="openCreate">+ 新建策略</el-button>
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="fill" :data="list" v-loading="loading" size="default" border stripe>
                  <el-table-column prop="name" label="策略名称" min-width="160" />
                  <el-table-column label="调度算法" min-width="140">
                    <template #default="{ row }">{{ algoText(row.algorithm) }}</template>
                  </el-table-column>
                  <el-table-column prop="defaultWeight" label="默认权重" min-width="100" />
                  <el-table-column label="TCP 策略" min-width="120">
                    <template #default="{ row }">{{ row.tcpPolicy || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="UDP 策略" min-width="120">
                    <template #default="{ row }">{{ row.udpPolicy || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="IPv4 策略" min-width="120">
                    <template #default="{ row }">{{ row.ipv4Policy || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="IPv6 策略" min-width="120">
                    <template #default="{ row }">{{ row.ipv6Policy || '—' }}</template>
                  </el-table-column>
                   <el-table-column label="会话粘性时间" min-width="120">
                     <template #default="{ row }">{{ row.sessionStickyTime != null ? row.sessionStickyTime + 's' : '—' }}</template>
                   </el-table-column>
                   <el-table-column label="引用汇聚组数" min-width="120">
                     <template #default="{ row }">{{ row.referencedByGroups?.length || 0 }}</template>
                   </el-table-column>
                  <el-table-column label="操作" fixed="right">
                    <template #default="{ row }">
                      <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
                      <el-button link type="danger" @click="removeItem(row)">删除</el-button>
                    </template>
                  </el-table-column>
                </StandardTable>
      
                <StandardModal size="standard"
                  v-model="dialogVisible"
                  :title="isEdit ? '编辑策略' : '新建策略'"
                >
                  <el-form :model="form" label-width="140px">
                    <el-form-item label="策略名称" required>
                      <el-input v-model="form.name" />
                    </el-form-item>
                    <el-form-item label="调度算法" required>
                      <el-select v-model="form.algorithm">
                       <el-option label="平均连接" value="round_robin" />
                       <el-option label="加权连接" value="weighted" />
                       <el-option label="最少连接加权" value="least_conn_weighted" />
                       <el-option label="按剩余带宽" value="bandwidth_aware" />
                       <el-option label="源地址固定" value="source_hash" />
                       <el-option label="目标地址固定" value="destination_hash" />
                      </el-select>
                    </el-form-item>
                    <el-form-item label="默认权重">
                      <el-input-number v-model="form.defaultWeight" :min="1" :max="100" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="TCP 策略">
                      <el-input v-model="form.tcpPolicy" placeholder="如 weight / sticky" />
                    </el-form-item>
                    <el-form-item label="UDP 策略">
                      <el-input v-model="form.udpPolicy" placeholder="如 weight / sticky" />
                    </el-form-item>
                    <el-form-item label="IPv4 策略">
                      <el-input v-model="form.ipv4Policy" placeholder="如 prefer" />
                    </el-form-item>
                    <el-form-item label="IPv6 策略">
                      <el-input v-model="form.ipv6Policy" placeholder="如 prefer" />
                    </el-form-item>
                     <el-form-item label="会话粘性时间(秒)">
                       <el-input-number v-model="form.sessionStickyTime" :min="0" :max="86400" controls-position="right" />
                    </el-form-item>
                  </el-form>
                  <template #footer>
                    <el-button @click="dialogVisible = false">取消</el-button>
                    <el-button type="primary" @click="save">保存</el-button>
                  </template>
                </StandardModal>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { policyService } from '../../services/dataService.js'

const loading = ref(false)
const list = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)

const defaultForm = () => ({
  id: null,
  name: '',
  algorithm: 'least_conn_weighted',
  defaultWeight: 10,
  tcpPolicy: '',
  udpPolicy: '',
  ipv4Policy: '',
  ipv6Policy: '',
  sessionStickyTime: 300,
  referencedByGroups: []
})
const form = reactive(defaultForm())

const algoText = (a) => ({
  round_robin: '平均连接',
  weighted: '加权连接',
  least_conn_weighted: '最少连接加权',
  bandwidth_aware: '按剩余带宽',
  source_hash: '源地址固定',
  destination_hash: '目标地址固定'
}[a] || a)

async function loadData() {
  loading.value = true
  try {
    list.value = await policyService.list()
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, defaultForm())
  isEdit.value = false
  dialogVisible.value = true
}
function openEdit(row) {
  Object.assign(form, defaultForm(), {
    ...row,
    referencedByGroups: [...(row.referencedByGroups || [])],
  })
  isEdit.value = true
  dialogVisible.value = true
}

async function save() {
  if (!form.name || !form.algorithm) {
    ElMessage.warning('请填写名称和算法')
    return
  }
  try {
    if (isEdit.value) {
      await policyService.update(form.id, { ...form })
      ElMessage.success('已保存')
    } else {
      await policyService.create({ ...form })
      ElMessage.success('已创建')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('保存失败：' + e.message)
  }
}

async function removeItem(row) {
  try {
    await policyService.remove(row.id)
    ElMessage.success('已删除 ' + row.name)
    loadData()
  } catch (e) {
    ElMessage.error('删除失败：' + e.message)
  }
}

onMounted(loadData)
</script>

<style scoped>
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
</style>
