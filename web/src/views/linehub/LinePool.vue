<template>
  <PageContainer>
    <PageHeader title="LinePool" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="多WAN线路池"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'在线', sessions:1}); ElMessage.success('添加成功') }"
                  @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
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
  { prop: 'name', label: '线路名称', width: 120 },
  { prop: 'type', label: '接入类型', type: 'tag', width: 110 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'isp', label: '运营商', width: 80 },
  { prop: 'bandwidth', label: '带宽', width: 80 },
  { prop: 'sessions', label: '拨号数', width: 70 },
  { prop: 'ip', label: '出口IP', width: 130 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '在线' ? 'success' : 'danger', width: 80 },
]
const formFields = [
  { prop: 'name', label: '线路名称', type: 'input', required: true },
  { prop: 'type', label: '接入类型', type: 'select', options: ['PPPoE拨号', 'VLAN虚拟拨号', 'DHCP', '静态IP'] },
  { prop: 'interface', label: '物理接口', type: 'select', options: ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5'] },
  { prop: 'isp', label: '运营商', type: 'select', options: ['电信', '联通', '移动', '其他'] },
  { prop: 'bandwidth', label: '带宽(Mbps)', type: 'input' },
]
let data = ref([
  { name: '电信主线', type: 'PPPoE拨号', interface: 'eth2', isp: '电信', bandwidth: '500M', sessions: 2, ip: '100.64.1.100', status: '在线' },
  { name: '联通备线', type: 'DHCP', interface: 'eth3', isp: '联通', bandwidth: '300M', sessions: 1, ip: '10.0.0.5', status: '在线' },
  { name: '电信VLAN池', type: 'VLAN虚拟拨号', interface: 'eth0', isp: '电信', bandwidth: '500M', sessions: 3, ip: '100.64.2.50', status: '在线' },
  { name: '企业专线', type: '静态IP', interface: 'eth4', isp: '其他', bandwidth: '100M', sessions: 1, ip: '172.16.0.10', status: '在线' },
])
</script>
