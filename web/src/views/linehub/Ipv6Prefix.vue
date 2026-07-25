<template>
  <PageContainer>
    <PageHeader title="Ipv6Prefix" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="IPv6前缀管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'已分配'}); ElMessage.success('添加成功') }"
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
  { prop: 'prefix', label: '前缀', width: 200 },
  { prop: 'interface', label: '来源接口', width: 90 },
  { prop: 'assignTo', label: '分配给', width: 120 },
  { prop: 'subPrefix', label: '子前缀', width: 200 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '已分配' ? 'success' : 'info', width: 90 },
]
const formFields = [
  { prop: 'prefix', label: '前缀', type: 'input', required: true },
  { prop: 'interface', label: '来源接口', type: 'select', options: ['wan', 'wan2', 'wan3'] },
  { prop: 'assignTo', label: '分配接口', type: 'select', options: ['lan', 'lan2', 'lan3'] },
  { prop: 'subPrefix', label: '子前缀', type: 'input' },
]
let data = ref([
  { prefix: '2408:8200:1234::/48', interface: 'wan', assignTo: 'lan', subPrefix: '2408:8200:1234:1::/64', status: '已分配' },
  { prefix: '2409:8a00:5678::/48', interface: 'wan2', assignTo: 'lan2', subPrefix: '2409:8a00:5678:2::/64', status: '已分配' },
])
</script>
