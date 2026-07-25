<template>
  <PageContainer>
    <PageHeader title="挂载管理" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="挂载管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, status:'已挂载'}); ElMessage.success('添加成功') }"
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
  { prop: 'device', label: '设备', width: 120 },
  { prop: 'mountPoint', label: '挂载点', width: 140 },
  { prop: 'fsType', label: '文件系统', width: 90 },
  { prop: 'size', label: '容量', width: 80 },
  { prop: 'used', label: '已用', width: 80 },
  { prop: 'usage', label: '使用率', type: 'progress', width: 130 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '已挂载' ? 'success' : 'danger', width: 90 },
]
const formFields = [
  { prop: 'device', label: '设备', type: 'input', required: true },
  { prop: 'mountPoint', label: '挂载点', type: 'input', required: true },
  { prop: 'fsType', label: '文件系统', type: 'select', options: ['ext4', 'xfs', 'btrfs', 'vfat', 'ntfs', 'overlay'] },
  { prop: 'options', label: '挂载选项', type: 'input' },
]
let data = ref([
  { device: '/dev/sda1', mountPoint: '/mnt/usb', fsType: 'ext4', size: '128GB', used: '45GB', usage: 35, status: '已挂载' },
  { device: '/dev/sdb1', mountPoint: '/mnt/backup', fsType: 'xfs', size: '1TB', used: '680GB', usage: 68, status: '已挂载' },
  { device: 'overlayfs', mountPoint: '/overlay', fsType: 'overlay', size: '256MB', used: '180MB', usage: 70, status: '已挂载' },
])
</script>
