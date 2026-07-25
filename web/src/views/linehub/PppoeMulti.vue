<template>
  <PageContainer>
    <PageHeader title="PppoeMulti" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>PPPoE多拨管理</span></template>
            <el-form inline>
              <el-form-item label="物理接口">
                <el-select v-model="targetIf"><el-option v-for="i in ['eth0','eth1','eth2','eth3','eth4','eth5']" :key="i" :label="i" :value="i" /></el-select>
              </el-form-item>
              <el-form-item label="拨号数量"><el-input-number v-model="dialCount" :min="1" :max="8" /></el-form-item>
              <el-form-item><el-button type="primary" @click="batchDial">批量拨号</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="多拨会话"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push({...f, status:'已连接', uptime:'0天 0小时'}); ElMessage.success('添加成功') }"
            @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
            :extra-buttons="[{ label: '重拨', handler: (row) => { row.status='拨号中'; setTimeout(()=>{row.status='已连接'; row.ip='100.64.'+Math.floor(Math.random()*255)+'.'+Math.floor(Math.random()*255); ElMessage.success('重拨成功')},1500) } }]"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const targetIf = ref('eth2')
const dialCount = ref(4)

function batchDial() {
  for (let i = 0; i < dialCount.value; i++) {
    data.value.push({ id: data.value.length + 1, interface: targetIf.value, account: `batch_user${i+1}@gd`, ip: `100.64.${Math.floor(Math.random()*255)}.${Math.floor(Math.random()*255)}`, status: '已连接', uptime: '0天 0小时' })
  }
  ElMessage.success(`已在 ${targetIf.value} 上创建 ${dialCount.value} 个拨号会话`)
}

const columns = [
  { prop: 'id', label: '#', width: 50 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'account', label: '账号', width: 160 },
  { prop: 'ip', label: '获得IP', width: 130 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '已连接' ? 'success' : v === '拨号中' ? 'warning' : 'danger', width: 90 },
  { prop: 'uptime', label: '运行时间', width: 100 },
]
const formFields = [
  { prop: 'interface', label: '接口', type: 'select', options: ['eth0', 'eth1', 'eth2', 'eth3', 'eth4', 'eth5'] },
  { prop: 'account', label: '宽带账号', type: 'input', required: true },
  { prop: 'password', label: '密码', type: 'input', required: true },
]
let data = ref([
  { id: 1, interface: 'eth2', account: 'user001@gd', ip: '100.64.1.100', status: '已连接', uptime: '12天 8小时' },
  { id: 2, interface: 'eth2', account: 'user002@gd', ip: '100.64.1.101', status: '已连接', uptime: '12天 8小时' },
  { id: 3, interface: 'eth2', account: 'user003@gd', ip: '100.64.1.102', status: '已连接', uptime: '5天 2小时' },
  { id: 4, interface: 'eth2', account: 'user004@gd', ip: '100.64.1.103', status: '已连接', uptime: '5天 2小时' },
])
</script>
