<template>
  <PageContainer>
    <PageHeader title="防火墙区域" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="防火墙区域"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push(f); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '区域名称', width: 100 },
  { prop: 'network', label: '关联网络', width: 120 },
  { prop: 'input', label: '入站', type: 'tag', tagType: (v) => v === 'ACCEPT' ? 'success' : v === 'REJECT' ? 'danger' : 'warning', width: 90 },
  { prop: 'output', label: '出站', type: 'tag', tagType: (v) => v === 'ACCEPT' ? 'success' : v === 'REJECT' ? 'danger' : 'warning', width: 90 },
  { prop: 'forward', label: '转发', type: 'tag', tagType: (v) => v === 'ACCEPT' ? 'success' : v === 'REJECT' ? 'danger' : 'warning', width: 90 },
  { prop: 'masq', label: 'NAT伪装', type: 'tag', tagType: (v) => v === '是' ? 'success' : 'info', width: 90 },
  { prop: 'mtuFix', label: 'MSS钳制', width: 90 },
]
const formFields = [
  { prop: 'name', label: '区域名称', type: 'input', required: true },
  { prop: 'network', label: '关联网络', type: 'input' },
  { prop: 'input', label: '入站策略', type: 'select', options: ['ACCEPT', 'REJECT', 'DROP'] },
  { prop: 'output', label: '出站策略', type: 'select', options: ['ACCEPT', 'REJECT', 'DROP'] },
  { prop: 'forward', label: '转发策略', type: 'select', options: ['ACCEPT', 'REJECT', 'DROP'] },
  { prop: 'masq', label: 'NAT伪装', type: 'select', options: ['是', '否'] },
  { prop: 'mtuFix', label: 'MSS钳制', type: 'select', options: ['是', '否'] },
]
let data = ref([
  { name: 'lan', network: 'lan lan2 lan3', input: 'ACCEPT', output: 'ACCEPT', forward: 'ACCEPT', masq: '否', mtuFix: '否' },
  { name: 'wan', network: 'wan wan2 wan3 wan4', input: 'REJECT', output: 'ACCEPT', forward: 'REJECT', masq: '是', mtuFix: '是' },
  { name: 'vpn', network: 'wg0 tun0', input: 'ACCEPT', output: 'ACCEPT', forward: 'REJECT', masq: '否', mtuFix: '否' },
])
</script>
