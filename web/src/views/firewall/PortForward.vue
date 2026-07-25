<template>
  <PageContainer>
    <PageHeader title="端口转发" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="端口转发规则"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'启用'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '规则名称', width: 120 },
  { prop: 'proto', label: '协议', width: 80 },
  { prop: 'srcPort', label: '外部端口', width: 100 },
  { prop: 'destIp', label: '内部IP', width: 130 },
  { prop: 'destPort', label: '内部端口', width: 100 },
  { prop: 'srcZone', label: '源区域', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'proto', label: '协议', type: 'select', options: ['tcp', 'udp', 'tcp udp'] },
  { prop: 'srcPort', label: '外部端口', type: 'input', required: true },
  { prop: 'destIp', label: '内部IP', type: 'input', required: true },
  { prop: 'destPort', label: '内部端口', type: 'input' },
  { prop: 'srcZone', label: '源区域', type: 'select', options: ['wan', 'vpn'] },
]
let data = ref([
  { name: 'Web服务器', proto: 'tcp', srcPort: '80', destIp: '192.168.1.100', destPort: '80', srcZone: 'wan', status: '启用' },
  { name: 'HTTPS', proto: 'tcp', srcPort: '443', destIp: '192.168.1.100', destPort: '443', srcZone: 'wan', status: '启用' },
  { name: 'SSH管理', proto: 'tcp', srcPort: '2222', destIp: '192.168.1.100', destPort: '22', srcZone: 'wan', status: '启用' },
  { name: '游戏服务器', proto: 'tcp udp', srcPort: '25565', destIp: '192.168.1.150', destPort: '25565', srcZone: 'wan', status: '启用' },
])
</script>
