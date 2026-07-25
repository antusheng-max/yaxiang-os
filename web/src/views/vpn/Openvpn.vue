<template>
  <PageContainer>
    <PageHeader title="OpenVPN" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="OpenVPN实例管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'运行中', clients:'0'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '实例名称', width: 120 },
  { prop: 'mode', label: '模式', type: 'tag', width: 80 },
  { prop: 'proto', label: '协议', width: 80 },
  { prop: 'port', label: '端口', width: 70 },
  { prop: 'subnet', label: '隧道网段', width: 130 },
  { prop: 'clients', label: '客户端数', width: 90 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
]
const formFields = [
  { prop: 'name', label: '实例名称', type: 'input', required: true },
  { prop: 'mode', label: '模式', type: 'select', options: ['server', 'client'] },
  { prop: 'proto', label: '协议', type: 'select', options: ['udp', 'tcp'] },
  { prop: 'port', label: '端口', type: 'input' },
  { prop: 'subnet', label: '隧道网段', type: 'input' },
]
let data = ref([
  { name: 'ovpn-server', mode: 'server', proto: 'udp', port: '1194', subnet: '10.8.0.0/24', clients: '5', status: '运行中' },
  { name: 'ovpn-client', mode: 'client', proto: 'tcp', port: '443', subnet: '-', clients: '-', status: '运行中' },
])
</script>
