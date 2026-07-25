<template>
  <PageContainer>
    <PageHeader title="网络设备" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="网络设备管理"
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
  { prop: 'name', label: '设备名称', width: 140 },
  { prop: 'type', label: '类型', type: 'tag', width: 120 },
  { prop: 'baseDevice', label: '基础设备', width: 120 },
  { prop: 'vlanId', label: 'VLAN ID', width: 90 },
  { prop: 'mtu', label: 'MTU', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === 'UP' ? 'success' : 'danger', width: 80 },
  { prop: 'mac', label: 'MAC地址', width: 160 },
]

const formFields = [
  { prop: 'name', label: '设备名称', type: 'input', required: true },
  { prop: 'type', label: '类型', type: 'select', options: ['网桥(bridge)', 'VLAN设备(802.1q)', 'VLAN过滤(bridge-vlan)', 'MACVLAN', 'VXLAN', 'Bonding'] },
  { prop: 'baseDevice', label: '基础设备', type: 'select', options: ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5'] },
  { prop: 'vlanId', label: 'VLAN ID', type: 'input' },
  { prop: 'mtu', label: 'MTU', type: 'input' },
]

const data = usePersistentRef('network:devices', [
  { name: 'br-lan', type: '网桥(bridge)', baseDevice: 'eth0 eth1', vlanId: '-', mtu: 1500, status: 'UP', mac: 'AA:BB:CC:DD:EE:01' },
  { name: 'eth0.100', type: 'VLAN设备(802.1q)', baseDevice: 'eth0', vlanId: '100', mtu: 1500, status: 'UP', mac: 'AA:BB:CC:DD:EE:01' },
  { name: 'eth0.200', type: 'VLAN设备(802.1q)', baseDevice: 'eth0', vlanId: '200', mtu: 1500, status: 'UP', mac: 'AA:BB:CC:DD:EE:01' },
  { name: 'eth1.300', type: 'VLAN设备(802.1q)', baseDevice: 'eth1', vlanId: '300', mtu: 1500, status: 'DOWN', mac: 'AA:BB:CC:DD:EE:02' },
  { name: 'br-wan', type: '网桥(bridge)', baseDevice: 'eth2 eth3', vlanId: '-', mtu: 1500, status: 'UP', mac: 'AA:BB:CC:DD:EE:03' },
])

const handleAdd = (form) => { data.value.push({ ...form, status: 'UP', mac: 'AA:BB:CC:DD:EE:FF' }); ElMessage.success('添加成功') }
const handleEdit = (row, form) => { Object.assign(row, form); ElMessage.success('修改成功') }
const handleDelete = (row) => { data.value = data.value.filter(i => i !== row); ElMessage.success('删除成功') }
</script>
