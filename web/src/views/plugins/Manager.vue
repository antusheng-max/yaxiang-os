<template>
  <PageContainer>
    <PageHeader title="插件管理" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span>插件管理</span>
                <el-input v-model="search" placeholder="搜索插件..." clearable />
              </div>
            </template>
            <el-row :gutter="16">
              <el-col :xs="24" :sm="12" :md="8" v-for="p in filtered" :key="p.name">
                <SectionCard shadow="hover">
                  <div style="display:flex;justify-content:space-between;align-items:flex-start">
                    <div>
                      <strong>{{ p.name }}</strong>
                      <el-tag size="small" :type="p.installed ? 'success' : 'info'">{{ p.installed ? '已安装' : '未安装' }}</el-tag>
                    </div>
                    <el-button size="small" :type="p.installed ? 'danger' : 'primary'" @click="toggle(p)">
                      {{ p.installed ? '卸载' : '安装' }}
                    </el-button>
                  </div>
                  <p style="color:#909399;font-size:13px">{{ p.desc }}</p>
                  <div style="font-size:12px;color:#c0c4cc">版本: {{ p.version }} | 大小: {{ p.size }}</div>
                </SectionCard>
              </el-col>
            </el-row>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'

const search = ref('')
const plugins = ref([
  { name: 'AdGuardHome', desc: 'DNS广告过滤与隐私保护', version: '0.107.44', size: '12MB', installed: true },
  { name: 'OpenClash', desc: 'Clash代理客户端', version: '0.46.0', size: '8MB', installed: true },
  { name: 'PassWall', desc: '透明代理', version: '4.77', size: '5MB', installed: false },
  { name: 'Docker', desc: '容器运行时环境', version: '24.0.7', size: '45MB', installed: false },
  { name: 'FRP Client', desc: '内网穿透客户端', version: '0.52.0', size: '6MB', installed: false },
  { name: 'Samba4', desc: 'SMB/CIFS文件共享', version: '4.18.0', size: '15MB', installed: false },
  { name: 'Aria2', desc: '下载工具', version: '1.37.0', size: '3MB', installed: false },
  { name: 'TTYD', desc: 'Web终端', version: '1.7.4', size: '1MB', installed: true },
  { name: 'NLBWmon', desc: '带宽流量监控', version: '2024.1', size: '2MB', installed: true },
])

const filtered = computed(() => search.value ? plugins.value.filter(p => p.name.toLowerCase().includes(search.value.toLowerCase()) || p.desc.includes(search.value)) : plugins.value)
function toggle(p) { p.installed = !p.installed; ElMessage.success(p.name + (p.installed ? ' 安装成功' : ' 已卸载')) }
</script>
