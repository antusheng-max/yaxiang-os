<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>接口状态</h2><p>各网络设备接口详细运行信息（只读）</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable title="设备" :columns="columns" :data="data" :form-fields="[]" @delete="() => {}" />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>
<script setup>
import CrudTable from '../../components/CrudTable.vue'
const columns = [
  { prop: 'device', label: '设备', width: 110 },
  { prop: 'type', label: '类型', width: 80 },
  { prop: 'mac', label: 'MAC地址', width: 160 },
  { prop: 'speed', label: '速率', width: 90 },
  { prop: 'status', label: '链路', width: 80, type: 'tag' },
  { prop: 'rxPackets', label: '收包', width: 90 },
  { prop: 'txPackets', label: '发包', width: 90 },
  { prop: 'rxErrors', label: '收错误', width: 80 },
]
const data = [
  { device: 'eth0', type: '物理', mac: '00:0C:29:1A:2B:01', speed: '1000M', status: 'up', rxPackets: '12.5M', txPackets: '8.3M', rxErrors: '0' },
  { device: 'eth1', type: '物理', mac: '00:0C:29:1A:2B:02', speed: '1000M', status: 'up', rxPackets: '9.8M', txPackets: '6.1M', rxErrors: '0' },
  { device: 'eth2', type: '物理', mac: '00:0C:29:1A:2B:03', speed: '1000M', status: 'up', rxPackets: '8.2M', txPackets: '5.5M', rxErrors: '2' },
  { device: 'eth3', type: '物理', mac: '00:0C:29:1A:2B:04', speed: '-', status: 'down', rxPackets: '0', txPackets: '0', rxErrors: '0' },
  { device: 'eth4', type: '物理', mac: '00:0C:29:1A:2B:05', speed: '1000M', status: 'up', rxPackets: '15.1M', txPackets: '11.2M', rxErrors: '0' },
  { device: 'br-lan', type: '网桥', mac: '00:0C:29:1A:2B:05', speed: '-', status: 'up', rxPackets: '15.1M', txPackets: '11.2M', rxErrors: '0' },
  { device: 'eth0.100', type: 'VLAN', mac: '00:0C:29:1A:2B:01', speed: '1000M', status: 'up', rxPackets: '5.2M', txPackets: '3.1M', rxErrors: '0' },
]
</script>
