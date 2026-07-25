<template>
  <PageContainer>
    <PageHeader title="服务管理" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="服务管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="[]"
                  @add="() => {}"
                  @edit="() => {}"
                  @delete="() => {}"
                  :extra-buttons="[
                    { label: '启动', type: 'success', handler: (row) => { row.status = '运行中'; ElMessage.success(row.name + ' 已启动') } },
                    { label: '停止', type: 'danger', handler: (row) => { row.status = '已停止'; ElMessage.warning(row.name + ' 已停止') } },
                    { label: '重启', handler: (row) => { ElMessage.info(row.name + ' 正在重启...'); setTimeout(() => { row.status = '运行中'; ElMessage.success(row.name + ' 重启完成') }, 1000) } }
                  ]"
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
  { prop: 'name', label: '服务名称', width: 140 },
  { prop: 'desc', label: '描述', width: 200 },
  { prop: 'port', label: '端口', width: 80 },
  { prop: 'autostart', label: '开机自启', type: 'tag', tagType: (v) => v === '是' ? 'success' : 'info', width: 90 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
  { prop: 'pid', label: 'PID', width: 70 },
]
let data = ref([
  { name: 'dnsmasq', desc: 'DNS/DHCP服务', port: '53', autostart: '是', status: '运行中', pid: '1234' },
  { name: 'firewall4', desc: '防火墙(nftables)', port: '-', autostart: '是', status: '运行中', pid: '1100' },
  { name: 'nginx', desc: 'Web服务器', port: '80/443', autostart: '是', status: '运行中', pid: '2345' },
  { name: 'sshd', desc: 'SSH服务', port: '22', autostart: '是', status: '运行中', pid: '980' },
  { name: 'wireguard', desc: 'WireGuard VPN', port: '51820', autostart: '是', status: '运行中', pid: '1567' },
  { name: 'openvpn', desc: 'OpenVPN服务', port: '1194', autostart: '否', status: '已停止', pid: '-' },
  { name: 'samba4', desc: 'SMB文件共享', port: '445', autostart: '否', status: '已停止', pid: '-' },
  { name: 'adguardhome', desc: 'DNS广告过滤', port: '3000', autostart: '是', status: '运行中', pid: '3456' },
])
</script>
