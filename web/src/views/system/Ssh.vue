<template>
  <PageContainer>
    <PageHeader title="SSH管理" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>SSH服务配置</span></template>
            <el-form :model="config" label-width="160px">
              <el-form-item label="启用SSH"><el-switch v-model="config.enable" /></el-form-item>
              <el-form-item label="端口"><el-input-number v-model="config.port" :min="1" :max="65535" /></el-form-item>
              <el-form-item label="允许密码登录"><el-switch v-model="config.passwordAuth" /></el-form-item>
              <el-form-item label="允许Root登录"><el-switch v-model="config.rootLogin" /></el-form-item>
              <el-form-item label="空闲超时(秒)"><el-input-number v-model="config.timeout" :min="0" :max="3600" /></el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="SSH密钥管理"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push(f); ElMessage.success('添加成功') }"
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

const config = reactive({ enable: true, port: 22, passwordAuth: true, rootLogin: true, timeout: 300 })

const columns = [
  { prop: 'name', label: '密钥名称', width: 140 },
  { prop: 'type', label: '类型', width: 100 },
  { prop: 'fingerprint', label: '指纹', width: 220 },
  { prop: 'addedAt', label: '添加时间', width: 140 },
]
const formFields = [
  { prop: 'name', label: '密钥名称', type: 'input', required: true },
  { prop: 'type', label: '类型', type: 'select', options: ['ssh-rsa', 'ssh-ed25519', 'ecdsa-sha2-nistp256'] },
  { prop: 'key', label: '公钥内容', type: 'input' },
]
let data = ref([
  { name: '管理电脑', type: 'ssh-ed25519', fingerprint: 'SHA256:AbCdEf123456789xYz', addedAt: '2026-06-01' },
  { name: '运维跳板机', type: 'ssh-rsa', fingerprint: 'SHA256:GhIjKl987654321mNo', addedAt: '2026-05-15' },
])
</script>
