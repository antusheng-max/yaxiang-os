<template>
  <PageContainer>
    <PageHeader title="通信规则" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="区域间转发规则"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push(f); ElMessage.success('添加成功') }"
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
  { prop: 'src', label: '源区域', width: 100 },
  { prop: 'dest', label: '目标区域', width: 100 },
  { prop: 'action', label: '动作', type: 'tag', tagType: (v) => v === 'ACCEPT' ? 'success' : v === 'REJECT' ? 'danger' : 'warning', width: 100 },
  { prop: 'comment', label: '备注', width: 200 },
]
const formFields = [
  { prop: 'src', label: '源区域', type: 'select', options: ['lan', 'wan', 'vpn'] },
  { prop: 'dest', label: '目标区域', type: 'select', options: ['lan', 'wan', 'vpn'] },
  { prop: 'action', label: '动作', type: 'select', options: ['ACCEPT', 'REJECT', 'DROP'] },
  { prop: 'comment', label: '备注', type: 'input' },
]
let data = ref([
  { src: 'lan', dest: 'wan', action: 'ACCEPT', comment: '允许LAN访问WAN' },
  { src: 'lan', dest: 'vpn', action: 'ACCEPT', comment: '允许LAN访问VPN' },
  { src: 'vpn', dest: 'lan', action: 'ACCEPT', comment: '允许VPN访问LAN' },
  { src: 'wan', dest: 'lan', action: 'REJECT', comment: '禁止WAN访问LAN' },
])
</script>
