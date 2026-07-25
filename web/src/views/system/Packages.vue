<template>
  <PageContainer>
    <PageHeader title="软件包" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span>软件包管理</span>
                <div>
                  <el-input v-model="search" placeholder="搜索软件包..." clearable />
                  <el-button type="primary" @click="updateLists">更新列表</el-button>
                </div>
              </div>
            </template>
            <StandardTable layout-mode="fill" :data="filteredData" border stripe size="small">
              <el-table-column prop="name" label="包名" />
              <el-table-column prop="version" label="版本" />
              <el-table-column prop="size" label="大小" />
              <el-table-column prop="desc" label="描述" min-width="200" />
              <el-table-column prop="status" label="状态">
                <template #default="{ row }">
                  <el-tag :type="row.status === '已安装' ? 'success' : 'info'" size="small">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" fixed="right">
                <template #default="{ row }">
                  <el-button v-if="row.status === '已安装'" size="small" type="danger" link @click="row.status='未安装'; ElMessage.success(row.name+' 已卸载')">卸载</el-button>
                  <el-button v-else size="small" type="primary" link @click="row.status='已安装'; ElMessage.success(row.name+' 已安装')">安装</el-button>
                </template>
              </el-table-column>
            </StandardTable>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'

const search = ref('')
const data = ref([
  { name: 'luci-app-wireguard', version: '2024.1.1', size: '45KB', desc: 'WireGuard LuCI界面', status: '已安装' },
  { name: 'luci-app-openvpn', version: '2024.1.1', size: '38KB', desc: 'OpenVPN LuCI界面', status: '已安装' },
  { name: 'luci-app-sqm', version: '2024.1.1', size: '28KB', desc: 'SQM QoS管理', status: '已安装' },
  { name: 'luci-app-adguardhome', version: '1.2.0', size: '120KB', desc: 'AdGuardHome管理', status: '已安装' },
  { name: 'luci-app-ddns', version: '2024.1.1', size: '35KB', desc: '动态DNS管理', status: '已安装' },
  { name: 'luci-app-samba4', version: '2024.1.1', size: '22KB', desc: 'Samba4文件共享', status: '未安装' },
  { name: 'luci-app-docker', version: '2024.1.1', size: '55KB', desc: 'Docker管理', status: '未安装' },
  { name: 'luci-app-frpc', version: '2024.1.1', size: '18KB', desc: 'FRP内网穿透客户端', status: '未安装' },
  { name: 'luci-app-nlbwmon', version: '2024.1.1', size: '32KB', desc: '带宽监控', status: '已安装' },
  { name: 'luci-app-ttyd', version: '2024.1.1', size: '15KB', desc: 'Web终端', status: '未安装' },
])

const filteredData = computed(() => search.value ? data.value.filter(p => p.name.includes(search.value) || p.desc.includes(search.value)) : data.value)
function updateLists() { ElMessage.success('软件包列表已更新') }
</script>
