<template>
  <PageContainer>
    <PageHeader title="PolicySplit" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="策略分流规则"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'启用', hits:0}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '规则名称', width: 130 },
  { prop: 'matchType', label: '匹配方式', type: 'tag', width: 100 },
  { prop: 'matchValue', label: '匹配值', width: 160 },
  { prop: 'action', label: '动作', width: 100 },
  { prop: 'target', label: '目标线路', width: 100 },
  { prop: 'hits', label: '命中次数', width: 90 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'matchType', label: '匹配方式', type: 'select', options: ['源IP', '目标IP', '目标域名', '目标端口', '协议'] },
  { prop: 'matchValue', label: '匹配值', type: 'input', required: true },
  { prop: 'action', label: '动作', type: 'select', options: ['走指定线路', '负载均衡', '直连', '拒绝'] },
  { prop: 'target', label: '目标线路', type: 'select', options: ['电信主线', '联通备线', '电信VLAN', '企业专线'] },
]
let data = ref([
  { name: '游戏走联通', matchType: '目标端口', matchValue: 'UDP 3000-5000', action: '走指定线路', target: '联通备线', hits: 15234, status: '启用' },
  { name: '视频走电信', matchType: '目标域名', matchValue: '*.iqiyi.com,*.qq.com', action: '走指定线路', target: '电信主线', hits: 89562, status: '启用' },
  { name: '服务器固定', matchType: '源IP', matchValue: '192.168.1.200/32', action: '走指定线路', target: '电信VLAN', hits: 45678, status: '启用' },
  { name: '办公走专线', matchType: '目标IP', matchValue: '10.0.0.0/8', action: '走指定线路', target: '企业专线', hits: 12345, status: '启用' },
])
</script>
