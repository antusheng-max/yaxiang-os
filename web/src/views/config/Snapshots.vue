<template>
  <PageContainer>
    <PageHeader title="配置快照" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="配置快照"
                  :columns="columns"
                  :data="data"
                  :form-fields="[]"
                  @add="() => { data.unshift({ name: 'snapshot-' + Date.now(), time: new Date().toLocaleString(), size: '1.8MB', desc: '手动快照' }); ElMessage.success('快照已创建') }"
                  @edit="() => {}"
                  @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
                  :extra-buttons="[{ label: '恢复', type: 'warning', handler: (row) => ElMessage.success('已恢复到快照: ' + row.name) }]"
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
  { prop: 'name', label: '快照名称', width: 200 },
  { prop: 'time', label: '创建时间', width: 160 },
  { prop: 'size', label: '大小', width: 80 },
  { prop: 'desc', label: '说明', width: 160 },
]
let data = ref([
  { name: 'snapshot-20260722-0300', time: '2026-07-22 03:00', size: '1.8MB', desc: '自动快照(每日)' },
  { name: 'snapshot-20260721-1630', time: '2026-07-21 16:30', size: '1.8MB', desc: '应用配置前' },
  { name: 'snapshot-20260721-0300', time: '2026-07-21 03:00', size: '1.7MB', desc: '自动快照(每日)' },
  { name: 'snapshot-20260720-1400', time: '2026-07-20 14:00', size: '1.7MB', desc: '手动快照(大改前)' },
])
</script>
