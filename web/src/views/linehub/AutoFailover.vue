<template>
  <PageContainer>
    <PageHeader title="AutoFailover" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>故障自动切换</span></template>
            <el-form :model="config" label-width="160px">
              <el-form-item label="自动故障切换"><el-switch v-model="config.autoFailover" /></el-form-item>
              <el-form-item label="故障判定时间(秒)"><el-input-number v-model="config.detectTime" :min="5" :max="60" /></el-form-item>
              <el-form-item label="连续失败次数"><el-input-number v-model="config.failCount" :min="1" :max="10" /></el-form-item>
              <el-form-item label="自动回切"><el-switch v-model="config.autoRecover" /></el-form-item>
              <el-form-item label="回切等待(秒)"><el-input-number v-model="config.recoverWait" :min="30" :max="600" /></el-form-item>
              <el-form-item label="切换通知"><el-switch v-model="config.notify" /></el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="切换优先级链"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push({...f, status:'就绪'}); ElMessage.success('添加成功') }"
            @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const config = reactive({ autoFailover: true, detectTime: 10, failCount: 3, autoRecover: true, recoverWait: 120, notify: true })

const columns = [
  { prop: 'priority', label: '优先级', width: 80 },
  { prop: 'line', label: '线路', width: 120 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'role', label: '角色', type: 'tag', tagType: (v) => v === '主用' ? 'success' : 'warning', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '活跃' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'priority', label: '优先级', type: 'input', required: true },
  { prop: 'line', label: '线路', type: 'select', options: ['电信主线', '联通备线', '电信VLAN', '企业专线'] },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'role', label: '角色', type: 'select', options: ['主用', '备用'] },
]
let data = ref([
  { priority: '1', line: '电信主线', interface: 'wan', role: '主用', status: '活跃' },
  { priority: '2', line: '电信VLAN', interface: 'wan3', role: '备用', status: '就绪' },
  { priority: '3', line: '联通备线', interface: 'wan2', role: '备用', status: '就绪' },
  { priority: '4', line: '企业专线', interface: 'wan4', role: '备用', status: '就绪' },
])
</script>
