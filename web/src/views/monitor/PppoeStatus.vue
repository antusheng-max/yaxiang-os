<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>PPPoE状态</h2><p>所有PPPoE拨号线路运行状态（只读）</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="线路"
                  :columns="columns"
                  :data="data"
                  :form-fields="[]"
                  :extra-buttons="[{ label: '重拨', handler: onRedial }]"
                  @delete="() => {}"
                />
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>
<script setup>
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage, ElMessageBox } from 'element-plus'

function onRedial(row) {
  ElMessageBox.confirm(`确认重拨 ${row.name}？`, '重拨确认', { type: 'warning' })
    .then(() => ElMessage.success(`${row.name} 重拨指令已发送（Mock）`))
    .catch(() => {})
}

const columns = [
  { prop: 'name', label: '线路', width: 120 },
  { prop: 'device', label: '设备', width: 90 },
  { prop: 'status', label: '状态', width: 80, type: 'tag' },
  { prop: 'ip', label: '获取IP', width: 130 },
  { prop: 'gateway', label: '网关', width: 130 },
  { prop: 'uptime', label: '连接时长', width: 110 },
  { prop: 'rxBytes', label: '接收', width: 90 },
  { prop: 'txBytes', label: '发送', width: 90 },
  { prop: 'account', label: '账号', minWidth: 150 },
]
const data = [
  { name: 'pppoe-wan1', device: 'eth0', status: '已连接', ip: '100.64.1.101', gateway: '100.64.1.1', uptime: '15天7小时', rxBytes: '128.5GB', txBytes: '35.2GB', account: 'user001@telecom' },
  { name: 'pppoe-wan1b', device: 'eth0', status: '已连接', ip: '100.64.1.201', gateway: '100.64.1.1', uptime: '15天7小时', rxBytes: '45.2GB', txBytes: '12.1GB', account: 'user001b@telecom' },
  { name: 'pppoe-wan2', device: 'eth1', status: '已连接', ip: '100.64.2.102', gateway: '100.64.2.1', uptime: '12天3小时', rxBytes: '96.3GB', txBytes: '22.1GB', account: 'user002@telecom' },
  { name: 'pppoe-wan3', device: 'eth0.100', status: '已连接', ip: '100.64.3.103', gateway: '100.64.3.1', uptime: '8天12小时', rxBytes: '85.1GB', txBytes: '18.7GB', account: 'user003@unicom' },
  { name: 'pppoe-wan4', device: 'eth3', status: '断开', ip: '-', gateway: '-', uptime: '-', rxBytes: '0', txBytes: '0', account: 'user004@mobile' },
]
</script>
