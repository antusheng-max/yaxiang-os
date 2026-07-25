<template>
  <PageContainer>
    <PageHeader title="定时任务" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="定时任务 (Crontab)"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'启用'}); ElMessage.success('添加成功') }"
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
  { prop: 'schedule', label: '时间表达式', width: 130 },
  { prop: 'command', label: '命令', width: 250 },
  { prop: 'desc', label: '说明', width: 160 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'info', width: 80 },
]
const formFields = [
  { prop: 'schedule', label: '时间表达式', type: 'input', required: true },
  { prop: 'command', label: '命令', type: 'input', required: true },
  { prop: 'desc', label: '说明', type: 'input' },
  { prop: 'status', label: '状态', type: 'select', options: ['启用', '禁用'] },
]
let data = ref([
  { schedule: '0 3 * * *', command: '/sbin/reboot', desc: '每天凌晨3点重启', status: '启用' },
  { schedule: '*/5 * * * *', command: '/usr/bin/health_check.sh', desc: '每5分钟健康检查', status: '启用' },
  { schedule: '0 0 * * 0', command: '/usr/bin/backup_config.sh', desc: '每周日备份配置', status: '启用' },
  { schedule: '30 4 * * *', command: '/usr/bin/update_ddns.sh', desc: '每天更新DDNS', status: '启用' },
])
</script>
