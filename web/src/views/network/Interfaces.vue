<template>
  <PageContainer>
    <PageHeader title="网络接口" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="网络接口管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="handleAdd"
                  @edit="handleEdit"
                  @delete="handleDelete"
                />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import { usePersistentRef } from '../../composables/usePersistentRef.js'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const columns = [
  { prop: 'name', label: '接口名称', width: 100 },
  { prop: 'proto', label: '协议', type: 'tag', width: 100 },
  { prop: 'device', label: '绑定设备', width: 120 },
  { prop: 'ipaddr', label: 'IP地址', width: 140 },
  { prop: 'gateway', label: '网关', width: 140 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'info', width: 90 },
  { prop: 'uptime', label: '运行时间', width: 100 },
]

const formFields = [
  { prop: 'name', label: '接口名称', type: 'input', required: true },
  { prop: 'proto', label: '协议', type: 'select', options: ['static', 'dhcp', 'pppoe', 'dhcpv6', 'none'] },
  { prop: 'device', label: '绑定设备', type: 'select', options: ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5', 'br-lan', 'br-wan', 'eth0.100', 'eth0.200'] },
  { prop: 'ipaddr', label: 'IP地址', type: 'input' },
  { prop: 'netmask', label: '子网掩码', type: 'input' },
  { prop: 'gateway', label: '网关', type: 'input' },
]

const data = usePersistentRef('network:interfaces', [
  { name: 'loopback', proto: 'static', device: 'lo', ipaddr: '127.0.0.1/8', gateway: '-', status: '运行中', uptime: '15天 3小时' },
  { name: 'lan', proto: 'static', device: 'br-lan', ipaddr: '192.168.1.1/24', gateway: '-', status: '运行中', uptime: '15天 3小时' },
  { name: 'wan', proto: 'pppoe', device: 'eth2', ipaddr: '100.64.1.100/32', gateway: '100.64.1.1', status: '运行中', uptime: '12天 8小时' },
  { name: 'wan2', proto: 'dhcp', device: 'eth3', ipaddr: '10.0.0.5/24', gateway: '10.0.0.1', status: '运行中', uptime: '5天 2小时' },
  { name: 'wan3', proto: 'pppoe', device: 'eth0.100', ipaddr: '100.64.2.50/32', gateway: '100.64.2.1', status: '运行中', uptime: '3天 1小时' },
])

const handleAdd = (form) => { data.value.push({ ...form, status: '未启动', uptime: '-' }); ElMessage.success('添加成功') }
const handleEdit = (row, form) => { Object.assign(row, form); ElMessage.success('修改成功') }
const handleDelete = (row) => { data.value = data.value.filter(i => i !== row); ElMessage.success('删除成功') }
</script>
