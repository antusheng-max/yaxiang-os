<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>DHCP租约</h2><p>当前活跃的DHCP客户端租约（只读）</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable title="租约" :columns="columns" :data="data" :form-fields="[]" @delete="() => {}" />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>
<script setup>
import CrudTable from '../../components/CrudTable.vue'
const columns = [
  { prop: 'hostname', label: '主机名', width: 140 },
  { prop: 'ip', label: 'IP地址', width: 130 },
  { prop: 'mac', label: 'MAC地址', width: 160 },
  { prop: 'expires', label: '剩余租期', width: 110 },
  { prop: 'interface', label: '接口', width: 90 },
]
const data = [
  { hostname: 'Office-PC-01', ip: '192.168.1.101', mac: 'AA:BB:CC:01:01:01', expires: '11小时32分', interface: 'br-lan' },
  { hostname: 'Server-Rack-A', ip: '192.168.1.10', mac: 'AA:BB:CC:02:01:01', expires: '11小时58分', interface: 'br-lan' },
  { hostname: 'AP-Floor1', ip: '192.168.1.201', mac: 'AA:BB:CC:03:01:01', expires: '9小时42分', interface: 'br-lan' },
  { hostname: 'Printer-HP', ip: '192.168.1.250', mac: 'AA:BB:CC:04:01:01', expires: '11小时5分', interface: 'br-lan' },
  { hostname: 'VLAN20-Client', ip: '192.168.20.101', mac: 'AA:BB:CC:05:01:01', expires: '7小时30分', interface: 'br-lan2' },
]
</script>
