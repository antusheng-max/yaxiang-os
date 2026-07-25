<template>
  <PageContainer>
    <PageHeader title="策略路由" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="分流策略（策略路由）"
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
  { prop: 'srcIp', label: '源IP/网段', width: 150 },
  { prop: 'destIp', label: '目标IP/域名', width: 160 },
  { prop: 'port', label: '端口', width: 100 },
  { prop: 'interface', label: '出口', width: 80 },
  { prop: 'priority', label: '优先级', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'srcIp', label: '源IP/网段', type: 'input' },
  { prop: 'destIp', label: '目标IP/域名', type: 'input' },
  { prop: 'port', label: '端口(可选)', type: 'input' },
  { prop: 'interface', label: '出口接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'priority', label: '优先级', type: 'input' },
]
let data = ref([
  { name: '游戏加速', srcIp: '192.168.1.0/24', destIp: '-', port: 'UDP 3000-5000', interface: 'wan2', priority: '10', status: '启用' },
  { name: '视频走电信', srcIp: '192.168.1.0/24', destIp: '*.iqiyi.com', port: '-', interface: 'wan', priority: '20', status: '启用' },
  { name: '服务器固定出口', srcIp: '192.168.1.200/32', destIp: '0.0.0.0/0', port: '-', interface: 'wan3', priority: '5', status: '启用' },
  { name: '办公走专线', srcIp: '192.168.1.50/32', destIp: '10.0.0.0/8', port: '-', interface: 'wan4', priority: '15', status: '启用' },
])
</script>
