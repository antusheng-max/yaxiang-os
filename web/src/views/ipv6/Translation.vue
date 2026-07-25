<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>NPTv6 / NAT66</h2>
      <p>展示系统自动生成的 IPv6 前缀转换规则（内部前缀与外部前缀/WAN 地址的映射关系）</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-alert
                  type="warning"
                  :closable="false"
                  show-icon
      
                >
                  这些规则由系统根据汇聚组配置自动生成，默认不允许手动编辑。
                </el-alert>
      
                <CardToolbar class="toolbar">
                  <el-button @click="loadData">刷新</el-button>
                </CardToolbar>
      
                <StandardTable layout-mode="scroll"
                  :data="list"
                  v-loading="loading"
                  size="default"
                  border
                  stripe
      
                >
                  <el-table-column label="内部前缀" min-width="220">
                    <template #default="{ row }">
                      <span class="mono">{{ getInternalPrefix(row) || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="外部前缀 / WAN 地址" min-width="220">
                    <template #default="{ row }">
                      <span class="mono">{{ row.pdPrefix || row.wanIpv6Address || '—' }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="线路" min-width="140">
                    <template #default="{ row }">{{ getDiName(row.dialInstanceId) }}</template>
                  </el-table-column>
                  <el-table-column label="汇聚组" min-width="140">
                    <template #default="{ row }">{{ getGroupName(row.aggregationGroupId) }}</template>
                  </el-table-column>
                  <el-table-column label="转换模式" min-width="130">
                    <template #default="{ row }">
                      <el-tag :type="translationTagType(row.translationMode)" effect="light">
                        <el-icon class="status-icon">
                          <Share v-if="row.translationMode === 'nptv6'" />
                          <Connection v-else-if="row.translationMode === 'nat66_fallback'" />
                          <Minus v-else />
                        </el-icon>
                        {{ translationText(row.translationMode) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="状态" min-width="120">
                    <template #default="{ row }">
                      <el-tag :type="statusTagType(row.status)" effect="light">
                        <el-icon class="status-icon">
                          <CircleCheck v-if="row.status === 'active'" />
                          <Warning v-else-if="row.status === 'no_pd'" />
                          <CircleClose v-else />
                        </el-icon>
                        {{ statusText(row.status) }}
                      </el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="最后更新时间" min-width="160">
                    <template #default="{ row }">{{ row.lastChangedAt || '—' }}</template>
                  </el-table-column>
                  <el-table-column label="操作" fixed="right">
                    <template #default="{ row }">
                      <el-button link type="primary" @click="openRule(row)">查看底层生成规则</el-button>
                    </template>
                  </el-table-column>
                </StandardTable>
      
                <StandardModal size="standard"
                  v-model="ruleVisible"
                  :title="`底层生成规则 — ${current?.dialInstanceId ? getDiName(current.dialInstanceId) : ''}`"
                >
                  <el-descriptions v-if="current" :column="1" border>
                    <el-descriptions-item label="线路">{{ getDiName(current.dialInstanceId) }}</el-descriptions-item>
                    <el-descriptions-item label="汇聚组">{{ getGroupName(current.aggregationGroupId) }}</el-descriptions-item>
                    <el-descriptions-item label="转换模式">
                      {{ translationText(current.translationMode) }}
                    </el-descriptions-item>
                    <el-descriptions-item label="WAN IPv6 地址">
                      <span class="mono">{{ current.wanIpv6Address || '—' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="外部 PD 前缀">
                      <span class="mono">{{ current.pdPrefix || '—' }}/{{ current.prefixLength || '' }}</span>
                    </el-descriptions-item>
                    <el-descriptions-item label="内部 LAN 前缀">
                      <span class="mono">{{ getInternalPrefix(current) || '—' }}</span>
                    </el-descriptions-item>
                  </el-descriptions>
      
                  <el-divider content-position="left">规则说明</el-divider>
      
                  <div class="rule-text">
                    <p v-if="current?.translationMode === 'nptv6'">
                      该线路已从运营商获得 PD 前缀
                      <code>{{ current?.pdPrefix }}/{{ current?.prefixLength }}</code>，
                      系统依据所属汇聚组 <code>{{ getGroupName(current?.aggregationGroupId) }}</code> 的 IPv6 设置
                      （模式：NPTv6，内部前缀：<code>{{ getInternalPrefix(current) }}</code>），
                      自动建立 NPTv6 一对一映射：LAN 内部地址段
                      <code>{{ getInternalPrefix(current) }}</code>
                      ↔ WAN 外部前缀
                      <code>{{ current?.pdPrefix }}/{{ current?.prefixLength }}</code>。
                      映射为无状态、可逆，不修改端口与协议。
                    </p>
                    <p v-else-if="current?.translationMode === 'nat66_fallback'">
                      该线路未获得可用的 PD 前缀（状态：无 PD），但双栈线路汇聚
                      <code>{{ getGroupName(current?.aggregationGroupId) }}</code>
                      的「无 PD 线路处理策略」配置为 NAT66 回退。系统自动以该线路 WAN 地址
                      <code>{{ current?.wanIpv6Address || '—' }}</code>
                      作为外部地址，对 LAN 内部前缀
                      <code>{{ getInternalPrefix(current) }}</code>
                      进行有状态 NAT66 转换。当线路重新获得 PD 前缀后，系统将自动切换为 NPTv6。
                    </p>
                    <p v-else>
                      该线路 IPv6 处于离线状态，或所属双栈线路汇聚未启用 IPv6，系统未生成任何转换规则。
                    </p>
                    <p class="rule-note">
                      注：以上规则由系统根据双栈线路汇聚与线路配置自动生成，默认不允许手动编辑。
                      如需调整，请修改对应汇聚组的 IPv6 设置。
                    </p>
                  </div>
      
                  <template #footer>
                    <el-button @click="ruleVisible = false">关闭</el-button>
                  </template>
                </StandardModal>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  CircleCheck, CircleClose, Warning, Share, Connection, Minus,
} from '@element-plus/icons-vue'
import {
  ipv6PrefixService, dialInstanceService, aggregationGroupService,
} from '../../services/dataService.js'

const list = ref([])
const dials = ref([])
const groups = ref([])
const loading = ref(false)
const ruleVisible = ref(false)
const current = ref(null)

function getDiName(id) {
  if (!id) return '—'
  const d = dials.value.find(x => x.id === id)
  return d ? d.name : '—'
}

function getGroupName(id) {
  if (!id) return '—'
  const g = groups.value.find(x => x.id === id)
  return g ? g.name : '—'
}

function getInternalPrefix(row) {
  if (!row?.aggregationGroupId) return ''
  const g = groups.value.find(x => x.id === row.aggregationGroupId)
  return g?.ipv6Settings?.lanInternalPrefix || ''
}

function translationText(mode) {
  return {
    nptv6: 'NPTv6',
    nat66_fallback: 'NAT66 回退',
    none: '无',
  }[mode] || mode
}

function translationTagType(mode) {
  return {
    nptv6: 'success',
    nat66_fallback: 'warning',
    none: 'info',
  }[mode] || 'info'
}

function statusText(s) {
  return {
    active: '有效',
    no_pd: '无 PD',
    ipv6_offline: 'IPv6 离线',
    expired: '已过期',
  }[s] || s
}

function statusTagType(s) {
  return {
    active: 'success',
    no_pd: 'warning',
    ipv6_offline: 'info',
    expired: 'danger',
  }[s] || 'info'
}

function openRule(row) {
  current.value = row
  ruleVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const [pm, d, g] = await Promise.all([
      ipv6PrefixService.list(),
      dialInstanceService.list(),
      aggregationGroupService.list(),
    ])
    list.value = pm
    dials.value = d
    groups.value = g
  } catch (e) {
    ElMessage.error('加载失败：' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.mono { font-family: monospace; font-size: 13px; word-break: break-all; }
.status-icon { margin-right: 4px; vertical-align: middle; }
.rule-text p { font-size: 14px; line-height: 1.7; margin: 0 0 8px 0; }
.rule-text code {
  font-family: monospace; background: #f5f7fa; padding: 1px 6px;
  border-radius: 3px; font-size: 13px;
}
.rule-note { color: #888; font-size: 13px; }
:deep(.el-table td) { padding: 8px 0; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-descriptions__label) { font-size: 14px; }
:deep(.el-divider__text) { font-size: 14px; font-weight: 600; }
</style>
