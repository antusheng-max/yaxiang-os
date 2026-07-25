<template>
  <PageContainer>
    <PageHeader title="UPnP" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>UPnP设置</span></template>
            <el-form :model="config" label-width="140px">
              <el-form-item label="启用UPnP"><el-switch v-model="config.enable" /></el-form-item>
              <el-form-item label="启用NAT-PMP"><el-switch v-model="config.natpmp" /></el-form-item>
              <el-form-item label="外部接口">
                <el-select v-model="config.extIf"><el-option v-for="i in ['wan','wan2','wan3','wan4']" :key="i" :label="i" :value="i" /></el-select>
              </el-form-item>
              <el-form-item label="内部接口">
                <el-select v-model="config.intIf"><el-option v-for="i in ['lan','lan2','lan3']" :key="i" :label="i" :value="i" /></el-select>
              </el-form-item>
              <el-form-item label="允许端口范围"><el-input v-model="config.ports" placeholder="1024-65535" /></el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="UPnP端口映射（运行时）"
            :columns="columns"
            :data="data"
            :form-fields="[]"
            @add="() => {}"
            @edit="() => {}"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const config = reactive({ enable: true, natpmp: true, extIf: 'wan', intIf: 'lan', ports: '1024-65535' })

const columns = [
  { prop: 'proto', label: '协议', width: 70 },
  { prop: 'extPort', label: '外部端口', width: 90 },
  { prop: 'intIp', label: '内部IP', width: 130 },
  { prop: 'intPort', label: '内部端口', width: 90 },
  { prop: 'desc', label: '描述', width: 160 },
]
let data = ref([
  { proto: 'TCP', extPort: '32400', intIp: '192.168.1.50', intPort: '32400', desc: 'Plex Media Server' },
  { proto: 'UDP', extPort: '1900', intIp: '192.168.1.55', intPort: '1900', desc: 'DLNA' },
  { proto: 'TCP', extPort: '8080', intIp: '192.168.1.60', intPort: '8080', desc: 'NAS Web' },
])
</script>
