<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>链路聚合 Bond/LACP</h2>
      <p>Linux Bond、802.3ad、active-backup 等链路层聚合 — 非PPPoE多线路汇聚</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <el-alert type="warning" :closable="false">
            <strong>注意：</strong>此页面仅负责链路层聚合（Bond/LACP），用于将多个物理网口绑定为单个逻辑链路。
            PPPoE 多线路汇聚请前往 <router-link to="/multiwan/aggregation-groups" style="color:#1677ff">多拨与汇聚 → 汇聚组</router-link>。
          </el-alert>
          <SectionCard shadow="never">
            <div style="display:flex;justify-content:space-between;align-items:center">
              <span>Bond 接口列表</span>
              <el-button type="primary" @click="openAdd">添加 Bond</el-button>
            </div>
            <StandardTable layout-mode="fill" :data="bonds" border stripe size="default">
              <el-table-column prop="name" label="接口名称" fixed />
              <el-table-column prop="mode" label="聚合模式">
                <template #default="{ row }">{{ modeLabel(row.mode) }}</template>
              </el-table-column>
              <el-table-column prop="members" label="成员端口" min-width="150">
                <template #default="{ row }">{{ row.members.join(', ') }}</template>
              </el-table-column>
              <el-table-column prop="miimon" label="MII监控(ms)" />
              <el-table-column label="状态">
                <template #default="{ row }">
                  <span class="status-tag">
                    <span :class="['status-dot', row.status === 'up' ? 'online' : 'offline']"></span>
                    {{ row.status === 'up' ? '活跃' : '离线' }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="hashPolicy" label="Hash策略" />
              <el-table-column prop="lacpRate" label="LACP速率" />
              <el-table-column label="操作" fixed="right">
                <template #default="{ row }">
                  <el-button size="small" type="primary" link @click="openEdit(row)">编辑</el-button>
                  <el-button size="small" type="danger" link @click="handleDelete(row)">删除</el-button>
                </template>
              </el-table-column>
            </StandardTable>
          </SectionCard>
      
          <StandardModal size="standard" v-model="dialogVisible" :title="editId ? '编辑 Bond' : '添加 Bond'">
            <el-form :model="form" label-width="110px">
              <el-form-item label="接口名称" required>
                <el-input v-model="form.name" placeholder="如 bond0" />
              </el-form-item>
              <el-form-item label="聚合模式">
                <el-select v-model="form.mode">
                  <el-option label="802.3ad (LACP)" value="802.3ad" />
                  <el-option label="active-backup" value="active-backup" />
                  <el-option label="balance-rr" value="balance-rr" />
                  <el-option label="balance-xor" value="balance-xor" />
                  <el-option label="broadcast" value="broadcast" />
                  <el-option label="balance-tlb" value="balance-tlb" />
                  <el-option label="balance-alb" value="balance-alb" />
                </el-select>
              </el-form-item>
              <el-form-item label="成员端口">
                <el-select v-model="form.members" multiple placeholder="选择物理端口">
                  <el-option v-for="p in ports" :key="p.id" :label="p.name" :value="p.name" />
                </el-select>
              </el-form-item>
              <el-form-item label="MII监控间隔">
                <el-input-number v-model="form.miimon" :min="0" :max="10000" />
              </el-form-item>
              <el-form-item label="Hash策略">
                <el-select v-model="form.hashPolicy">
                  <el-option label="layer2" value="layer2" />
                  <el-option label="layer2+3" value="layer2+3" />
                  <el-option label="layer3+4" value="layer3+4" />
                  <el-option label="encap2+3" value="encap2+3" />
                  <el-option label="encap3+4" value="encap3+4" />
                </el-select>
              </el-form-item>
              <el-form-item label="LACP速率" v-if="form.mode === '802.3ad'">
                <el-select v-model="form.lacpRate">
                  <el-option label="慢速 (30s)" value="slow" />
                  <el-option label="快速 (1s)" value="fast" />
                </el-select>
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="dialogVisible = false">取消</el-button>
              <el-button type="primary" :disabled="!form.name" @click="save">保存</el-button>
            </template>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { usePersistentRef } from '../../composables/usePersistentRef.js'
import { physicalPortService } from '../../services/dataService.js'

const ports = ref(physicalPortService.list())

const bonds = usePersistentRef('network:linkAggregation', [
  { id: 1, name: 'bond0', mode: '802.3ad', members: ['eth1', 'eth2'], miimon: 100, status: 'up', hashPolicy: 'layer3+4', lacpRate: 'slow' }
])

function modeLabel(m) {
  return { '802.3ad': '802.3ad (LACP)', 'active-backup': 'active-backup', 'balance-rr': 'balance-rr', 'balance-xor': 'balance-xor', 'broadcast': 'broadcast', 'balance-tlb': 'balance-tlb', 'balance-alb': 'balance-alb' }[m] || m
}

const dialogVisible = ref(false)
const editId = ref(null)
const form = reactive({ name: '', mode: '802.3ad', members: [], miimon: 100, hashPolicy: 'layer3+4', lacpRate: 'slow' })

function openAdd() {
  editId.value = null
  Object.assign(form, { name: '', mode: '802.3ad', members: [], miimon: 100, hashPolicy: 'layer3+4', lacpRate: 'slow' })
  dialogVisible.value = true
}
function openEdit(row) {
  editId.value = row.id
  Object.assign(form, { ...row })
  dialogVisible.value = true
}
function save() {
  if (editId.value) {
    const idx = bonds.value.findIndex(b => b.id === editId.value)
    if (idx >= 0) bonds.value[idx] = { ...bonds.value[idx], ...form }
    ElMessage.success('Bond 已更新')
  } else {
    bonds.value.push({ ...form, id: Date.now(), status: 'down' })
    ElMessage.success('Bond 已添加')
  }
  dialogVisible.value = false
}
function handleDelete(row) {
  bonds.value = bonds.value.filter(b => b.id !== row.id)
  ElMessage.success(`Bond「${row.name}」已删除`)
}
</script>
