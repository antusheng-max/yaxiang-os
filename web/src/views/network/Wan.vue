<template>
  <PageContainer>
    <PageHeader title="Wan" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header>
              <div class="card-header">
                <span>WAN管理 - 连接方式配置</span>
                <el-button type="primary" @click="showAddDialog">添加WAN连接</el-button>
              </div>
            </template>
      
            <div v-for="(wan, idx) in wanList" :key="idx" class="wan-card">
              <div class="wan-card-header">
                <div class="wan-title">
                  <el-tag :type="wan.status === '已连接' ? 'success' : 'danger'" size="small">{{ wan.status }}</el-tag>
                  <strong>{{ wan.name }}</strong>
                  <el-tag size="small" type="info">{{ wan.method }}</el-tag>
                  <span class="wan-device">设备: {{ wan.device }}</span>
                </div>
                <div>
                  <el-button size="small" @click="editWan(idx)">编辑</el-button>
                  <el-button size="small" type="danger" @click="deleteWan(idx)">删除</el-button>
                </div>
              </div>
      
              <!-- 运行时状态 -->
              <el-descriptions :column="4" size="small" border class="wan-runtime">
                <el-descriptions-item label="IP地址">{{ wan.runtime.ip || '-' }}</el-descriptions-item>
                <el-descriptions-item label="网关">{{ wan.runtime.gateway || '-' }}</el-descriptions-item>
                <el-descriptions-item label="DNS">{{ wan.runtime.dns || '-' }}</el-descriptions-item>
                <el-descriptions-item label="运行时间">{{ wan.runtime.uptime || '-' }}</el-descriptions-item>
                <el-descriptions-item label="下行速率">{{ wan.runtime.rxRate || '-' }}</el-descriptions-item>
                <el-descriptions-item label="上行速率">{{ wan.runtime.txRate || '-' }}</el-descriptions-item>
                <el-descriptions-item label="延迟">{{ wan.runtime.latency || '-' }}</el-descriptions-item>
                <el-descriptions-item label="丢包率">{{ wan.runtime.loss || '-' }}</el-descriptions-item>
              </el-descriptions>
      
              <!-- PPPoE拨号会话列表 -->
              <div v-if="wan.method === 'PPPoE拨号' || wan.method === 'VLAN虚拟拨号'" class="session-list">
                <div class="session-header">
                  <span>拨号会话 ({{ wan.sessions.length }}/8)</span>
                  <el-button size="small" type="primary" link @click="addSession(idx)" :disabled="wan.sessions.length >= 8">+ 添加会话</el-button>
                </div>
                <StandardTable layout-mode="scroll" :data="wan.sessions" size="small" border stripe>
                  <el-table-column prop="id" label="#" />
                  <el-table-column v-if="wan.method === 'VLAN虚拟拨号'" prop="vlanId" label="VLAN ID" />
                  <el-table-column v-if="wan.method === 'VLAN虚拟拨号'" prop="vlanDevice" label="VLAN设备" />
                  <el-table-column prop="account" label="账号" min-width="160" />
                  <el-table-column prop="password" label="密码">
                    <template #default="{ row }">{{ '•'.repeat(Math.min(row.password.length, 8)) }}</template>
                  </el-table-column>
                  <el-table-column prop="status" label="状态">
                    <template #default="{ row }">
                      <el-tag :type="row.status === '已连接' ? 'success' : row.status === '拨号中' ? 'warning' : 'danger'" size="small">{{ row.status }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column prop="ip" label="获得IP" />
                  <el-table-column prop="uptime" label="运行时间" />
                  <el-table-column label="操作" fixed="right">
                    <template #default="{ row, $index }">
                      <el-button size="small" link type="primary" @click="redial(idx, $index)">重拨</el-button>
                      <el-button size="small" link type="danger" @click="removeSession(idx, $index)">删除</el-button>
                    </template>
                  </el-table-column>
                </StandardTable>
              </div>
            </div>
      
            <EmptyState v-if="wanList.length === 0" description="暂无WAN连接，请添加" />
          </SectionCard>
      
          <!-- 添加/编辑WAN对话框 -->
          <StandardModal size="standard" v-model="dialogVisible" :title="dialogTitle">
            <el-form :model="form" label-width="120px">
              <el-form-item label="接口名称" required>
                <el-input v-model="form.name" placeholder="如 wan, wan2, wan3" />
              </el-form-item>
              <el-form-item label="物理网口" required>
                <el-select v-model="form.device">
                  <el-option v-for="d in devices" :key="d" :label="d" :value="d" />
                </el-select>
              </el-form-item>
              <el-form-item label="连接方式" required>
                <el-radio-group v-model="form.method">
                  <el-radio value="DHCP">DHCP</el-radio>
                  <el-radio value="静态IP">静态IP</el-radio>
                  <el-radio value="PPPoE拨号">PPPoE拨号</el-radio>
                  <el-radio value="VLAN虚拟拨号">VLAN虚拟拨号</el-radio>
                </el-radio-group>
              </el-form-item>
      
              <!-- 静态IP字段 -->
              <template v-if="form.method === '静态IP'">
                <el-form-item label="IP地址"><el-input v-model="form.ipaddr" placeholder="192.168.1.100/24" /></el-form-item>
                <el-form-item label="网关"><el-input v-model="form.gateway" placeholder="192.168.1.1" /></el-form-item>
                <el-form-item label="DNS"><el-input v-model="form.dns" placeholder="8.8.8.8 8.8.4.4" /></el-form-item>
              </template>
      
              <!-- PPPoE拨号字段 -->
              <template v-if="form.method === 'PPPoE拨号'">
                <el-divider content-position="left">拨号会话配置（最多8个）</el-divider>
                <div v-for="(s, i) in form.sessions" :key="i" class="session-form-row">
                  <el-input v-model="s.account" placeholder="宽带账号" />
                  <el-input v-model="s.password" placeholder="密码" type="password" show-password />
                  <el-button type="danger" link @click="form.sessions.splice(i, 1)">删除</el-button>
                </div>
                <el-button size="small" @click="form.sessions.push({ account: '', password: '' })" :disabled="form.sessions.length >= 8">+ 添加拨号会话</el-button>
              </template>
      
              <!-- VLAN虚拟拨号字段 -->
              <template v-if="form.method === 'VLAN虚拟拨号'">
                <el-divider content-position="left">VLAN拨号会话（VLAN ID + 账号 + 密码）</el-divider>
                <div v-for="(s, i) in form.sessions" :key="i" class="session-form-row">
                  <el-input-number v-model="s.vlanId" :min="1" :max="4094" placeholder="VLAN" />
                  <el-input v-model="s.account" placeholder="宽带账号" />
                  <el-input v-model="s.password" placeholder="密码" type="password" show-password />
                  <el-button type="danger" link @click="form.sessions.splice(i, 1)">删除</el-button>
                </div>
                <el-button size="small" @click="form.sessions.push({ vlanId: 100, account: '', password: '' })" :disabled="form.sessions.length >= 8">+ 添加VLAN会话</el-button>
              </template>
      
              <el-form-item label="MTU">
                <el-input-number v-model="form.mtu" :min="576" :max="9000" />
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="dialogVisible = false">取消</el-button>
              <el-button type="primary" @click="saveWan">保存</el-button>
            </template>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const windowWidth = ref(window.innerWidth)
function onResize() { windowWidth.value = window.innerWidth }
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))
const isMobile = computed(() => windowWidth.value < 600)

const devices = ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5']

const wanList = ref([
  {
    name: 'wan', device: 'eth2', method: 'PPPoE拨号', status: '已连接',
    runtime: { ip: '100.64.1.100', gateway: '100.64.1.1', dns: '202.96.128.86', uptime: '12天 8小时', rxRate: '85.2 Mbps', txRate: '32.1 Mbps', latency: '8ms', loss: '0%' },
    sessions: [
      { id: 1, account: 'user001@gd', password: 'pass123456', status: '已连接', ip: '100.64.1.100', uptime: '12天 8小时' },
      { id: 2, account: 'user002@gd', password: 'pass654321', status: '已连接', ip: '100.64.1.101', uptime: '12天 8小时' },
    ]
  },
  {
    name: 'wan2', device: 'eth3', method: 'DHCP', status: '已连接',
    runtime: { ip: '10.0.0.5', gateway: '10.0.0.1', dns: '10.0.0.1', uptime: '5天 2小时', rxRate: '45.8 Mbps', txRate: '12.3 Mbps', latency: '12ms', loss: '0.1%' },
    sessions: []
  },
  {
    name: 'wan3', device: 'eth0', method: 'VLAN虚拟拨号', status: '已连接',
    runtime: { ip: '100.64.2.50', gateway: '100.64.2.1', dns: '202.96.128.86', uptime: '3天 1小时', rxRate: '92.5 Mbps', txRate: '28.7 Mbps', latency: '6ms', loss: '0%' },
    sessions: [
      { id: 1, vlanId: 100, vlanDevice: 'eth0.100', account: 'vlan_user1@gd', password: 'vlanpass1', status: '已连接', ip: '100.64.2.50', uptime: '3天 1小时' },
      { id: 2, vlanId: 200, vlanDevice: 'eth0.200', account: 'vlan_user2@gd', password: 'vlanpass2', status: '已连接', ip: '100.64.2.51', uptime: '3天 1小时' },
      { id: 3, vlanId: 300, vlanDevice: 'eth0.300', account: 'vlan_user3@gd', password: 'vlanpass3', status: '拨号中', ip: '-', uptime: '-' },
    ]
  },
  {
    name: 'wan4', device: 'eth4', method: '静态IP', status: '已连接',
    runtime: { ip: '172.16.0.10', gateway: '172.16.0.1', dns: '172.16.0.1', uptime: '8天 5小时', rxRate: '55.0 Mbps', txRate: '20.0 Mbps', latency: '3ms', loss: '0%' },
    sessions: []
  },
])

const dialogVisible = ref(false)
const dialogTitle = ref('添加WAN连接')
const editIndex = ref(-1)
const form = reactive({
  name: '', device: 'eth0', method: 'DHCP', ipaddr: '', gateway: '', dns: '', mtu: 1500, sessions: []
})

function showAddDialog() {
  editIndex.value = -1
  dialogTitle.value = '添加WAN连接'
  Object.assign(form, { name: '', device: 'eth0', method: 'DHCP', ipaddr: '', gateway: '', dns: '', mtu: 1500, sessions: [] })
  dialogVisible.value = true
}

function editWan(idx) {
  editIndex.value = idx
  dialogTitle.value = '编辑WAN连接'
  const w = wanList.value[idx]
  Object.assign(form, { name: w.name, device: w.device, method: w.method, mtu: 1500, sessions: JSON.parse(JSON.stringify(w.sessions.map(s => ({ ...s })))) })
  dialogVisible.value = true
}

function saveWan() {
  if (!form.name) { ElMessage.warning('请输入接口名称'); return }
  const sessions = form.sessions.map((s, i) => ({
    ...s, id: i + 1,
    vlanDevice: form.method === 'VLAN虚拟拨号' ? `${form.device}.${s.vlanId}` : undefined,
    status: s.status || '未连接', ip: s.ip || '-', uptime: s.uptime || '-'
  }))
  const entry = {
    name: form.name, device: form.device, method: form.method, status: '未连接',
    runtime: { ip: form.ipaddr || '-', gateway: form.gateway || '-', dns: form.dns || '-', uptime: '-', rxRate: '-', txRate: '-', latency: '-', loss: '-' },
    sessions
  }
  if (editIndex.value >= 0) { wanList.value[editIndex.value] = entry; ElMessage.success('修改成功') }
  else { wanList.value.push(entry); ElMessage.success('添加成功') }
  dialogVisible.value = false
}

function deleteWan(idx) {
  ElMessageBox.confirm('确定删除该WAN连接？', '提示', { type: 'warning' }).then(() => {
    wanList.value.splice(idx, 1)
    ElMessage.success('删除成功')
  }).catch(() => {})
}

function addSession(wanIdx) {
  const wan = wanList.value[wanIdx]
  const id = wan.sessions.length + 1
  if (wan.method === 'VLAN虚拟拨号') {
    wan.sessions.push({ id, vlanId: 100 + id, vlanDevice: `${wan.device}.${100 + id}`, account: '', password: '', status: '未连接', ip: '-', uptime: '-' })
  } else {
    wan.sessions.push({ id, account: '', password: '', status: '未连接', ip: '-', uptime: '-' })
  }
}

function removeSession(wanIdx, sessIdx) {
  wanList.value[wanIdx].sessions.splice(sessIdx, 1)
  wanList.value[wanIdx].sessions.forEach((s, i) => s.id = i + 1)
  ElMessage.success('会话已删除')
}

function redial(wanIdx, sessIdx) {
  const s = wanList.value[wanIdx].sessions[sessIdx]
  s.status = '拨号中'
  s.ip = '-'
  s.uptime = '-'
  ElMessage.info(`会话 ${s.id} 正在重新拨号...`)
  setTimeout(() => {
    s.status = '已连接'
    s.ip = `100.64.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`
    s.uptime = '0天 0小时'
    ElMessage.success(`会话 ${s.id} 拨号成功`)
  }, 2000)
}
</script>

<style scoped>
.wan-card { border: 1px solid var(--el-border-color-light); border-radius: 8px; padding: 16px; margin-bottom: 16px; }
.wan-card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--layout-section-gap); }
.wan-title { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.wan-device { color: #909399; font-size: 13px; }
.wan-runtime { margin-bottom: var(--layout-section-gap); }
.session-list { margin-top: 12px; }
.session-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; font-size: 14px; font-weight: 500; }
.session-form-row { display: flex; gap: 8px; align-items: center; margin-bottom: 8px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
