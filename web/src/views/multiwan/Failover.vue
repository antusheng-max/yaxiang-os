<template>
  <PageContainer>
    <PageHeader title="Failover" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>故障切换配置</span></template>
            <el-form :model="config" label-width="140px">
              <el-form-item label="自动切换">
                <el-switch v-model="config.autoSwitch" />
              </el-form-item>
              <el-form-item label="切换延迟(秒)">
                <el-input-number v-model="config.delay" :min="0" :max="60" />
              </el-form-item>
              <el-form-item label="自动回切">
                <el-switch v-model="config.autoRecover" />
              </el-form-item>
              <el-form-item label="回切等待(秒)">
                <el-input-number v-model="config.recoverDelay" :min="30" :max="600" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="ElMessage.success('保存成功')">保存配置</el-button>
              </el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="切换优先级"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push({...f, status:'活跃'}); ElMessage.success('添加成功') }"
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

const config = reactive({ autoSwitch: true, delay: 5, autoRecover: true, recoverDelay: 120 })

const columns = [
  { prop: 'priority', label: '优先级', width: 80 },
  { prop: 'line', label: '线路', width: 120 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '活跃' ? 'success' : v === '备用' ? 'warning' : 'danger', width: 80 },
  { prop: 'lastSwitch', label: '上次切换', width: 140 },
]
const formFields = [
  { prop: 'priority', label: '优先级', type: 'input', required: true },
  { prop: 'line', label: '线路', type: 'select', options: ['电信主线', '联通备线', '电信VLAN', '专线'] },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
]
let data = ref([
  { priority: '1', line: '电信主线', interface: 'wan', status: '活跃', lastSwitch: '-' },
  { priority: '2', line: '电信VLAN', interface: 'wan3', status: '备用', lastSwitch: '-' },
  { priority: '3', line: '联通备线', interface: 'wan2', status: '备用', lastSwitch: '-' },
  { priority: '4', line: '专线', interface: 'wan4', status: '备用', lastSwitch: '2026-07-20 14:30' },
])
</script>
