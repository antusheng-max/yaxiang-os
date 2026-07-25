<template>
  <PageContainer>
    <PageHeader title="启动项" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="启动项管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="[]"
                  @add="() => {}"
                  @edit="() => {}"
                  @delete="() => {}"
                  :extra-buttons="[
                    { label: '启用', type: 'success', handler: (row) => { row.enabled = '是'; ElMessage.success(row.name + ' 已设为开机启动') } },
                    { label: '禁用', type: 'danger', handler: (row) => { row.enabled = '否'; ElMessage.warning(row.name + ' 已禁用自启') } }
                  ]"
                />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const columns = [
  { prop: 'name', label: '服务名称', width: 160 },
  { prop: 'desc', label: '描述', width: 200 },
  { prop: 'priority', label: '启动顺序', width: 90 },
  { prop: 'enabled', label: '开机自启', type: 'tag', tagType: (v) => v === '是' ? 'success' : 'danger', width: 90 },
  { prop: 'status', label: '当前状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'info', width: 90 },
]
let data = ref([
  { name: 'network', desc: '网络初始化', priority: '10', enabled: '是', status: '运行中' },
  { name: 'firewall4', desc: '防火墙', priority: '20', enabled: '是', status: '运行中' },
  { name: 'dnsmasq', desc: 'DNS/DHCP', priority: '30', enabled: '是', status: '运行中' },
  { name: 'sshd', desc: 'SSH服务', priority: '40', enabled: '是', status: '运行中' },
  { name: 'nginx', desc: 'Web服务器', priority: '50', enabled: '是', status: '运行中' },
  { name: 'wireguard', desc: 'WireGuard VPN', priority: '60', enabled: '是', status: '运行中' },
  { name: 'adguardhome', desc: 'AdGuardHome', priority: '70', enabled: '是', status: '运行中' },
  { name: 'samba4', desc: 'SMB共享', priority: '80', enabled: '否', status: '已停止' },
  { name: 'dockerd', desc: 'Docker守护进程', priority: '90', enabled: '否', status: '已停止' },
])
</script>
