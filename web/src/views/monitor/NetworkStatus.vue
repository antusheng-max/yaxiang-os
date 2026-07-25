<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>网络状态</h2><p>所有网络接口运行状态（只读）</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable title="接口" :columns="columns" :data="data" :form-fields="[]" @delete="() => {}" />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>
<script setup>
import CrudTable from '../../components/CrudTable.vue'
const columns = [
  { prop: 'name', label: '接口', width: 110 },
  { prop: 'status', label: '状态', width: 80, type: 'tag' },
  { prop: 'ipaddr', label: 'IPv4地址', width: 150 },
  { prop: 'gateway', label: '网关', width: 140 },
  { prop: 'dns', label: 'DNS', minWidth: 140 },
  { prop: 'uptime', label: '运行时间', width: 120 },
  { prop: 'rx', label: '接收', width: 90 },
  { prop: 'tx', label: '发送', width: 90 },
]
const data = [
  { name: 'lan', status: 'up', ipaddr: '192.168.1.1/24', gateway: '-', dns: '-', uptime: '15天8小时', rx: '256GB', tx: '89GB' },
  { name: 'wan1', status: 'up', ipaddr: '100.64.1.101/32', gateway: '100.64.1.1', dns: '223.5.5.5', uptime: '15天7小时', rx: '128GB', tx: '35GB' },
  { name: 'wan2', status: 'up', ipaddr: '100.64.2.102/32', gateway: '100.64.2.1', dns: '119.29.29.29', uptime: '12天3小时', rx: '96GB', tx: '22GB' },
  { name: 'wan3', status: 'up', ipaddr: '100.64.3.103/32', gateway: '100.64.3.1', dns: '223.5.5.5', uptime: '8天12小时', rx: '85GB', tx: '18GB' },
  { name: 'wan4', status: 'down', ipaddr: '-', gateway: '-', dns: '-', uptime: '-', rx: '0', tx: '0' },
]
</script>
