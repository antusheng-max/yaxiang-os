<template>
  <PageContainer>
    <PageHeader title="路由规则" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="路由规则（策略路由）"
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
  { prop: 'src', label: '源地址/网段', width: 150 },
  { prop: 'dest', label: '目标地址', width: 150 },
  { prop: 'interface', label: '出口接口', width: 100 },
  { prop: 'priority', label: '优先级', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'src', label: '源地址/网段', type: 'input' },
  { prop: 'dest', label: '目标地址/网段', type: 'input' },
  { prop: 'interface', label: '出口接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'priority', label: '优先级', type: 'input' },
]
let data = ref([
  { name: '办公走wan', src: '192.168.1.0/24', dest: '0.0.0.0/0', interface: 'wan', priority: '100', status: '启用' },
  { name: '游戏走wan2', src: '192.168.1.100/32', dest: '0.0.0.0/0', interface: 'wan2', priority: '50', status: '启用' },
  { name: '服务器走wan3', src: '192.168.1.200/32', dest: '0.0.0.0/0', interface: 'wan3', priority: '80', status: '启用' },
])
</script>
