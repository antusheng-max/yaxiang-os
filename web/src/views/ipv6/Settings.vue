<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>IPv6 全局设置</h2>
      <p>配置系统级 IPv6 选项，包括转发、DHCPv6 客户端、RA 服务、ND 代理等</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-form
                  :model="form"
                  label-width="180px"
                  label-position="right"
                  v-loading="loading"
      
                >
                  <el-divider content-position="left">基础开关</el-divider>
      
                  <el-form-item label="IPv6 总开关">
                    <el-switch v-model="form.enabled" />
                    <span class="form-hint">{{ form.enabled ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-form-item label="IPv6 转发">
                    <el-switch v-model="form.forwarding" />
                    <span class="form-hint">{{ form.forwarding ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-form-item label="DHCPv6 客户端">
                    <el-switch v-model="form.dhcpv6Client" />
                    <span class="form-hint">{{ form.dhcpv6Client ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-form-item label="RA 服务">
                    <el-switch v-model="form.raService" />
                    <span class="form-hint">{{ form.raService ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-divider content-position="left">路由与代理</el-divider>
      
                  <el-form-item label="默认路由">
                    <el-switch v-model="form.defaultRoute" />
                    <span class="form-hint">{{ form.defaultRoute ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-form-item label="ND 代理">
                    <el-switch v-model="form.ndProxy" />
                    <span class="form-hint">{{ form.ndProxy ? '已启用' : '已禁用' }}</span>
                  </el-form-item>
      
                  <el-divider content-position="left">链路参数</el-divider>
      
                  <el-form-item label="MTU">
                    <el-input-number
                      v-model="form.mtu"
                      :min="1280"
                      :max="1500"
                      :step="8"
                      controls-position="right"
                    />
                    <span class="form-hint">建议 1492（PPPoE）或 1500</span>
                  </el-form-item>
      
                  <el-form-item label="获取 DNS">
                    <el-switch v-model="form.acquireDns" />
                    <span class="form-hint">{{ form.acquireDns ? '自动获取' : '手动配置' }}</span>
                  </el-form-item>
      
                  <el-form-item>
                    <el-button type="primary" @click="save">保存设置</el-button>
                    <el-button @click="reset">重置</el-button>
                  </el-form-item>
                </el-form>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { isMockMode } from '../../services/dataService.js'

const STORAGE_KEY = 'linehub:ipv6GlobalSettings'

const defaultForm = () => ({
  enabled: true,
  forwarding: true,
  dhcpv6Client: true,
  raService: true,
  defaultRoute: true,
  ndProxy: false,
  mtu: 1492,
  acquireDns: true,
})

const loading = ref(false)
const form = reactive(defaultForm())

function loadFromStorage() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      Object.assign(form, parsed)
    }
  } catch (e) {
    // ignore
  }
}

async function loadData() {
  loading.value = true
  try {
    if (isMockMode()) {
      loadFromStorage()
    } else {
      // 真实模式预留：GET /api/ipv6/settings
      loadFromStorage()
    }
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

async function save() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...form }))
    if (!isMockMode()) {
      // 真实模式预留：PUT /api/ipv6/settings
    }
    ElMessage.success('IPv6 全局设置已保存')
  } catch (e) {
    ElMessage.error('保存失败：' + e.message)
  }
}

function reset() {
  Object.assign(form, defaultForm())
  ElMessage.info('已重置为默认值（未保存）')
}

onMounted(loadData)
</script>

<style scoped>
.form-hint { margin-left: 12px; font-size: 13px; color: #888; }
:deep(.el-form-item__label) { font-size: 14px; }
:deep(.el-divider__text) { font-size: 14px; font-weight: 600; }
</style>
