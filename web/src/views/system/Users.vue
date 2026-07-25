<template>
  <PageContainer>
    <PageHeader title="用户权限" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <CrudTable
                  title="用户权限管理"
                  :columns="columns"
                  :data="data"
                  :form-fields="formFields"
                  @add="(f) => { data.push({...f, lastLogin:'-'}); ElMessage.success('添加成功') }"
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
  { prop: 'username', label: '用户名', width: 120 },
  { prop: 'role', label: '角色', type: 'tag', tagType: (v) => v === '管理员' ? 'danger' : v === '操作员' ? 'warning' : 'info', width: 100 },
  { prop: 'permissions', label: '权限', width: 200 },
  { prop: 'status', label: '状态', type: 'tag', tagType: (v) => v === '启用' ? 'success' : 'danger', width: 80 },
  { prop: 'lastLogin', label: '上次登录', width: 150 },
]
const formFields = [
  { prop: 'username', label: '用户名', type: 'input', required: true },
  { prop: 'password', label: '密码', type: 'input', required: true },
  { prop: 'role', label: '角色', type: 'select', options: ['管理员', '操作员', '只读'] },
  { prop: 'permissions', label: '权限范围', type: 'input' },
  { prop: 'status', label: '状态', type: 'select', options: ['启用', '禁用'] },
]
let data = ref([
  { username: 'root', role: '管理员', permissions: '全部权限', status: '启用', lastLogin: '2026-07-22 08:15' },
  { username: 'operator', role: '操作员', permissions: '网络配置, 监控', status: '启用', lastLogin: '2026-07-21 16:30' },
  { username: 'viewer', role: '只读', permissions: '运行监控', status: '启用', lastLogin: '2026-07-20 09:00' },
])
</script>
