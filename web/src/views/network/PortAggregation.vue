<template>
  <PageContainer>
    <PageHeader><h2>端口聚合管理</h2>
    <p style="color:var(--el-text-color-secondary);font-size:13px">
      管理 WAN 网络来源与 LAN 接口绑定 — 服务器/电脑通过绑定的 WAN 出口上网
    </p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <!-- ===== WAN 网络来源 ===== -->
          <SectionCard shadow="never" class="section-card">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span><strong>WAN 网络来源</strong> — 提供互联网接入</span>
                <el-button type="primary" size="small" @click="openAddWan">+ 添加 WAN</el-button>
              </div>
            </template>
            <div v-if="wanSources.length === 0" class="empty-tip">暂无 WAN，请点击右上角添加</div>
            <transition-group v-else name="card-list" tag="div" class="wan-source-row">
              <div v-for="wan in wanSources" :key="wan.id" :class="['wan-source-card', 'wan-color-' + wan.color, wan.tagType]">
                <div class="live-dot" v-if="wan.rx"></div>
                <div class="ws-title">
                  <el-tag :type="wan.tagType" size="small" effect="dark">WAN</el-tag>
                  <strong>{{ wan.name }}</strong>
                </div>
                <div class="ws-info">端口: {{ wan.port }} · {{ wan.method }}</div>
                <div class="ws-info">IP: {{ wan.ip }}</div>
                <div class="ws-info">带宽: {{ wan.bandwidth }}</div>
                <div class="ws-stat">
                  <span>↓ {{ wan.rx }}</span>
                  <span>↑ {{ wan.tx }}</span>
                </div>
                <div class="ws-actions">
                  <el-button size="small" type="primary" link @click="openEditWan(wan)">编辑</el-button>
                  <el-button size="small" type="danger" link @click="deleteWan(wan)">删除</el-button>
                </div>
              </div>
            </transition-group>
          </SectionCard>
      
          <div class="flow-arrow">
            <span class="flow-arrow-inner">⬇ 聚合绑定 ⬇</span>
          </div>
      
          <!-- ===== LAN 接口绑定 ===== -->
          <SectionCard shadow="never" class="section-card">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span><strong>LAN 接口绑定</strong> — 选择 WAN 出口</span>
                <el-button type="primary" size="small" @click="openAddLan">+ 添加 LAN</el-button>
              </div>
            </template>
            <StandardTable layout-mode="scroll" :data="lanBindings" border stripe size="small" row-class-name="lan-row">
              <el-table-column prop="name" label="LAN 名称" />
              <el-table-column label="绑定设备">
                <template #default="{ row }">{{ row.device }}</template>
              </el-table-column>
              <el-table-column label="子网">
                <template #default="{ row }">{{ row.subnet }}</template>
              </el-table-column>
              <el-table-column label="绑定 WAN">
                <template #default="{ row }">
                  <el-select v-model="row.bindWan" size="small" @change="v => onBindChange(row, v)">
                    <el-option label="— 未绑定 —" value="" />
                    <el-option v-for="w in wanSources" :key="w.id" :label="w.name + ' (' + w.port + ')'" :value="w.name" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="连接设备">
                <template #default="{ row }">{{ row.connectedDevices }}</template>
              </el-table-column>
              <el-table-column label="聚合带宽">
                <template #default="{ row }">
                  <span v-if="row.bindWan" class="agg-bandwidth">{{ row.aggBandwidth }}</span>
                  <span v-else style="color:#c0c4cc">—</span>
                </template>
              </el-table-column>
              <el-table-column label="状态">
                <template #default="{ row }">
                  <el-tag :type="row.bindWan ? 'success' : 'info'" size="small" effect="row.bindWan ? 'light' : 'plain'">
                    {{ row.bindWan ? '已聚合' : '未绑定' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" fixed="right">
                <template #default="{ row }">
                  <el-button size="small" type="primary" link @click="openEditLan(row)">编辑</el-button>
                  <el-button size="small" type="danger" link @click="deleteLan(row)">删除</el-button>
                </template>
              </el-table-column>
            </StandardTable>
          </SectionCard>
      
          <div class="flow-arrow">
            <span class="flow-arrow-inner">⬇ 设备接入 ⬇</span>
          </div>
      
          <!-- ===== 接入设备 ===== -->
          <SectionCard shadow="never" class="section-card">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span><strong>接入设备</strong> — 通过已绑定的 LAN 上网</span>
                <el-button type="primary" size="small" @click="openAddDevice">+ 添加设备</el-button>
              </div>
            </template>
            <div v-if="devices.length === 0" class="empty-tip">暂无设备，请点击右上角添加</div>
            <transition-group v-else name="card-list" tag="div" class="device-row">
              <div v-for="dev in devices" :key="dev.id" class="device-card">
                <div class="dev-icon">🖥</div>
                <div class="dev-name">{{ dev.name }}</div>
                <div class="dev-info">接入: {{ dev.connectLan }}</div>
                <div class="dev-info">IP: {{ dev.ip }}</div>
                <div class="dev-info">网关: {{ dev.gateway }}</div>
                <div class="dev-info">绑定 WAN: <el-tag size="small" type="primary">{{ dev.bindWan }}</el-tag></div>
                <div class="dev-status">
                  <el-tag :type="dev.status === '在线' ? 'success' : 'danger'" size="small" class="status-tag">
                    <span :class="['status-dot', dev.status === '在线' ? 'online' : 'offline']"></span>
                    {{ dev.status }}
                  </el-tag>
                  <span style="font-size:11px;color:var(--el-text-color-secondary)">{{ dev.traffic }}</span>
                </div>
                <div class="dev-actions">
                  <el-button size="small" type="primary" link @click="openEditDevice(dev)">编辑</el-button>
                  <el-button size="small" type="danger" link @click="deleteDevice(dev)">删除</el-button>
                </div>
              </div>
            </transition-group>
          </SectionCard>
      
          <!-- ===== WAN 编辑对话框 ===== -->
          <StandardModal size="standard" v-model="wanDialog" :title="wanEdit.id ? '编辑 WAN' : '添加 WAN'">
            <el-form :model="wanEdit" label-width="100px" size="default">
              <el-form-item label="名称" required>
                <el-input v-model="wanEdit.name" placeholder="如 WAN_POOL" />
              </el-form-item>
              <el-form-item label="物理端口" required>
                <el-select v-model="wanEdit.port">
                  <el-option v-for="p in portOptions" :key="p" :label="p" :value="p" />
                </el-select>
              </el-form-item>
              <el-form-item label="连接方式" required>
                <el-select v-model="wanEdit.method">
                  <el-option label="PPPoE 单线" value="PPPoE 单线" />
                  <el-option label="DHCP 自动获取" value="DHCP" />
                  <el-option label="静态 IP" value="静态IP" />
                  <el-option label="VLAN × N 聚合" value="VLAN × N 聚合" />
                </el-select>
              </el-form-item>
              <el-form-item label="IP 地址">
                <el-input v-model="wanEdit.ip" placeholder="如 100.64.0.1/24" />
              </el-form-item>
              <el-form-item label="带宽">
                <el-input v-model="wanEdit.bandwidth" placeholder="如 10 × 100Mbps" />
              </el-form-item>
              <el-form-item label="下行流量">
                <el-input v-model="wanEdit.rx" placeholder="如 520 Mbps" />
              </el-form-item>
              <el-form-item label="上行流量">
                <el-input v-model="wanEdit.tx" placeholder="如 280 Mbps" />
              </el-form-item>
              <el-form-item label="颜色标签">
                <el-select v-model="wanEdit.color">
                  <el-option label="蓝色 (primary)" value="blue" />
                  <el-option label="绿色 (success)" value="green" />
                  <el-option label="橙色 (warning)" value="orange" />
                  <el-option label="紫色 (info)" value="purple" />
                </el-select>
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="wanDialog = false">取消</el-button>
              <el-button type="primary" :disabled="!wanEdit.name || !wanEdit.port" @click="saveWan">保存</el-button>
            </template>
          </StandardModal>
      
          <!-- ===== LAN 编辑对话框 ===== -->
          <StandardModal size="standard" v-model="lanDialog" :title="lanEdit.id ? '编辑 LAN' : '添加 LAN'">
            <el-form :model="lanEdit" label-width="100px" size="default">
              <el-form-item label="LAN 名称" required>
                <el-input v-model="lanEdit.name" placeholder="如 管理网络" />
              </el-form-item>
              <el-form-item label="绑定设备" required>
                <el-select v-model="lanEdit.device">
                  <el-option v-for="d in deviceOptions" :key="d" :label="d" :value="d" />
                </el-select>
              </el-form-item>
              <el-form-item label="子网" required>
                <el-input v-model="lanEdit.subnet" placeholder="如 192.168.3.0/24" />
              </el-form-item>
              <el-form-item label="绑定 WAN">
                <el-select v-model="lanEdit.bindWan">
                  <el-option label="— 未绑定 —" value="" />
                  <el-option v-for="w in wanSources" :key="w.id" :label="w.name + ' (' + w.port + ')'" :value="w.name" />
                </el-select>
              </el-form-item>
              <el-form-item label="连接设备">
                <el-input v-model="lanEdit.connectedDevices" placeholder="如 管理电脑(1台)" />
              </el-form-item>
              <el-form-item label="聚合带宽">
                <el-input v-model="lanEdit.aggBandwidth" placeholder="如 10 × 100Mbps" />
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="lanDialog = false">取消</el-button>
              <el-button type="primary" :disabled="!lanEdit.name || !lanEdit.device || !lanEdit.subnet" @click="saveLan">保存</el-button>
            </template>
          </StandardModal>
      
          <!-- ===== 设备编辑对话框 ===== -->
          <StandardModal size="standard" v-model="devDialog" :title="devEdit.id ? '编辑设备' : '添加设备'">
            <el-form :model="devEdit" label-width="100px" size="default">
              <el-form-item label="设备名称" required>
                <el-input v-model="devEdit.name" placeholder="如 Web Server" />
              </el-form-item>
              <el-form-item label="接入 LAN" required>
                <el-select v-model="devEdit.connectLan">
                  <el-option v-for="l in lanBindings" :key="l.id" :label="l.name" :value="l.name" />
                </el-select>
              </el-form-item>
              <el-form-item label="IP 地址" required>
                <el-input v-model="devEdit.ip" placeholder="如 10.10.10.10/24" />
              </el-form-item>
              <el-form-item label="网关">
                <el-input v-model="devEdit.gateway" placeholder="如 10.10.10.1" />
              </el-form-item>
              <el-form-item label="状态">
                <el-select v-model="devEdit.status">
                  <el-option label="在线" value="在线" />
                  <el-option label="离线" value="离线" />
                </el-select>
              </el-form-item>
              <el-form-item label="流量">
                <el-input v-model="devEdit.traffic" placeholder="如 ↓ 128 Mbps / ↑ 45 Mbps" />
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="devDialog = false">取消</el-button>
              <el-button type="primary" :disabled="!devEdit.name || !devEdit.connectLan || !devEdit.ip" @click="saveDevice">保存</el-button>
            </template>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { usePersistentRef } from '../../composables/usePersistentRef.js'

// WAN 颜色映射
function tagTypeFor(color) {
  if (color === 'blue') return 'primary'
  if (color === 'green') return 'success'
  if (color === 'orange') return 'warning'
  return 'info'
}

// 持久化数据
const wanSources = usePersistentRef('agg:wan:list', [
  { id: 1, name: 'WAN_POOL', port: 'eth1', method: 'VLAN × 10 聚合', color: 'blue', tagType: 'primary',
    ip: '100.64.0.1/24', bandwidth: '10 × 100Mbps', rx: '520 Mbps', tx: '280 Mbps' },
  { id: 2, name: 'WAN_MAIN', port: 'eth0', method: 'PPPoE 单线', color: 'green', tagType: 'success',
    ip: '100.64.1.100/32', bandwidth: '100Mbps', rx: '45 Mbps', tx: '12 Mbps' },
])
const lanBindings = usePersistentRef('agg:lan:list', [
  { id: 1, name: '管理网络', device: 'eth0', subnet: '192.168.3.0/24', bindWan: 'WAN_POOL',
    connectedDevices: '管理电脑(1台)', aggBandwidth: '10 × 100Mbps' },
  { id: 2, name: '服务器网络', device: 'eth2(万兆)', subnet: '10.10.10.0/24', bindWan: 'WAN_POOL',
    connectedDevices: 'Web Server / NAS (2台)', aggBandwidth: '10 × 100Mbps' },
  { id: 3, name: '备用LAN', device: 'br-lan', subnet: '192.168.10.0/24', bindWan: '',
    connectedDevices: '—', aggBandwidth: '—' },
])
const devices = usePersistentRef('agg:device:list', [
  { id: 1, name: '管理电脑', connectLan: '管理网络', ip: '192.168.3.100/24', gateway: '192.168.3.1',
    bindWan: 'WAN_POOL', status: '在线', traffic: '↓ 2.3 Mbps / ↑ 0.8 Mbps' },
  { id: 2, name: 'Web Server', connectLan: '服务器网络', ip: '10.10.10.10/24', gateway: '10.10.10.1',
    bindWan: 'WAN_POOL', status: '在线', traffic: '↓ 128.5 Mbps / ↑ 45.2 Mbps' },
  { id: 3, name: 'NAS Storage', connectLan: '服务器网络', ip: '10.10.10.11/24', gateway: '10.10.10.1',
    bindWan: 'WAN_POOL', status: '在线', traffic: '↓ 56.8 Mbps / ↑ 120.3 Mbps' },
])

// 工具: 从子网字符串解析前三段与前缀
function parseSubnet(subnet) {
  const m = String(subnet || '').match(/^(\d+)\.(\d+)\.(\d+)\.\d+\/(\d+)$/)
  if (!m) return null
  return { base: m[1] + '.' + m[2] + '.' + m[3], prefix: m[4] }
}
// 根据 LAN 自动生成网关
function gatewayFromLan(lanName) {
  const lan = lanBindings.value.find(l => l.name === lanName)
  if (!lan) return ''
  const p = parseSubnet(lan.subnet)
  return p ? p.base + '.1' : ''
}
// 根据 LAN 子网自动生成一个未占用的设备 IP
function deviceIpFromLan(lanName) {
  const lan = lanBindings.value.find(l => l.name === lanName)
  if (!lan) return ''
  const p = parseSubnet(lan.subnet)
  if (!p) return ''
  const prefix = p.base + '.'
  const used = devices.value
    .filter(d => d.connectLan === lanName && d.ip.startsWith(prefix))
    .map(d => parseInt(((d.ip.split('/')[0]) || '0').split('.').pop(), 10))
  let offset = 10
  while (used.includes(offset) && offset < 250) offset++
  return p.base + '.' + offset + '/' + p.prefix
}

// 选项
const portOptions = ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5']
const deviceOptions = ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5', 'br-lan', 'eth0.100', 'eth0.200']

// 移动端检测
const windowWidth = ref(window.innerWidth)
function onResize() { windowWidth.value = window.innerWidth }
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))
const isMobile = () => windowWidth.value < 600

// ===== WAN 增删改 =====
const wanDialog = ref(false)
const wanEdit = reactive({ id: null, name: '', port: 'eth1', method: 'VLAN × N 聚合',
  ip: '', bandwidth: '', rx: '', tx: '', color: 'blue' })

function openAddWan() {
  Object.assign(wanEdit, { id: null, name: '', port: 'eth1', method: 'VLAN × N 聚合',
    ip: '', bandwidth: '', rx: '', tx: '', color: 'blue' })
  wanDialog.value = true
}
function openEditWan(wan) {
  Object.assign(wanEdit, wan)
  wanDialog.value = true
}
function saveWan() {
  const newWan = {
    id: wanEdit.id || Date.now(),
    name: wanEdit.name, port: wanEdit.port, method: wanEdit.method,
    ip: wanEdit.ip, bandwidth: wanEdit.bandwidth, rx: wanEdit.rx, tx: wanEdit.tx,
    color: wanEdit.color, tagType: tagTypeFor(wanEdit.color),
  }
  if (wanEdit.id) {
    const idx = wanSources.value.findIndex(w => w.id === wanEdit.id)
    if (idx >= 0) wanSources.value[idx] = newWan
    ElMessage.success('WAN 已更新')
  } else {
    wanSources.value.push(newWan)
    ElMessage.success('WAN 已添加')
  }
  wanDialog.value = false
}
function deleteWan(wan) {
  wanSources.value = wanSources.value.filter(w => w.id !== wan.id)
  // 解绑使用此WAN的LAN
  lanBindings.value.forEach(l => {
    if (l.bindWan === wan.name) { l.bindWan = ''; l.aggBandwidth = '—' }
  })
  // 更新设备的bindWan
  devices.value.forEach(d => {
    if (d.bindWan === wan.name) d.bindWan = '—'
  })
  ElMessage.success(`WAN「${wan.name}」已删除`)
}

function onBindChange(row, val) {
  if (val) {
    const wan = wanSources.value.find(w => w.name === val)
    row.aggBandwidth = wan ? wan.bandwidth : '10 × 100Mbps'
    // 更新设备上的 bindWan 显示
    devices.value.forEach(d => {
      if (d.connectLan === row.name) d.bindWan = val
    })
    ElMessage.success(row.name + ' 已聚合到 ' + val)
  } else {
    row.aggBandwidth = '—'
    devices.value.forEach(d => {
      if (d.connectLan === row.name) d.bindWan = '—'
    })
    ElMessage.info(row.name + ' 已解绑')
  }
}

// ===== LAN 增删改 =====
const lanDialog = ref(false)
const lanEdit = reactive({ id: null, name: '', device: 'eth0', subnet: '192.168.1.0/24',
  bindWan: '', connectedDevices: '', aggBandwidth: '—' })

function openAddLan() {
  Object.assign(lanEdit, { id: null, name: '', device: 'eth0', subnet: '192.168.1.0/24',
    bindWan: '', connectedDevices: '', aggBandwidth: '—' })
  lanDialog.value = true
}
function openEditLan(lan) {
  Object.assign(lanEdit, lan)
  lanDialog.value = true
}
function saveLan() {
  const newLan = {
    id: lanEdit.id || Date.now(),
    name: lanEdit.name, device: lanEdit.device, subnet: lanEdit.subnet,
    bindWan: lanEdit.bindWan, connectedDevices: lanEdit.connectedDevices,
    aggBandwidth: lanEdit.aggBandwidth || (lanEdit.bindWan ? '10 × 100Mbps' : '—'),
  }
  if (lanEdit.id) {
    const idx = lanBindings.value.findIndex(l => l.id === lanEdit.id)
    if (idx >= 0) lanBindings.value[idx] = newLan
    ElMessage.success('LAN 已更新')
  } else {
    lanBindings.value.push(newLan)
    ElMessage.success('LAN 已添加')
  }
  lanDialog.value = false
}
function deleteLan(lan) {
  lanBindings.value = lanBindings.value.filter(l => l.id !== lan.id)
  devices.value.forEach(d => {
    if (d.connectLan === lan.name) d.connectLan = '—'
  })
  ElMessage.success(`LAN「${lan.name}」已删除`)
}

// ===== 设备 增删改 =====
const devDialog = ref(false)
const devEdit = reactive({ id: null, name: '', connectLan: '', ip: '', gateway: '',
  bindWan: '—', status: '在线', traffic: '—' })

function openAddDevice() {
  const lanName = lanBindings.value[0]?.name || ''
  Object.assign(devEdit, { id: null, name: '', connectLan: lanName,
    ip: deviceIpFromLan(lanName), gateway: gatewayFromLan(lanName),
    bindWan: '—', status: '在线', traffic: '—' })
  devDialog.value = true
}
function openEditDevice(dev) {
  Object.assign(devEdit, dev)
  devDialog.value = true
}
function saveDevice() {
  // 根据接入的LAN自动推导 bindWan 和 gateway
  const lan = lanBindings.value.find(l => l.name === devEdit.connectLan)
  const bindWan = lan && lan.bindWan ? lan.bindWan : '—'
  const newDev = {
    id: devEdit.id || Date.now(),
    name: devEdit.name, connectLan: devEdit.connectLan, ip: devEdit.ip,
    gateway: devEdit.gateway, bindWan: bindWan, status: devEdit.status, traffic: devEdit.traffic,
  }
  if (devEdit.id) {
    const idx = devices.value.findIndex(d => d.id === devEdit.id)
    if (idx >= 0) devices.value[idx] = newDev
    ElMessage.success('设备已更新')
  } else {
    devices.value.push(newDev)
    ElMessage.success('设备已添加')
  }
  devDialog.value = false
}
// 切换接入 LAN 时自动补全 IP/网关
watch(() => devEdit.connectLan, (newLan, oldLan) => {
  if (newLan && newLan !== oldLan) {
    devEdit.gateway = gatewayFromLan(newLan)
    devEdit.ip = deviceIpFromLan(newLan)
  }
})

function deleteDevice(dev) {
  devices.value = devices.value.filter(d => d.id !== dev.id)
  ElMessage.success(`设备「${dev.name}」已删除`)
}
</script>

<style scoped>
.section-card { margin-bottom: 8px; }
.empty-tip { text-align: center; padding: 40px 0; color: var(--el-text-color-secondary); font-size: 14px; animation: fadeInUp 0.5s ease; }

/* WAN 卡片 */
.wan-source-row { display: flex; gap: 14px; flex-wrap: wrap; }
.wan-source-card { width: 280px; border: 1px solid var(--el-border-color-light); border-radius: 12px; padding: 14px; flex: 1; min-width: 240px; position: relative; transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); cursor: default; }
.wan-source-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
.wan-color-blue { background: linear-gradient(135deg, #ecf5ff 0%, #f5faff 100%); }
.wan-color-green { background: linear-gradient(135deg, #f0f9eb 0%, #f7fcf4 100%); }
.wan-color-orange { background: linear-gradient(135deg, #fdf6ec 0%, #fffbf5 100%); }
.wan-color-purple { background: linear-gradient(135deg, #f5f0ff 0%, #faf8ff 100%); }

/* 实时闪烁点 */
.live-dot { position: absolute; top: 10px; right: 10px; width: 8px; height: 8px; border-radius: 50%; background: #67c23a; box-shadow: 0 0 0 0 rgba(103, 194, 58, 0.7); animation: pulse-dot 1.8s infinite; }

.ws-title { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; font-size: 15px; }
.ws-info { font-size: 12px; padding: 2px 0; color: var(--el-text-color-regular); }
.ws-stat { margin-top: 8px; display: flex; gap: 16px; font-size: 12px; color: #409eff; font-weight: 500; }
.ws-actions { margin-top: 10px; padding-top: 8px; border-top: 1px dashed var(--el-border-color-light); display: flex; gap: 4px; }

/* 流程箭头动画 */
.flow-arrow { text-align: center; padding: 10px 0; font-size: 14px; color: var(--el-text-color-secondary); font-weight: 500; }
.flow-arrow-inner { display: block; animation: flow-bounce 1.6s ease-in-out infinite; }

/* 聚合带宽高亮 */
.agg-bandwidth { color: #67c23a; font-weight: 600; animation: fadeIn 0.4s ease; }

/* 设备卡片 */
.device-row { display: flex; gap: 14px; flex-wrap: wrap; }
.device-card { width: 220px; border: 1px solid var(--el-border-color-light); border-radius: 12px; padding: 14px; background: var(--el-fill-color-lighter); flex: 1; min-width: 200px; transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.device-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.08); background: var(--el-fill-color); }
.dev-icon { font-size: 28px; text-align: center; transition: transform 0.3s ease; }
.device-card:hover .dev-icon { transform: scale(1.1) rotate(-3deg); }
.dev-name { text-align: center; font-weight: 600; font-size: 14px; margin: 6px 0; }
.dev-info { font-size: 12px; padding: 2px 0; color: var(--el-text-color-regular); }
.dev-status { margin-top: 8px; display: flex; justify-content: space-between; align-items: center; }
.dev-actions { margin-top: 10px; padding-top: 8px; border-top: 1px dashed var(--el-border-color-light); display: flex; justify-content: center; gap: 8px; }

/* 状态指示灯 */
.status-tag { display: inline-flex; align-items: center; gap: 4px; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; display: block; }
.status-dot.online { background: #67c23a; animation: pulse-dot 1.5s infinite; }
.status-dot.offline { background: #f56c6c; }

/* 列表过渡动画 */
.card-list-enter-active, .card-list-leave-active { transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.card-list-enter-from, .card-list-leave-to { opacity: 0; transform: translateY(16px) scale(0.96); }
.card-list-leave-active { position: absolute; }
.card-list-move { transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1); }

/* LAN 表格行 hover */
:deep(.lan-row:hover td) { transition: background 0.25s ease; }

/* 关键帧 */
@keyframes pulse-dot {
  0% { box-shadow: 0 0 0 0 rgba(103, 194, 58, 0.7); }
  70% { box-shadow: 0 0 0 8px rgba(103, 194, 58, 0); }
  100% { box-shadow: 0 0 0 0 rgba(103, 194, 58, 0); }
}
@keyframes flow-bounce {
  0%, 100% { transform: translateY(0); opacity: 0.7; }
  50% { transform: translateY(5px); opacity: 1; }
}
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
