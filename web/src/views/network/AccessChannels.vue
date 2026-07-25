<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>接入通道</h2>
      <p>PPPoE 会话依附的二层通道 — 一个物理口可创建多个通道，同一通道可承载多个账号</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never" class="section-card">
            <div class="card-header-actions">
              <div class="header-left">
                <span class="header-title">接入通道列表</span>
                <span class="header-count">（共 {{ channels.length }} 个）</span>
              </div>
              <div class="header-right">
                <el-button @click="refreshTable">
                  <el-icon><Refresh /></el-icon>刷新
                </el-button>
                <el-button @click="openBatchVlan">批量创建VLAN</el-button>
                <el-button type="primary" @click="openAdd">添加通道</el-button>
              </div>
            </div>
      
            <!-- 表格 — fill 模式，100% 宽度 -->
            <StandardTable layout-mode="fill" :data="channels" border stripe size="default">
              <el-table-column prop="name" label="通道名称" min-width="140" />
              <el-table-column label="物理端口">
                <template #default="{ row }">{{ getPortName(row.physicalPortId) }}</template>
              </el-table-column>
              <el-table-column label="标签模式">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.tagMode === 'dot1q' ? 'primary' : 'info'">{{ row.tagMode === 'dot1q' ? '802.1Q' : 'Untagged' }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="VLAN ID">
                <template #default="{ row }">{{ row.vlanId || '—' }}</template>
              </el-table-column>
              <el-table-column prop="deviceName" label="底层设备" min-width="140" />
              <el-table-column prop="mtu" label="MTU" />
              <el-table-column label="MAC模式">
                <template #default="{ row }">{{ { shared:'共用通道MAC', auto:'自动生成', manual:'手动指定' }[row.macMode] || row.macMode }}</template>
              </el-table-column>
              <el-table-column label="线路">
                <template #default="{ row }">{{ countDials(row.id) }}</template>
              </el-table-column>
              <el-table-column label="状态">
                <template #default="{ row }">
                  <span class="status-tag">
                    <span :class="['status-dot', row.status === 'up' ? 'online' : 'offline']"></span>
                    {{ row.status === 'up' ? '活跃' : '离线' }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column label="操作" fixed="right">
                <template #default="{ row }">
                  <el-button size="small" type="primary" link @click="openEdit(row)">编辑</el-button>
                  <el-button size="small" type="danger" link @click="handleDelete(row)">删除</el-button>
                </template>
              </el-table-column>
            </StandardTable>
          </SectionCard>
      
          <!-- 添加/编辑通道 — standard 宽度 -->
          <StandardModal v-model="dialogVisible" :title="editId ? '编辑接入通道' : '添加接入通道'" size="standard" @submit="save">
            <el-form :model="form" label-width="110px">
              <el-row :gutter="16">
                <el-col :span="12">
                  <el-form-item label="物理端口" required>
                    <el-select v-model="form.physicalPortId" @change="autoFillFromPort">
                      <el-option v-for="p in ports" :key="p.id" :label="p.name + (p.role ? ' (' + {wan:'WAN',lan:'LAN',mgmt:'管理',unassigned:'未分配'}[p.role]+')' : '')" :value="p.id" />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="标签模式">
                    <el-select v-model="form.tagMode" @change="autoFillDeviceName">
                      <el-option label="802.1Q VLAN" value="dot1q" />
                      <el-option label="Untagged" value="untagged" />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="16">
                <el-col :span="12">
                  <el-form-item label="通道名称" required>
                    <el-input v-model="form.name" placeholder="自动生成" />
                    <span style="font-size:12px;color:var(--lh-text-secondary)">建议使用自动生成名称</span>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="VLAN ID" v-if="form.tagMode === 'dot1q'">
                    <el-input-number v-model="form.vlanId" :min="1" :max="4094" @change="autoFillFromVlan" />
                  </el-form-item>
                  <el-form-item label="MTU" v-else>
                    <el-input-number v-model="form.mtu" :min="576" :max="9000" />
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="16">
                <el-col :span="12">
                  <el-form-item label="底层设备">
                    <el-input v-model="form.deviceName" placeholder="自动生成" />
                    <span style="font-size:12px;color:var(--lh-text-secondary)">由物理口和VLAN自动推导</span>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="MAC模式">
                    <el-select v-model="form.macMode">
                      <el-option label="共用通道MAC" value="shared" />
                      <el-option label="自动生成独立MAC" value="auto" />
                      <el-option label="手动指定" value="manual" />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </StandardModal>
      
          <!-- 批量VLAN — standard 宽度 -->
          <StandardModal v-model="batchDialog" title="批量创建VLAN通道" size="standard" @submit="doBatchCreate">
            <el-alert type="info" :closable="false">
              选择基础端口，输入VLAN列表（逗号分隔），自动生成对应接入通道。<br>
              同一物理口、同一VLAN如已存在则自动跳过。
            </el-alert>
            <el-form :model="batchForm" label-width="110px">
              <el-form-item label="基础端口" required>
                <el-select v-model="batchForm.portId">
                  <el-option v-for="p in ports" :key="p.id" :label="p.name" :value="p.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="VLAN列表" required>
                <el-input v-model="batchForm.vlans" type="textarea" :rows="3" placeholder="101, 103, 105, 107, 109, 111" />
              </el-form-item>
            </el-form>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { accessChannelService, physicalPortService } from '../../services/dataService.js'
import StandardModal from '../../components/StandardModal.vue'

const channels = ref(accessChannelService.list())
const ports = ref(physicalPortService.list())

function refreshTable() { channels.value = accessChannelService.list() }
function getPortName(pid) { return physicalPortService.get(pid)?.name || '—' }
function countDials(chId) { return accessChannelService.countDialInstances(chId) }

// 表单
const dialogVisible = ref(false)
const editId = ref(null)
const form = reactive({ name:'', physicalPortId:'', tagMode:'dot1q', vlanId:101, deviceName:'', mtu:1500, macMode:'shared' })

function autoFillFromPort() {
  autoFillDeviceName()
}
function autoFillFromVlan() {
  autoFillDeviceName()
}
function autoFillDeviceName() {
  const port = physicalPortService.get(form.physicalPortId)
  if (!port) return
  if (form.tagMode === 'dot1q' && form.vlanId) {
    form.deviceName = `${port.name}.${form.vlanId}`
    if (!editId.value) form.name = `channel-${form.vlanId}`
    form.mtu = port.mtu || 1500
  } else if (form.tagMode === 'untagged') {
    form.deviceName = port.name
    if (!editId.value) form.name = `channel-${port.name}-native`
    form.mtu = port.mtu || 1500
  }
}

function openAdd() {
  editId.value = null
  Object.assign(form, { name:'', physicalPortId: ports.value[0]?.id||'', tagMode:'dot1q', vlanId:101, deviceName:'', mtu:1500, macMode:'shared' })
  autoFillDeviceName()
  dialogVisible.value = true
}
function openEdit(row) {
  editId.value = row.id
  Object.assign(form, { ...row })
  dialogVisible.value = true
}
function save() {
  if (!editId.value && form.tagMode === 'dot1q' && form.physicalPortId) {
    // 检查是否已存在相同VLAN通道
    const exists = channels.value.find(c => c.physicalPortId === form.physicalPortId && c.vlanId === form.vlanId)
    if (exists) {
      ElMessage.warning(`物理端口 ${getPortName(form.physicalPortId)} 的 VLAN ${form.vlanId} 已存在（${exists.name}），自动复用`)
      dialogVisible.value = false
      return
    }
  }
  const data = { ...form }
  if (editId.value) {
    accessChannelService.update(editId.value, data)
    ElMessage.success('接入通道已更新')
  } else {
    accessChannelService.create({ ...data, status: 'down' })
    ElMessage.success('接入通道已添加')
  }
  refreshTable()
  dialogVisible.value = false
}
function handleDelete(row) {
  try {
    accessChannelService.remove(row.id)
    refreshTable()
    ElMessage.success(`接入通道「${row.name}」已删除`)
  } catch(e) { ElMessage.error(e.message) }
}

// 批量
const batchDialog = ref(false)
const batchForm = reactive({ portId:'', vlans:'' })
function openBatchVlan() { batchForm.portId = ''; batchForm.vlans = ''; batchDialog.value = true }
function doBatchCreate() {
  if (!batchForm.portId || !batchForm.vlans) { ElMessage.warning('请填写基础端口和VLAN列表'); return }
  const vlanIds = batchForm.vlans.split(',').map(s=>parseInt(s.trim())).filter(n=>!isNaN(n)&&n>0&&n<=4094)
  if (!vlanIds.length) { ElMessage.warning('VLAN ID 无效'); return }
  const created = accessChannelService.batchCreateVlans(batchForm.portId, vlanIds)
  refreshTable()
  ElMessage.success(`已创建 ${created.length} 个接入通道`)
  batchDialog.value = false
}
</script>

<style scoped>
.section-card { margin-bottom: 16px; }
.card-header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.header-left { display: flex; align-items: baseline; gap: 4px; }
.header-title { font-size: 15px; font-weight: 600; }
.header-count { font-size: 13px; color: var(--lh-text-secondary); }
.header-right { display: flex; gap: 8px; }
</style>
