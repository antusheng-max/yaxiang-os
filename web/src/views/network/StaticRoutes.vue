<template>
  <PageContainer>
    <PageHeader title="静态路由" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="静态路由"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'已生效'}); ElMessage.success('添加成功') }"
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
  { prop: 'target', label: '目标网络', width: 160 },
  { prop: 'netmask', label: '子网掩码', width: 130 },
  { prop: 'gateway', label: '网关', width: 140 },
  { prop: 'interface', label: '接口', width: 100 },
  { prop: 'metric', label: '跃点', width: 70 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '已生效' ? 'success' : 'info', width: 90 },
]
const formFields = [
  { prop: 'target', label: '目标网络', type: 'input', required: true },
  { prop: 'netmask', label: '子网掩码', type: 'input' },
  { prop: 'gateway', label: '网关', type: 'input', required: true },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'lan', 'lan2'] },
  { prop: 'metric', label: '跃点', type: 'input' },
]
let data = ref([
  { target: '10.0.0.0/8', netmask: '255.0.0.0', gateway: '192.168.1.254', interface: 'lan', metric: '100', status: '已生效' },
  { target: '172.16.0.0/12', netmask: '255.240.0.0', gateway: '100.64.1.1', interface: 'wan', metric: '200', status: '已生效' },
  { target: '0.0.0.0/0', netmask: '0.0.0.0', gateway: '10.0.0.1', interface: 'wan2', metric: '300', status: '已生效' },
])
</script>
