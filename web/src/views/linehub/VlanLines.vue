<template>
  <PageContainer>
    <PageHeader title="VlanLines" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="VLAN线路管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, device: f.interface+'.'+f.vlanId, status:'UP'}); ElMessage.success('添加成功') }"
                  @edit="(r,f) => { Object.assign(r,f); r.device=f.interface+'.'+f.vlanId; ElMessage.success('修改成功') }"
                  @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
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
  { prop: 'device', label: 'VLAN设备', width: 110 },
  { prop: 'interface', label: '物理接口', width: 90 },
  { prop: 'vlanId', label: 'VLAN ID', width: 80 },
  { prop: 'account', label: '拨号账号', width: 160 },
  { prop: 'ip', label: '获得IP', width: 130 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === 'UP' ? 'success' : 'danger', width: 80 },
]
const formFields = [
  { prop: 'interface', label: '物理接口', type: 'select', options: ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5'] },
  { prop: 'vlanId', label: 'VLAN ID', type: 'input', required: true },
  { prop: 'account', label: '拨号账号', type: 'input', required: true },
  { prop: 'password', label: '密码', type: 'input', required: true },
]
let data = ref([
  { device: 'eth0.100', interface: 'eth0', vlanId: '100', account: 'vlan_user1@gd', ip: '100.64.2.50', status: 'UP' },
  { device: 'eth0.200', interface: 'eth0', vlanId: '200', account: 'vlan_user2@gd', ip: '100.64.2.51', status: 'UP' },
  { device: 'eth0.300', interface: 'eth0', vlanId: '300', account: 'vlan_user3@gd', ip: '100.64.2.52', status: 'UP' },
  { device: 'eth1.400', interface: 'eth1', vlanId: '400', account: 'vlan_user4@gd', ip: '100.64.3.10', status: 'UP' },
])
</script>
