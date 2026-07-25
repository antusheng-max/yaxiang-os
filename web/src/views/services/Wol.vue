<template>
  <PageContainer>
    <PageHeader title="Wake on LAN" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>Wake on LAN</span></template>
            <el-form inline>
              <el-form-item label="MAC地址"><el-input v-model="mac" placeholder="AA:BB:CC:DD:EE:FF" /></el-form-item>
              <el-form-item label="广播地址"><el-input v-model="broadcast" placeholder="192.168.1.255" /></el-form-item>
              <el-form-item><el-button type="primary" @click="wake">唤醒</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="设备列表"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push(f); ElMessage.success('添加成功') }"
            @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
            :extra-buttons="[{ label: '唤醒', handler: (row) => { mac = row.mac; wake() } }]"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const mac = ref('')
const broadcast = ref('192.168.1.255')

function wake() {
  if (!mac.value) { ElMessage.warning('请输入MAC地址'); return }
  ElMessage.success(`已发送唤醒魔术包到 ${mac.value}`)
}

const columns = [
  { prop: 'name', label: '设备名称', width: 120 },
  { prop: 'mac', label: 'MAC地址', width: 160 },
  { prop: 'ip', label: 'IP地址', width: 130 },
  { prop: 'broadcast', label: '广播地址', width: 140 },
]
const formFields = [
  { prop: 'name', label: '设备名称', type: 'input', required: true },
  { prop: 'mac', label: 'MAC地址', type: 'input', required: true },
  { prop: 'ip', label: 'IP地址', type: 'input' },
  { prop: 'broadcast', label: '广播地址', type: 'input' },
]
let data = ref([
  { name: '办公PC', mac: 'AA:BB:CC:11:22:33', ip: '192.168.1.100', broadcast: '192.168.1.255' },
  { name: 'NAS', mac: 'AA:BB:CC:44:55:66', ip: '192.168.1.50', broadcast: '192.168.1.255' },
  { name: '工作站', mac: 'AA:BB:CC:77:88:99', ip: '192.168.1.200', broadcast: '192.168.1.255' },
])
</script>
