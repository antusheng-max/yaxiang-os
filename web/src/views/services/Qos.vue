<template>
  <PageContainer>
    <PageHeader title="QoS/SQM" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>QoS/SQM配置</span></template>
            <el-form :model="config" label-width="140px">
              <el-form-item label="启用SQM"><el-switch v-model="config.enable" /></el-form-item>
              <el-form-item label="接口">
                <el-select v-model="config.interface"><el-option v-for="i in ['wan','wan2','wan3','wan4']" :key="i" :label="i" :value="i" /></el-select>
              </el-form-item>
              <el-form-item label="下载带宽(Kbps)"><el-input-number v-model="config.download" :min="1000" :step="1000" /></el-form-item>
              <el-form-item label="上传带宽(Kbps)"><el-input-number v-model="config.upload" :min="1000" :step="1000" /></el-form-item>
              <el-form-item label="队列规则">
                <el-select v-model="config.qdisc">
                  <el-option label="cake (推荐)" value="cake" />
                  <el-option label="fq_codel" value="fq_codel" />
                  <el-option label="htb + sfq" value="htb" />
                </el-select>
              </el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="QoS分类规则"
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

const config = reactive({ enable: true, interface: 'wan', download: 500000, upload: 100000, qdisc: 'cake' })

const columns = [
  { prop: 'name', label: '规则名称', width: 120 },
  { prop: 'target', label: '目标', width: 140 },
  { prop: 'port', label: '端口', width: 100 },
  { prop: 'priority', label: '优先级', type: 'tag', tagType: (v) => v === '高' ? 'danger' : v === '中' ? 'warning' : 'info', width: 80 },
  { prop: 'rateLimit', label: '限速', width: 100 },
]
const formFields = [
  { prop: 'name', label: '规则名称', type: 'input', required: true },
  { prop: 'target', label: '目标IP/网段', type: 'input' },
  { prop: 'port', label: '端口', type: 'input' },
  { prop: 'priority', label: '优先级', type: 'select', options: ['高', '中', '低'] },
  { prop: 'rateLimit', label: '限速(Kbps)', type: 'input' },
]
let data = ref([
  { name: '游戏优先', target: '192.168.1.100', port: '-', priority: '高', rateLimit: '-' },
  { name: '视频限速', target: '192.168.1.0/24', port: '443', priority: '中', rateLimit: '50000' },
  { name: '下载限制', target: '192.168.1.0/24', port: '80', priority: '低', rateLimit: '20000' },
])
</script>
