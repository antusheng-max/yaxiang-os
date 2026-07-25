<template>
  <PageContainer>
    <PageHeader title="流量规则" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="流量规则"
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
  { prop: 'name', label: '规则名称', width: 140 },
  { prop: 'proto', label: '协议', width: 80 },
  { prop: 'srcIp', label: '源地址', width: 140 },
  { prop: 'destIp', label: '目标地址', width: 140 },
  { prop: 'destPort', label: '目标端口', width: 100 },
  { prop: 'target', label: '动作', type: 'tag', tagType: (v) => v === 'ACCEPT' ? 'success' : v === 'DROP' ? 'danger' : 'warning', width: 90 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'proto', label: '协议', type: 'select', options: ['tcp', 'udp', 'icmp', 'all'] },
  { prop: 'srcIp', label: '源地址', type: 'input' },
  { prop: 'destIp', label: '目标地址', type: 'input' },
  { prop: 'destPort', label: '目标端口', type: 'input' },
  { prop: 'target', label: '动作', type: 'select', options: ['ACCEPT', 'REJECT', 'DROP'] },
]
let data = ref([
  { name: '允许ICMP', proto: 'icmp', srcIp: '-', destIp: '-', destPort: '-', target: 'ACCEPT', status: '启用' },
  { name: '允许DNS', proto: 'udp', srcIp: '192.168.1.0/24', destIp: '-', destPort: '53', target: 'ACCEPT', status: '启用' },
  { name: '禁止BT下载', proto: 'tcp', srcIp: '-', destIp: '-', destPort: '6881-6889', target: 'DROP', status: '启用' },
  { name: '允许SSH内网', proto: 'tcp', srcIp: '192.168.1.0/24', destIp: '192.168.1.1', destPort: '22', target: 'ACCEPT', status: '启用' },
])
</script>
