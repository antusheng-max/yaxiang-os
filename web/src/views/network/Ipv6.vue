<template>
  <PageContainer>
    <PageHeader title="Ipv6" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="IPv6管理"
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
  { prop: 'interface', label: '接口', width: 100 },
  { prop: 'type', label: '获取方式', type: 'tag', width: 120 },
  { prop: 'address', label: 'IPv6地址', width: 220 },
  { prop: 'gateway', label: '网关', width: 200 },
  { prop: 'prefix', label: '前缀', width: 180 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'info', width: 90 },
]
const formFields = [
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'lan'] },
  { prop: 'type', label: '获取方式', type: 'select', options: ['DHCPv6', 'SLAAC', '静态', '6rd', '6in4', 'DHCPv6-PD'] },
  { prop: 'address', label: 'IPv6地址', type: 'input' },
  { prop: 'gateway', label: '网关', type: 'input' },
  { prop: 'prefix', label: '前缀委派', type: 'input' },
]
let data = ref([
  { interface: 'wan', type: 'DHCPv6-PD', address: '2408:8200:1234::1/64', gateway: 'fe80::1', prefix: '2408:8200:1234::/48', status: '运行中' },
  { interface: 'wan2', type: 'SLAAC', address: '2409:8a00:5678::2/64', gateway: 'fe80::1', prefix: '2409:8a00:5678::/48', status: '运行中' },
  { interface: 'lan', type: 'SLAAC', address: '2408:8200:1234:1::1/64', gateway: '-', prefix: '-', status: '运行中' },
])
</script>
