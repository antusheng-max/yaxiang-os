<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>LAN管理</h2>
      <p>管理 LAN 网络 — 绑定到汇聚组后，IPv6 前缀由汇聚组统一管理</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <div style="display:flex;justify-content:space-between;align-items:center">
              <span>LAN 网络列表</span>
              <el-button type="primary" @click="openAdd">添加LAN</el-button>
            </div>
            <StandardTable layout-mode="fill" :data="lans" border stripe size="default">
              <el-table-column prop="name" label="LAN名称" fixed />
              <el-table-column label="绑定设备">
                <template #default="{ row }">{{ getPortName(row.deviceId) }}</template>
              </el-table-column>
              <el-table-column label="所属汇聚组">
                <template #default="{ row }">
                  <el-tag v-if="row.aggregationGroupId" size="small" type="primary">{{ getGroupName(row.aggregationGroupId) }}</el-tag>
                  <span v-else style="color:#c0c4cc">—</span>
                </template>
              </el-table-column>
              <el-table-column label="IPv4网关">
                <template #default="{ row }">{{ row.ipv4Config?.gateway || '—' }}</template>
              </el-table-column>
              <el-table-column label="DHCPv4">
                <template #default="{ row }">
                  <span v-if="row.dhcpv4Config?.enabled">{{ row.dhcpv4Config.poolStart }} - {{ row.dhcpv4Config.poolEnd }}</span>
                  <span v-else style="color:#c0c4cc">禁用</span>
                </template>
              </el-table-column>
              <el-table-column label="IPv6模式">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.ipv6Config?.mode === 'aggregation_managed' ? 'warning' : 'info'">
                    {{ ipv6ModeLabel(row.ipv6Config?.mode) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="IPv6前缀">
                <template #default="{ row }">{{ row.ipv6Config?.prefix || '—' }}</template>
              </el-table-column>
              <el-table-column label="IPv6网关">
                <template #default="{ row }">{{ row.ipv6Config?.gateway || '—' }}</template>
              </el-table-column>
              <el-table-column label="RA/DHCPv6">
                <template #default="{ row }">
                  <span v-if="row.raConfig?.enabled">{{ row.raConfig.mode }}</span>
                  <span v-else style="color:#c0c4cc">—</span>
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
      
          <StandardModal size="standard" v-model="dialogVisible" :title="editId ? '编辑LAN' : '添加LAN'">
            <el-form :model="form" label-width="110px">
              <el-divider content-position="left">基础信息</el-divider>
              <el-form-item label="LAN名称" required>
                <el-input v-model="form.name" placeholder="如 Server-LAN" />
              </el-form-item>
              <el-form-item label="绑定设备" required>
                <el-select v-model="form.deviceId">
                  <el-option v-for="p in ports" :key="p.id" :label="p.name" :value="p.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="所属汇聚组">
                <el-select v-model="form.aggregationGroupId" clearable placeholder="不绑定">
                  <el-option v-for="g in groups" :key="g.id" :label="g.name" :value="g.id" />
                </el-select>
              </el-form-item>
      
              <el-divider content-position="left">IPv4</el-divider>
              <el-form-item label="网关地址">
                <el-input v-model="form.ipv4Gateway" placeholder="192.168.9.1/24" />
              </el-form-item>
              <el-form-item label="DHCPv4">
                <el-switch v-model="form.dhcpv4Enabled" />
              </el-form-item>
              <template v-if="form.dhcpv4Enabled">
                <el-form-item label="地址池起始">
                  <el-input v-model="form.poolStart" placeholder="192.168.9.10" />
                </el-form-item>
                <el-form-item label="地址池结束">
                  <el-input v-model="form.poolEnd" placeholder="192.168.9.200" />
                </el-form-item>
              </template>
      
              <el-divider content-position="left">IPv6</el-divider>
              <el-alert v-if="form.aggregationGroupId" type="warning" :closable="false">
                此 LAN 已绑定到汇聚组，IPv6 前缀由汇聚组管理，以下字段为只读展示。
              </el-alert>
              <el-form-item label="IPv6模式">
                <el-select v-model="form.ipv6Mode" :disabled="!!form.aggregationGroupId">
                  <el-option label="手动配置" value="manual" />
                  <el-option label="由汇聚组管理" value="aggregation_managed" />
                </el-select>
              </el-form-item>
              <el-form-item label="内部前缀">
                <el-input v-model="form.ipv6Prefix" placeholder="fd66:10:10::/64" :disabled="!!form.aggregationGroupId" />
              </el-form-item>
              <el-form-item label="IPv6网关">
                <el-input v-model="form.ipv6Gateway" placeholder="fd66:10:10::1" :disabled="!!form.aggregationGroupId" />
              </el-form-item>
              <el-form-item label="RA模式">
                <el-select v-model="form.raMode" :disabled="!!form.aggregationGroupId">
                  <el-option label="禁用" value="" />
                  <el-option label="托管 (managed)" value="managed" />
                  <el-option label="有状态 (stateful)" value="stateful" />
                  <el-option label="无状态 (stateless)" value="stateless" />
                </el-select>
              </el-form-item>
              <el-form-item label="DHCPv6">
                <el-switch v-model="form.dhcpv6Enabled" :disabled="!!form.aggregationGroupId" />
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="dialogVisible = false">取消</el-button>
              <el-button type="primary" :disabled="!form.name || !form.deviceId" @click="save">保存</el-button>
            </template>
          </StandardModal>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { lanService, physicalPortService, aggregationGroupService } from '../../services/dataService.js'

const lans = ref(lanService.list())
const ports = ref(physicalPortService.list())
const groups = ref(aggregationGroupService.list())

function getPortName(pid) { return physicalPortService.get(pid)?.name || '—' }
function getGroupName(gid) { return aggregationGroupService.get(gid)?.name || '—' }
function ipv6ModeLabel(m) {
  return { manual: '手动配置', aggregation_managed: '由汇聚组管理' }[m] || m
}

const dialogVisible = ref(false)
const editId = ref(null)
const form = reactive({
  name: '', deviceId: '', aggregationGroupId: '',
  ipv4Gateway: '', dhcpv4Enabled: true, poolStart: '', poolEnd: '',
  ipv6Mode: 'manual', ipv6Prefix: '', ipv6Gateway: '', raMode: '', dhcpv6Enabled: false
})

function openAdd() {
  editId.value = null
  Object.assign(form, { name: '', deviceId: '', aggregationGroupId: '', ipv4Gateway: '', dhcpv4Enabled: true, poolStart: '', poolEnd: '', ipv6Mode: 'manual', ipv6Prefix: '', ipv6Gateway: '', raMode: '', dhcpv6Enabled: false })
  dialogVisible.value = true
}
function openEdit(row) {
  editId.value = row.id
  Object.assign(form, {
    name: row.name, deviceId: row.deviceId, aggregationGroupId: row.aggregationGroupId || '',
    ipv4Gateway: row.ipv4Config?.gateway || '', dhcpv4Enabled: row.dhcpv4Config?.enabled || false,
    poolStart: row.dhcpv4Config?.poolStart || '', poolEnd: row.dhcpv4Config?.poolEnd || '',
    ipv6Mode: row.ipv6Config?.mode || 'manual', ipv6Prefix: row.ipv6Config?.prefix || '',
    ipv6Gateway: row.ipv6Config?.gateway || '', raMode: row.raConfig?.mode || '', dhcpv6Enabled: row.dhcpv6Config?.enabled || false
  })
  dialogVisible.value = true
}
function save() {
  const data = {
    name: form.name, deviceId: form.deviceId, aggregationGroupId: form.aggregationGroupId,
    ipv4Config: { gateway: form.ipv4Gateway },
    dhcpv4Config: { enabled: form.dhcpv4Enabled, poolStart: form.poolStart, poolEnd: form.poolEnd },
    ipv6Config: { mode: form.aggregationGroupId ? 'aggregation_managed' : form.ipv6Mode, prefix: form.ipv6Prefix, gateway: form.ipv6Gateway },
    raConfig: { enabled: !!form.raMode, mode: form.raMode },
    dhcpv6Config: { enabled: form.dhcpv6Enabled }
  }
  if (editId.value) {
    lanService.update(editId.value, data)
    ElMessage.success('LAN 已更新')
  } else {
    lanService.create(data)
    ElMessage.success('LAN 已添加')
  }
  lans.value = lanService.list()
  dialogVisible.value = false
}
function handleDelete(row) {
  try {
    lanService.remove(row.id)
    lans.value = lanService.list()
    ElMessage.success(`LAN「${row.name}」已删除`)
  } catch (e) {
    ElMessage.error(e.message)
  }
}
</script>
