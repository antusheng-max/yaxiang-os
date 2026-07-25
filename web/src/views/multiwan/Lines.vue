<template>
  <PageContainer>
    <PageHeader title="Lines" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="多WAN线路管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'在线', latency:'-', bandwidth:'-'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '线路名称', width: 120 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'isp', label: '运营商', width: 100 },
  { prop: 'bandwidth', label: '带宽', width: 100 },
  { prop: 'weight', label: '权重', width: 70 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '在线' ? 'success' : 'danger', width: 80 },
  { prop: 'latency', label: '延迟', width: 80 },
  { prop: 'ip', label: '出口IP', width: 140 },
]
const formFields = [
  { prop: 'name', label: '线路名称', type: 'input', required: true },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'isp', label: '运营商', type: 'select', options: ['电信', '联通', '移动', '其他'] },
  { prop: 'bandwidth', label: '带宽(Mbps)', type: 'input' },
  { prop: 'weight', label: '权重', type: 'input' },
]
let data = ref([
  { name: '电信主线', interface: 'wan', isp: '电信', bandwidth: '500M', weight: '5', status: '在线', latency: '8ms', ip: '100.64.1.100' },
  { name: '联通备线', interface: 'wan2', isp: '联通', bandwidth: '300M', weight: '3', status: '在线', latency: '12ms', ip: '10.0.0.5' },
  { name: '电信VLAN', interface: 'wan3', isp: '电信', bandwidth: '500M', weight: '5', status: '在线', latency: '6ms', ip: '100.64.2.50' },
  { name: '专线', interface: 'wan4', isp: '其他', bandwidth: '100M', weight: '2', status: '在线', latency: '3ms', ip: '172.16.0.10' },
])
</script>
