<template>
  <PageContainer>
    <PageHeader title="动态DNS" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="动态DNS管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'运行中', lastUpdate:'-'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '配置名称', width: 120 },
  { prop: 'provider', label: '服务商', width: 120 },
  { prop: 'domain', label: '域名', width: 160 },
  { prop: 'interface', label: 'IP来源', width: 80 },
  { prop: 'currentIp', label: '当前IP', width: 130 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
  { prop: 'lastUpdate', label: '上次更新', width: 140 },
]
const formFields = [
  { prop: 'name', label: '配置名称', type: 'input', required: true },
  { prop: 'provider', label: '服务商', type: 'select', options: ['Cloudflare', 'DNSPod', '阿里云', 'No-IP', 'DynDNS', '花生壳'] },
  { prop: 'domain', label: '域名', type: 'input', required: true },
  { prop: 'username', label: '用户名/Token', type: 'input' },
  { prop: 'password', label: '密码/密钥', type: 'input' },
  { prop: 'interface', label: 'IP来源接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
]
let data = ref([
  { name: '主域名', provider: 'Cloudflare', domain: 'home.example.com', interface: 'wan', currentIp: '100.64.1.100', status: '运行中', lastUpdate: '2026-07-22 08:30' },
  { name: '备线域名', provider: 'DNSPod', domain: 'backup.example.com', interface: 'wan2', currentIp: '10.0.0.5', status: '运行中', lastUpdate: '2026-07-22 08:30' },
])
</script>
