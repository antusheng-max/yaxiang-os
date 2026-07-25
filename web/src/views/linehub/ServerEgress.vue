<template>
  <PageContainer>
    <PageHeader title="ServerEgress" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="服务器出口管理"
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
  { prop: 'server', label: '服务器', width: 140 },
  { prop: 'serverIp', label: '服务器IP', width: 130 },
  { prop: 'egressLine', label: '出口线路', width: 100 },
  { prop: 'egressIp', label: '出口IP', width: 130 },
  { prop: 'ports', label: '服务端口', width: 120 },
  { prop: 'protocol', label: '协议', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
]
const formFields = [
  { prop: 'server', label: '服务器名称', type: 'input', required: true },
  { prop: 'serverIp', label: '服务器IP', type: 'input', required: true },
  { prop: 'egressLine', label: '出口线路', type: 'select', options: ['电信主线', '联通备线', '电信VLAN', '企业专线'] },
  { prop: 'ports', label: '服务端口', type: 'input' },
  { prop: 'protocol', label: '协议', type: 'select', options: ['TCP', 'UDP', 'TCP/UDP'] },
]
let data = ref([
  { server: 'Web服务器', serverIp: '192.168.1.100', egressLine: '电信主线', egressIp: '100.64.1.100', ports: '80,443', protocol: 'TCP', status: '运行中' },
  { server: '游戏服务器', serverIp: '192.168.1.150', egressLine: '联通备线', egressIp: '10.0.0.5', ports: '25565', protocol: 'TCP/UDP', status: '运行中' },
  { server: '开发服务器', serverIp: '192.168.1.200', egressLine: '电信VLAN', egressIp: '100.64.2.50', ports: '22,8080,3000', protocol: 'TCP', status: '运行中' },
  { server: 'NAS', serverIp: '192.168.1.50', egressLine: '企业专线', egressIp: '172.16.0.10', ports: '443,5000,5001', protocol: 'TCP', status: '运行中' },
])
</script>
