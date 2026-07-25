<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>DHCP/DNS</h2>
      <p>DHCP 服务器和 DNS 转发配置</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never" data-layout="section-card">
              <template #header><span data-layout="card-header">DHCP 服务器配置</span></template>
              <CrudTable
                title="" :columns="dhcpColumns" :data="dhcpData" :form-fields="dhcpFields"
                layout-mode="fill"
                @add="(f) => { dhcpData.push({...f, status:'运行中'}); ElMessage.success('添加成功') }"
                @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
                @delete="(r) => { dhcpData = dhcpData.filter(i=>i!==r); ElMessage.success('删除成功') }"
              />
            </SectionCard>
      
      
      
            <SectionCard shadow="never" data-layout="section-card">
              <template #header><span data-layout="card-header">DNS 配置</span></template>
              <CrudTable
                title="" :columns="dnsColumns" :data="dnsData" :form-fields="dnsFields"
                layout-mode="fill"
                @add="(f) => { dnsData.push(f); ElMessage.success('添加成功') }"
                @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
                @delete="(r) => { dnsData = dnsData.filter(i=>i!==r); ElMessage.success('删除成功') }"
              />
            </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const dhcpColumns = [
  { prop: 'interface', label: '接口', minWidth: 120 },
  { prop: 'start', label: '起始地址', minWidth: 140 },
  { prop: 'limit', label: '客户端数', minWidth: 110 },
  { prop: 'leasetime', label: '租约时间', minWidth: 110 },
  { prop: 'ignore', label: '忽略', type: 'tag', tagType: (v) => v === '否' ? 'success' : 'warning', minWidth: 80 },
]
const dhcpFields = [
  { prop: 'interface', label: '接口', type: 'select', options: ['lan', 'lan2', 'lan3'] },
  { prop: 'start', label: '起始地址', type: 'input' },
  { prop: 'limit', label: '客户端数', type: 'input' },
  { prop: 'leasetime', label: '租约时间', type: 'input' },
  { prop: 'ignore', label: '忽略此接口', type: 'select', options: ['否', '是'] },
]
let dhcpData = ref([
  { interface: 'lan', start: '100', limit: '150', leasetime: '12h', ignore: '否' },
  { interface: 'lan2', start: '100', limit: '100', leasetime: '12h', ignore: '否' },
  { interface: 'lan3', start: '50', limit: '200', leasetime: '24h', ignore: '否' },
])

const dnsColumns = [
  { prop: 'type', label: '类型', type: 'tag', minWidth: 140 },
  { prop: 'address', label: '地址', minWidth: 280 },
  { prop: 'port', label: '端口', minWidth: 80 },
  { prop: 'interface', label: '接口', minWidth: 120 },
]
const dnsFields = [
  { prop: 'type', label: '类型', type: 'select', options: ['上游DNS', '转发规则', '本地记录'] },
  { prop: 'address', label: '地址/域名', type: 'input' },
  { prop: 'port', label: '端口', type: 'input' },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'lan'] },
]
let dnsData = ref([
  { type: '上游DNS', address: '202.96.128.86', port: '53', interface: 'wan' },
  { type: '上游DNS', address: '8.8.8.8', port: '53', interface: 'wan2' },
  { type: '转发规则', address: '/taobao.com/223.5.5.5', port: '53', interface: '-' },
  { type: '本地记录', address: 'router.lan → 192.168.1.1', port: '-', interface: 'lan' },
])
</script>
