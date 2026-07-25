<template>
  <PageContainer>
    <PageHeader title="Ipv4Egress" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="IPv4出口管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'活跃'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '出口名称', width: 120 },
  { prop: 'ip', label: '出口IP', width: 130 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'bindServer', label: '绑定服务器', width: 150 },
  { prop: 'portRange', label: '端口范围', width: 120 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '活跃' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '出口名称', type: 'input', required: true },
  { prop: 'ip', label: '出口IP', type: 'input' },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'bindServer', label: '绑定服务器IP', type: 'input' },
  { prop: 'portRange', label: '端口范围', type: 'input' },
]
let data = ref([
  { name: 'Web出口', ip: '100.64.1.100', interface: 'wan', bindServer: '192.168.1.100', portRange: '80,443', status: '活跃' },
  { name: '游戏出口', ip: '10.0.0.5', interface: 'wan2', bindServer: '192.168.1.150', portRange: '25565', status: '活跃' },
  { name: 'VLAN出口', ip: '100.64.2.50', interface: 'wan3', bindServer: '192.168.1.200', portRange: '全部', status: '活跃' },
])
</script>
