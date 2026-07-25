<template>
  <PageContainer>
    <PageHeader title="NAT" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="NAT规则（SNAT/DNAT）"
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
  { prop: 'type', label: '类型', type: 'tag', width: 80 },
  { prop: 'src', label: '源地址', width: 140 },
  { prop: 'dest', label: '目标地址', width: 140 },
  { prop: 'target', label: 'NAT目标', width: 140 },
  { prop: 'interface', label: '出口', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'type', label: '类型', type: 'select', options: ['SNAT', 'DNAT', 'MASQUERADE'] },
  { prop: 'src', label: '源地址', type: 'input' },
  { prop: 'dest', label: '目标地址', type: 'input' },
  { prop: 'target', label: 'NAT目标地址', type: 'input' },
  { prop: 'interface', label: '出口接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
]
let data = ref([
  { name: '默认伪装', type: 'MASQUERADE', src: '192.168.1.0/24', dest: '-', target: '-', interface: 'wan', status: '启用' },
  { name: '服务器SNAT', type: 'SNAT', src: '192.168.1.200/32', dest: '0.0.0.0/0', target: '100.64.2.50', interface: 'wan3', status: '启用' },
  { name: 'DMZ', type: 'DNAT', src: '-', dest: '100.64.1.100', target: '192.168.1.100', interface: 'wan', status: '启用' },
])
</script>
