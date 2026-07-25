<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>IPv6 路由</h2>
      <p>查看与维护 IPv6 路由表，包括静态、动态、自动学习到的路由条目</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CardToolbar class="toolbar">
                  <el-button type="primary" @click="openCreate">+ 新建静态路由</el-button>
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="scroll"
                  :data="list"
                  v-loading="loading"
                  size="default"
                  border
                  stripe
      
                >
                  <el-table-column prop="destination" label="目标网络" min-width="220">
                    <template #default="{ row }">
                      <span class="mono">{{ row.destination }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column prop="nextHop" label="下一跳" min-width="200">
                    <template #default="{ row }">
                      <span class="mono">{{ row.nextHop }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column prop="interface" label="接口" min-width="120" />
                  <el-table-column prop="metric" label="度量" min-width="80" />
                  <el-table-column label="来源" min-width="110">
                    <template #default="{ row }">
                      <el-tag :type="sourceTagType(row.source)" effect="light">
                        <el-icon class="status-icon">
                          <Edit v-if="row.source === 'static'" />
                          <Refresh v-else-if="row.source === 'dynamic'" />
                          <MagicStick v-else />
                        </el-icon>
                        {{ sourceText(row.source) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column prop="protocol" label="协议" min-width="110" />
                  <el-table-column label="状态" min-width="120">
                    <template #default="{ row }">
                      <el-tag :type="row.status === 'up' ? 'success' : 'info'" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="row.status === 'up'" />
                          <CircleClose v-else />
                        </el-icon>
                        {{ row.status === 'up' ? '可达' : '不可达' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="操作" fixed="right">
                    <template #default="{ row }">
                      <el-button
                        link
                        type="primary"
                        :disabled="row.source !== 'static'"
                        @click="openEdit(row)"
                      >编辑</el-button>
                      <el-button
                        link
                        type="danger"
                        :disabled="row.source !== 'static'"
                        @click="removeItem(row)"
                      >删除</el-button>
                    </template>
                  </el-table-column>
                </StandardTable>
      
                <StandardModal size="standard"
                  v-model="dialogVisible"
                  :title="isEdit ? '编辑静态路由' : '新建静态路由'"
                >
                  <el-form :model="form" label-width="120px">
                    <el-form-item label="目标网络" required>
                      <el-input v-model="form.destination" placeholder="如 2001:db8::/64" />
                    </el-form-item>
                    <el-form-item label="下一跳" required>
                      <el-input v-model="form.nextHop" placeholder="如 fe80::1" />
                    </el-form-item>
                    <el-form-item label="接口">
                      <el-input v-model="form.interface" placeholder="如 eth2.101 或 pppoe-101" />
                    </el-form-item>
                    <el-form-item label="度量">
                      <el-input-number v-model="form.metric" :min="0" :max="9999" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="协议">
                      <el-input v-model="form.protocol" placeholder="如 static" />
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
import {
  CircleCheck, CircleClose, Edit, Refresh, MagicStick,
} from '@element-plus/icons-vue'

// 内联 Mock 数据
const mockRoutes = [
  { id: 'r1', destination: '::/0', nextHop: 'fe80::aabb:ccdd:eeff', interface: 'pppoe-101', metric: 10, source: 'dynamic', protocol: 'DHCPv6-PD', status: 'up' },
  { id: 'r2', destination: '2408:8456:3a02:1010::/60', nextHop: '::', interface: 'pppoe-101', metric: 0, source: 'auto', protocol: 'kernel', status: 'up' },
  { id: 'r3', destination: '2408:8456:3a01:101::/64', nextHop: '::', interface: 'pppoe-101', metric: 0, source: 'auto', protocol: 'kernel', status: 'up' },
  { id: 'r4', destination: 'fd66:10:10::/64', nextHop: '::', interface: 'br-lan', metric: 0, source: 'auto', protocol: 'kernel', status: 'up' },
  { id: 'r5', destination: '2001:4860:4860::/48', nextHop: 'fe80::aabb:ccdd:eeff', interface: 'pppoe-103', metric: 50, source: 'static', protocol: 'static', status: 'up' },
  { id: 'r6', destination: '2408:8888::/32', nextHop: 'fe80::aabb:ccdd:eeff', interface: 'pppoe-105', metric: 50, source: 'static', protocol: 'static', status: 'up' },
  { id: 'r7', destination: 'fe80::/64', nextHop: '::', interface: 'br-lan', metric: 0, source: 'auto', protocol: 'kernel', status: 'up' },
  { id: 'r8', destination: 'ff00::/8', nextHop: '::', interface: 'br-lan', metric: 0, source: 'auto', protocol: 'kernel', status: 'up' },
]

const list = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)

const defaultForm = () => ({
  id: null,
  destination: '',
  nextHop: '',
  interface: '',
  metric: 100,
  protocol: 'static',
})
const form = reactive(defaultForm())

function sourceText(s) {
  return { static: '静态', dynamic: '动态', auto: '自动' }[s] || s
}

function sourceTagType(s) {
  return { static: 'warning', dynamic: 'success', auto: 'info' }[s] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    // Mock 模式：直接使用内联数据
    list.value = JSON.parse(JSON.stringify(mockRoutes))
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
  Object.assign(form, defaultForm(), row)
  isEdit.value = true
  dialogVisible.value = true
}

function save() {
  if (!form.destination || !form.nextHop) {
    ElMessage.warning('请填写目标网络与下一跳')
    return
  }
  if (isEdit.value) {
    const idx = list.value.findIndex(i => i.id === form.id)
    if (idx >= 0) list.value[idx] = { ...form, source: 'static' }
    ElMessage.success('已保存')
  } else {
    list.value.push({ ...form, id: 'r_' + Date.now(), source: 'static', status: 'up' })
    ElMessage.success('已创建')
  }
  dialogVisible.value = false
}

function removeItem(row) {
  const idx = list.value.findIndex(i => i.id === row.id)
  if (idx >= 0) {
    list.value.splice(idx, 1)
    ElMessage.success('已删除 ' + row.destination)
  }
}

onMounted(loadData)
</script>

<style scoped>
.mono { font-family: monospace; font-size: 13px; word-break: break-all; }
.status-icon { margin-right: 4px; vertical-align: middle; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-form-item__label) { font-size: 14px; }
</style>
