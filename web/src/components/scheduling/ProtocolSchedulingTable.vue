<template>
  <div class="protocol-panel">
    <el-alert
      type="info"
      show-icon
      :closable="false"
      :title="`${protocolLabel}独立维护健康状态、调度资格、评分、排名、权重、故障摘除和恢复加入，不依赖另一种协议的结果。`"
    />
    <div class="threshold-summary">
      <span>高丢包快速降权：{{ thresholds.packetLossFastDropPercent }}%</span>
      <span>高传输重试快速降权：{{ thresholds.retransmissionFastDropPercent }}%</span>
      <span>故障摘除参考分：{{ thresholds.failureRemovalScore }}</span>
      <span>恢复加入参考分：{{ thresholds.recoveryJoinScore }}</span>
      <el-tooltip content="故障阈值用于快速保护新连接。恢复阈值高于摘除阈值，可以减少线路在临界状态反复加入和退出。">
        <el-icon><QuestionFilled /></el-icon>
      </el-tooltip>
    </div>

    <StandardTable layout-mode="scroll" :data="rows" border stripe class="protocol-table">
      <el-table-column prop="name" label="线路名称" min-width="155" fixed="left" />
      <el-table-column prop="carrier" label="运营商" min-width="100" />
      <el-table-column label="健康状态" min-width="105">
        <template #header>
          <HeaderHelp label="健康状态" text="表示当前协议的互联网连通性与健康检查结果。" />
        </template>
        <template #default="{ row }">
          <el-tag :type="healthType(row.protocol.healthState)" size="small">
            {{ row.protocol.healthState }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="调度资格" min-width="125">
        <template #header>
          <HeaderHelp label="调度资格" text="只有协议参数、连通性和健康检查都通过的线路，才会接收该协议的新连接。" />
        </template>
        <template #default="{ row }">
          <el-tag :type="row.protocol.eligible ? 'success' : 'info'" size="small">
            {{ row.protocol.eligibilityState }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="评分" min-width="78" align="center">
        <template #header>
          <HeaderHelp label="评分" text="综合质量分为0至100分，分数越高越适合承接新连接。" />
        </template>
        <template #default="{ row }">
          <strong>{{ Number(row.protocol.score).toFixed(1) }}</strong>
        </template>
      </el-table-column>
      <el-table-column label="排名" min-width="72" align="center">
        <template #default="{ row }">{{ row.protocol.rank || '—' }}</template>
      </el-table-column>
      <el-table-column label="当前权重" min-width="100" align="center">
        <template #header>
          <HeaderHelp label="当前权重" text="调度权重表示健康线路承接新连接的相对概率，数值越高越容易被选中。" />
        </template>
        <template #default="{ row }">{{ row.protocol.currentWeight }}</template>
      </el-table-column>
      <el-table-column label="推荐权重" min-width="105" align="center">
        <template #default="{ row }">
          <span :class="deltaClass(row)">
            {{ row.protocol.recommendedWeight }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="故障摘除" min-width="150">
        <template #header>
          <HeaderHelp label="故障摘除" text="该协议故障后立即停止分配新连接；已经建立的连接保持原出口。" />
        </template>
        <template #default="{ row }">
          <div>{{ row.protocol.failureState }}</div>
          <small>{{ row.protocol.removalState }}</small>
        </template>
      </el-table-column>
      <el-table-column label="恢复加入" min-width="135">
        <template #header>
          <HeaderHelp label="恢复加入" text="线路恢复后连续通过检测，再逐步增加新连接权重。" />
        </template>
        <template #default="{ row }">
          <el-tag :type="row.protocol.removed ? 'danger' : 'success'" size="small">
            {{ row.protocol.recoveryState }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="ruleHitCount" label="规则命中" min-width="95" align="right" />
    </StandardTable>
  </div>
</template>

<script setup>
import { defineComponent, h } from 'vue'
import { ElIcon, ElTooltip } from 'element-plus'
import { QuestionFilled } from '@element-plus/icons-vue'

defineProps({
  rows: { type: Array, default: () => [] },
  protocolLabel: { type: String, required: true },
  thresholds: { type: Object, required: true },
})

const HeaderHelp = defineComponent({
  props: {
    label: { type: String, required: true },
    text: { type: String, required: true },
  },
  setup(props) {
    return () => h('span', { class: 'table-header-help' }, [
      props.label,
      h(ElTooltip, { content: props.text }, {
        default: () => h(ElIcon, null, { default: () => h(QuestionFilled) }),
      }),
    ])
  },
})

function healthType(state) {
  return { 正常: 'success', 异常: 'danger', 离线: 'info' }[state] || 'warning'
}

function deltaClass(row) {
  const delta = row.protocol.recommendedWeight - row.protocol.currentWeight
  if (delta > 0) return 'weight-up'
  if (delta < 0) return 'weight-down'
  return ''
}
</script>

<style scoped>
.protocol-panel {
  min-width: 0;
}

.threshold-summary {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin: 12px 0;
  color: var(--lh-text-secondary);
  font-size: 12px;
}

.threshold-summary span {
  padding: 6px 9px;
  border-radius: 4px;
  background: var(--el-fill-color-lighter);
}

.threshold-summary :deep(.el-icon),
:deep(.table-header-help .el-icon) {
  color: var(--lh-primary);
  cursor: help;
}

:deep(.table-header-help) {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.protocol-table {
  --standard-table-scroll-width: 1250px;
}

.protocol-table small {
  display: block;
  margin-top: 3px;
  color: var(--lh-text-secondary);
  font-size: 11px;
}

.weight-up {
  color: #67c23a;
  font-weight: 700;
}

.weight-down {
  color: #f56c6c;
  font-weight: 700;
}
</style>
