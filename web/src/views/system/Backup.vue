<template>
  <PageContainer>
    <PageHeader title="备份恢复" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>备份与恢复</span></template>
            <el-row :gutter="20">
              <el-col :span="12">
                <SectionCard shadow="never">
                  <h4>生成备份</h4>
                  <p style="color:#909399;font-size:13px">备份当前所有配置文件，生成 .tar.gz 归档文件</p>
                  <el-button type="primary" @click="backup">生成备份文件</el-button>
                </SectionCard>
              </el-col>
              <el-col :span="12">
                <SectionCard shadow="never">
                  <h4>恢复配置</h4>
                  <p style="color:#909399;font-size:13px">上传备份文件恢复系统配置</p>
                  <el-upload action="#" :auto-upload="false" :on-change="restore">
                    <el-button type="warning">上传恢复文件</el-button>
                  </el-upload>
                </SectionCard>
              </el-col>
            </el-row>
          </SectionCard>
          <CrudTable
            title="历史备份"
            :columns="columns"
            :data="data"
            :form-fields="[]"
            @add="() => {}"
            @edit="() => {}"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
            :extra-buttons="[{ label: '下载', handler: () => ElMessage.success('开始下载备份文件') }]"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

function backup() { ElMessage.success('备份文件已生成: backup-2026-07-22.tar.gz') }
function restore(file) { ElMessage.success(`已上传: ${file.name}，配置恢复成功`) }

const columns = [
  { prop: 'name', label: '文件名', width: 200 },
  { prop: 'date', label: '备份时间', width: 150 },
  { prop: 'size', label: '大小', width: 80 },
  { prop: 'type', label: '类型', type: 'tag', width: 100 },
]
let data = ref([
  { name: 'backup-2026-07-22.tar.gz', date: '2026-07-22 03:00', size: '2.1MB', type: '自动备份' },
  { name: 'backup-2026-07-15.tar.gz', date: '2026-07-15 03:00', size: '2.0MB', type: '自动备份' },
  { name: 'manual-2026-07-10.tar.gz', date: '2026-07-10 14:30', size: '1.9MB', type: '手动备份' },
])
</script>
