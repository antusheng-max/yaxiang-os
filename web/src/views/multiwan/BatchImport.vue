<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>批量导入</h2>
      <p>批量添加宽带线路与接入通道，支持粘贴文本或上传 CSV</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-tabs v-model="activeTab" class="import-tabs">
                  <el-tab-pane label="粘贴文本" name="paste">
                    <CardToolbar class="tab-toolbar">
                      <el-button @click="downloadTemplate">下载导入模板</el-button>
                      <el-button type="primary" @click="preview" :disabled="!text">预览解析</el-button>
                    </CardToolbar>
                    <el-input
                      v-model="text"
                      type="textarea"
                      :rows="14"
                      placeholder="线路名称,物理端口,VLAN,账号,密码,MAC模式,IPv4,IPv6&#10;line-101-01,eth0,101,user1,pass1,shared,on,on&#10;line-101-02,eth0,102,user2,pass2,shared,on,on&#10;&#10;说明：&#10;- VLAN 留空表示 Untagged&#10;- MAC 模式：shared/auto/manual&#10;- IPv4/IPv6：on/off"
                    />
                  </el-tab-pane>
      
                  <el-tab-pane label="上传 CSV" name="upload">
                    <CardToolbar class="tab-toolbar">
                      <el-button @click="downloadTemplate">下载导入模板</el-button>
                    </CardToolbar>
                    <el-upload
                      drag
                      accept=".csv,text/csv"
                      :auto-upload="false"
                      :show-file-list="true"
                      :on-change="onFileChange"
                    >
                      <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
                      <div class="el-upload__text">拖拽 CSV 文件到此处，或<em>点击选择</em></div>
                      <template #tip>
                        <div class="upload-tip">CSV 格式：线路名称,物理端口,VLAN,账号,密码,MAC模式,IPv4,IPv6</div>
                      </template>
                    </el-upload>
                  </el-tab-pane>
                </el-tabs>
      
                <div v-if="previewList.length" class="preview-section">
                  <div class="section-header">
                    <h3>预览（共 {{ previewList.length }} 行）</h3>
                    <div class="section-actions">
                      <el-button type="primary" @click="doImport" :loading="importing">
                        执行导入
                      </el-button>
                    </div>
                  </div>
      
                   <el-alert
                     v-if="missCount"
                     type="warning"
                     :title="`存在 ${missCount} 行无法导入，请检查必填项、端口和 VLAN`"
                    :closable="false"
      
                  />
      
                  <StandardTable layout-mode="scroll" :data="previewList" size="default" border stripe>
                    <el-table-column type="index" label="#" />
                    <el-table-column label="线路名称" min-width="120">
                      <template #default="{ row }">
                        <span :class="{ 'dup-name': row._dupName }">{{ row.name || '—' }}</span>
                      </template>
                    </el-table-column>
                    <el-table-column prop="port" label="物理端口" min-width="100" />
                    <el-table-column label="VLAN" min-width="90">
                      <template #default="{ row }">
                        {{ row.vlan || 'Untagged' }}
                      </template>
                    </el-table-column>
                    <el-table-column prop="account" label="账号" min-width="140" />
                    <el-table-column label="密码" min-width="100">
                      <template #default="{ row }">{{ row.password ? '••••••••' : '—' }}</template>
                    </el-table-column>
                    <el-table-column prop="macMode" label="MAC模式" min-width="100" />
                    <el-table-column prop="ipv4" label="IPv4" min-width="80" />
                    <el-table-column prop="ipv6" label="IPv6" min-width="80" />
                    <el-table-column label="状态" min-width="140">
                      <template #default="{ row }">
                        <el-tag v-if="row._dupName" type="danger" size="small">名称重复</el-tag>
                        <el-tag v-if="row._missing" type="warning" size="small">字段缺失</el-tag>
                        <el-tag v-if="row._invalidPort" type="danger" size="small">端口不存在</el-tag>
                        <el-tag v-if="row._invalidVlan" type="danger" size="small">VLAN 无效</el-tag>
                        <el-tag v-if="!row._dupName && !row._missing && !row._invalidPort && !row._invalidVlan" type="success" size="small">可导入</el-tag>
                      </template>
                    </el-table-column>
                  </StandardTable>
      
                  <div class="dup-hint">
                    <el-icon><InfoFilled /></el-icon>
                    重复 VLAN 不报错（允许同 VLAN 多账号）；重复名称将被红色标记，不会导入。
                  </div>
                </div>
      
                <div v-if="summary" class="summary-section">
                  <h3>导入完成摘要</h3>
                  <el-descriptions :column="2" border>
                    <el-descriptions-item label="新建接入通道">{{ summary.channels }}</el-descriptions-item>
                    <el-descriptions-item label="新增线路">{{ summary.instances }}</el-descriptions-item>
                    <el-descriptions-item label="启用 IPv4">{{ summary.ipv4Enabled }}</el-descriptions-item>
                    <el-descriptions-item label="启用 IPv6">{{ summary.ipv6Enabled }}</el-descriptions-item>
                  </el-descriptions>
                </div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled, InfoFilled } from '@element-plus/icons-vue'
import {
  accessChannelService,
  dialInstanceService,
  physicalPortService,
} from '../../services/dataService.js'

const activeTab = ref('paste')
const text = ref('')
const previewList = ref([])
const missCount = ref(0)
const importing = ref(false)
const summary = ref(null)

const HEADER = ['name', 'port', 'vlan', 'account', 'password', 'macMode', 'ipv4', 'ipv6']

function parseLine(line) {
  const parts = line.split(',').map(s => s.trim())
  if (parts.length < 5) return null
  const obj = {}
  HEADER.forEach((k, i) => { obj[k] = parts[i] || '' })
  return obj
}

function preview() {
  previewList.value = []
  missCount.value = 0
  summary.value = null
  const lines = text.value.split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#') && !l.startsWith('线路名称'))
  const parsed = []
  const nameSet = new Map()
  const existingNames = new Set(dialInstanceService.list().map(item => item.name))
  for (const line of lines) {
    const obj = parseLine(line)
    if (!obj) continue
    const missing = !obj.name || !obj.port || !obj.account || !obj.password
    obj._missing = missing
    obj._invalidPort = Boolean(obj.port) && !physicalPortService.getByName(obj.port)
    const vlanId = obj.vlan === '' ? null : Number(obj.vlan)
    obj._invalidVlan = vlanId != null && (
      !Number.isInteger(vlanId) || vlanId < 1 || vlanId > 4094
    )
    if (missing || obj._invalidPort || obj._invalidVlan) missCount.value++
    obj._dupName = false
    parsed.push(obj)
    nameSet.set(obj.name, (nameSet.get(obj.name) || 0) + 1)
  }
  parsed.forEach(o => {
    if (o.name && (nameSet.get(o.name) > 1 || existingNames.has(o.name))) {
      o._dupName = true
    }
  })
  previewList.value = parsed
  if (!parsed.length) {
    ElMessage.warning('未解析到有效数据')
  } else {
    ElMessage.success(`解析完成，共 ${parsed.length} 行`)
  }
}

function onFileChange(file) {
  const reader = new FileReader()
  reader.onload = (e) => {
    text.value = e.target.result
    activeTab.value = 'paste'
    ElMessage.success('文件已加载，点击预览解析')
  }
  reader.readAsText(file.raw)
}

function downloadTemplate() {
  const csv = '线路名称,物理端口,VLAN,账号,密码,MAC模式,IPv4,IPv6\n'
    + 'line-101-01,eth0,101,user1,pass1,shared,on,on\n'
    + 'line-101-02,eth0,102,user2,pass2,shared,on,on\n'
    + 'line-101-03,eth1,,user3,pass3,auto,on,off\n'
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'pppoe-import-template.csv'
  a.click()
  URL.revokeObjectURL(url)
}

async function doImport() {
  const valid = previewList.value.filter(row => (
    !row._dupName
    && !row._missing
    && !row._invalidPort
    && !row._invalidVlan
  ))
  if (!valid.length) {
    ElMessage.warning('没有可导入的数据')
    return
  }
  importing.value = true
  try {
    let channelsCreated = 0
    let instancesCreated = 0
    let ipv4Enabled = 0
    let ipv6Enabled = 0
    for (const row of valid) {
      const port = physicalPortService.getByName(row.port)
      const vlanId = row.vlan === '' ? null : Number(row.vlan)
      let channel = accessChannelService.list().find(item => (
        item.physicalPortId === port.id
        && item.vlanId === vlanId
      ))
      if (!channel) {
        channel = await accessChannelService.create({
          name: vlanId == null ? `${row.port}-untagged` : `channel-${vlanId}`,
          physicalPortId: port.id,
          tagMode: vlanId == null ? 'untagged' : 'dot1q',
          vlanId,
          deviceName: vlanId == null ? row.port : `${row.port}.${vlanId}`,
          mtu: 1500,
          macMode: row.macMode || 'shared',
          status: 'down',
        })
        channelsCreated++
      }
      const inst = await dialInstanceService.create({
        name: row.name,
        accessChannelId: channel.id,
        username: row.account,
        password: row.password,
        macMode: row.macMode || 'shared',
        enabled: true,
        autoDial: true,
        redialOnDisconnect: true,
        ipv4Config: {
          autoAcquire: row.ipv4 !== 'off',
          acquireDns: true,
          customDns: '',
          defaultRoute: true,
          metric: 10,
        },
        ipv6Config: {
          enabled: row.ipv6 !== 'off',
          enableIpv6cp: true,
          dhcpv6Client: true,
          iaNa: 'auto',
          iaPd: 'auto',
          prefixLength: 'auto',
          acquireDns: true,
          defaultRoute: true,
          autoUpdatePrefix: true,
        },
      })
      instancesCreated++
      if (inst.ipv4Config.autoAcquire) ipv4Enabled++
      if (inst.ipv6Config.enabled) ipv6Enabled++
    }
    summary.value = {
      channels: channelsCreated,
      instances: instancesCreated,
      ipv4Enabled,
      ipv6Enabled
    }
    ElMessage.success(`已导入 ${instancesCreated} 条线路`)
    previewList.value = []
    text.value = ''
  } catch (e) {
    ElMessage.error('导入失败：' + e.message)
  } finally {
    importing.value = false
  }
}
</script>

<style scoped>
.upload-tip { font-size: 13px; color: #909399; }
.preview-section { margin-top: 24px; }
.section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--layout-section-gap); }
.section-header h3 { font-size: 16px; margin: 0; }
.dup-name { color: #f56c6c; font-weight: 600; }
.dup-hint { margin-top: 8px; font-size: 13px; color: #909399; display: flex; align-items: center; gap: 4px; }
.summary-section { margin-top: 24px; }
.summary-section h3 { font-size: 16px; margin: 0 0 12px 0; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-upload-dragger) { padding: 30px; }
</style>
