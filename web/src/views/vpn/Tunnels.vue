<template>
  <PageContainer>
    <PageHeader title="隧道管理" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="隧道管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'运行中'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '隧道名称', width: 100 },
  { prop: 'type', label: '类型', type: 'tag', width: 100 },
  { prop: 'local', label: '本地端点', width: 140 },
  { prop: 'remote', label: '远端地址', width: 140 },
  { prop: 'tunnelIp', label: '隧道IP', width: 130 },
  { prop: 'mtu', label: 'MTU', width: 70 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
]
const formFields = [
  { prop: 'name', label: '隧道名称', type: 'input', required: true },
  { prop: 'type', label: '类型', type: 'select', options: ['GRE', 'IPIP', 'SIT(6in4)', '6to4', 'VXLAN', 'EOIP'] },
  { prop: 'local', label: '本地端点', type: 'input' },
  { prop: 'remote', label: '远端地址', type: 'input' },
  { prop: 'tunnelIp', label: '隧道IP', type: 'input' },
  { prop: 'mtu', label: 'MTU', type: 'input' },
]
let data = ref([
  { name: 'gre1', type: 'GRE', local: '100.64.1.100', remote: '203.0.113.1', tunnelIp: '10.200.0.1/30', mtu: '1400', status: '运行中' },
  { name: 'sit1', type: 'SIT(6in4)', local: '100.64.1.100', remote: '203.0.113.2', tunnelIp: '2001:db8::1/64', mtu: '1480', status: '运行中' },
])
</script>
