<template>
  <PageContainer>
    <PageHeader title="WireGuard" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="WireGuard隧道管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'运行中'}); ElMessage.success('添加成功') }"
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
  { prop: 'name', label: '隧道名称', width: 100 },
  { prop: 'listenPort', label: '监听端口', width: 90 },
  { prop: 'address', label: '隧道地址', width: 150 },
  { prop: 'peers', label: '对端数', width: 70 },
  { prop: 'publicKey', label: '公钥', width: 200 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '运行中' ? 'success' : 'danger', width: 90 },
  { prop: 'traffic', label: '流量', width: 120 },
]
const formFields = [
  { prop: 'name', label: '隧道名称', type: 'input', required: true },
  { prop: 'listenPort', label: '监听端口', type: 'input' },
  { prop: 'address', label: '隧道地址', type: 'input' },
  { prop: 'privateKey', label: '私钥', type: 'input' },
  { prop: 'publicKey', label: '公钥', type: 'input' },
  { prop: 'peers', label: '对端数', type: 'input' },
]
let data = ref([
  { name: 'wg0', listenPort: '51820', address: '10.100.0.1/24', peers: '3', publicKey: 'aBcDeFgHiJkLmNoPqRsTuVwXyZ123456789=', status: '运行中', traffic: '↑2.1GB ↓8.5GB' },
  { name: 'wg1', listenPort: '51821', address: '10.101.0.1/24', peers: '1', publicKey: 'xYzAbCdEfGhIjKlMnOpQrStUvWx123456789=', status: '运行中', traffic: '↑0.5GB ↓1.2GB' },
])
</script>
