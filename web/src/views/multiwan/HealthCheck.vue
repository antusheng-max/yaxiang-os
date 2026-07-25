<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>健康检测</h2>
      <p>定义多 WAN 线路健康检测策略，支持 IPv4/IPv6 分别摘除</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-alert
                  type="warning"
                  :closable="false"
                  show-icon
                  title="不能因为 IPv6 检测失败就默认把 IPv4 线路一并摘除，应允许分别参与 IPv4 和 IPv6 调度。"
      
                />
      
                <CardToolbar class="toolbar">
                  <el-button type="primary" @click="openCreate">+ 新建检测策略</el-button>
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="fill" :data="list" v-loading="loading" size="default" border stripe>
                  <el-table-column prop="name" label="策略名称" min-width="160" />
                   <el-table-column label="检测类型" min-width="120">
                     <template #default="{ row }">
                       <el-tag size="small" :type="typeTag(row.checkType)">{{ typeText(row.checkType) }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="检测间隔" min-width="100">
                    <template #default="{ row }">{{ row.interval }}s</template>
                  </el-table-column>
                  <el-table-column label="超时" min-width="90">
                    <template #default="{ row }">{{ row.timeout }}s</template>
                  </el-table-column>
                   <el-table-column prop="consecutiveFailures" label="连续失败次数" min-width="120" />
                   <el-table-column prop="consecutiveRecovery" label="连续恢复次数" min-width="120" />
                   <el-table-column label="IPv4 检测目标" min-width="190">
                     <template #default="{ row }">{{ row.ipv4Targets?.join(', ') || '—' }}</template>
                   </el-table-column>
                   <el-table-column label="IPv6 检测目标" min-width="220">
                     <template #default="{ row }">{{ row.ipv6Targets?.join(', ') || '—' }}</template>
                   </el-table-column>
                   <el-table-column label="分别摘除" min-width="100">
                     <template #default="{ row }">
                       <el-tag :type="row.separateRemoval ? 'success' : 'info'" size="small">
                         {{ row.separateRemoval ? '是' : '否' }}
                       </el-tag>
                     </template>
                   </el-table-column>
                   <el-table-column label="引用汇聚组" min-width="110">
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
                  :title="isEdit ? '编辑检测策略' : '新建检测策略'"
                >
                  <el-form :model="form" label-width="140px">
                    <el-form-item label="策略名称" required>
                      <el-input v-model="form.name" />
                    </el-form-item>
                    <el-form-item label="检测类型" required>
                     <el-select v-model="form.checkType">
                        <el-option label="ICMP" value="icmp" />
                        <el-option label="TCP" value="tcp" />
                        <el-option label="DNS" value="dns" />
                        <el-option label="HTTP" value="http" />
                      </el-select>
                    </el-form-item>
                    <el-form-item label="检测间隔(秒)">
                      <el-input-number v-model="form.interval" :min="1" :max="3600" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="超时(秒)">
                      <el-input-number v-model="form.timeout" :min="1" :max="60" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="连续失败次数">
                     <el-input-number v-model="form.consecutiveFailures" :min="1" :max="20" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="连续恢复次数">
                     <el-input-number v-model="form.consecutiveRecovery" :min="1" :max="20" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="IPv4 检测目标">
                     <el-input v-model="form.ipv4TargetsText" placeholder="多个目标用逗号分隔" />
                    </el-form-item>
                    <el-form-item label="IPv6 检测目标">
                     <el-input v-model="form.ipv6TargetsText" placeholder="多个目标用逗号分隔" />
                    </el-form-item>
                    <el-form-item label="分别摘除">
                     <el-switch v-model="form.separateRemoval" />
                      <span class="form-hint">开启后 IPv6 失败仅摘除 IPv6，不影响 IPv4 调度</span>
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
import { healthCheckService } from '../../services/dataService.js'

const loading = ref(false)
const list = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)

const defaultForm = () => ({
  id: null,
  name: '',
  checkType: 'icmp',
  interval: 5,
  timeout: 3,
  consecutiveFailures: 3,
  consecutiveRecovery: 2,
  ipv4TargetsText: '',
  ipv6TargetsText: '',
  checkIpv4: true,
  checkIpv6: true,
  separateRemoval: true,
  referencedByGroups: []
})
const form = reactive(defaultForm())

const typeText = (t) => ({ icmp: 'ICMP', tcp: 'TCP', dns: 'DNS', http: 'HTTP' }[t] || t)
const typeTag = (t) => ({ icmp: '', tcp: 'success', dns: 'warning', http: 'info' }[t] || '')

async function loadData() {
  loading.value = true
  try {
    list.value = await healthCheckService.list()
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
    ipv4TargetsText: (row.ipv4Targets || []).join(', '),
    ipv6TargetsText: (row.ipv6Targets || []).join(', '),
    referencedByGroups: [...(row.referencedByGroups || [])],
  })
  isEdit.value = true
  dialogVisible.value = true
}

async function save() {
  if (!form.name || !form.checkType) {
    ElMessage.warning('请填写名称和类型')
    return
  }
  const splitTargets = value => String(value || '')
    .split(',')
    .map(item => item.trim())
    .filter(Boolean)
  const payload = {
    id: form.id,
    name: form.name,
    checkType: form.checkType,
    interval: form.interval,
    timeout: form.timeout,
    consecutiveFailures: form.consecutiveFailures,
    consecutiveRecovery: form.consecutiveRecovery,
    ipv4Targets: splitTargets(form.ipv4TargetsText),
    ipv6Targets: splitTargets(form.ipv6TargetsText),
    checkIpv4: form.checkIpv4,
    checkIpv6: form.checkIpv6,
    separateRemoval: form.separateRemoval,
    referencedByGroups: [...form.referencedByGroups],
  }
  try {
    if (isEdit.value) {
      await healthCheckService.update(form.id, payload)
      ElMessage.success('已保存')
    } else {
      await healthCheckService.create(payload)
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
    await healthCheckService.remove(row.id)
    ElMessage.success('已删除 ' + row.name)
    loadData()
  } catch (e) {
    ElMessage.error('删除失败：' + e.message)
  }
}

onMounted(loadData)
</script>

<style scoped>
.form-hint { margin-left: 8px; font-size: 12px; color: #909399; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
</style>
