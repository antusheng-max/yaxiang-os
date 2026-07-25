<template>
  <PageContainer>
    <PageHeader title="IP集合" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="IP集合管理"
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
  { prop: 'name', label: '集合名称', width: 140 },
  { prop: 'type', label: '类型', type: 'tag', width: 120 },
  { prop: 'entries', label: '条目数', width: 80 },
  { prop: 'content', label: '内容示例', width: 200 },
  { prop: 'usedBy', label: '引用规则', width: 140 },
]
const formFields = [
  { prop: 'name', label: '集合名称', type: 'input', required: true },
  { prop: 'type', label: '类型', type: 'select', options: ['hash:ip', 'hash:net', 'hash:mac', 'list:set'] },
  { prop: 'entries', label: '条目数', type: 'input' },
  { prop: 'content', label: '内容(逗号分隔)', type: 'input' },
  { prop: 'usedBy', label: '引用规则', type: 'input' },
]
let data = ref([
  { name: 'whitelist_ips', type: 'hash:ip', entries: '15', content: '192.168.1.10, 192.168.1.20...', usedBy: '允许SSH内网' },
  { name: 'blocked_nets', type: 'hash:net', entries: '8', content: '10.99.0.0/16, 172.31.0.0/16...', usedBy: '禁止BT下载' },
  { name: 'game_servers', type: 'hash:ip', entries: '25', content: '47.96.1.1, 47.96.1.2...', usedBy: '游戏加速' },
])
</script>
