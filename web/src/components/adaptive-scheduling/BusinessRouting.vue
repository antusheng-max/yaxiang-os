<template>
  <SectionCard shadow="never">
    <template #header>
      <div class="card-header-actions">
        <HeaderHelp label="业务分流规则" text="线路池是一组满足同类能力条件的候选线路。规则只决定允许使用的线路池，具体线路仍由智能调度选择。" />
        <div>
          <el-button size="small" @click="$emit('openSimulation')">模拟匹配</el-button>
          <el-button type="primary" size="small" @click="$emit('openRuleEditor')">添加规则</el-button>
        </div>
      </div>
    </template>
    <el-alert v-if="ruleConflicts.length" type="warning" show-icon :closable="false" :title="`检测到 ${ruleConflicts.length} 组优先级和匹配范围重叠，请核对规则顺序。`" class="rule-conflict-alert" />
    <div class="template-grid">
      <button v-for="template in ruleTemplates" :key="template.id" type="button" class="template-card" @click="$emit('createFromTemplate', template.id)">
        <span>{{ template.name }}</span>
        <small>{{ template.description }}</small>
        <em>使用模板</em>
      </button>
    </div>
    <StandardTable layout-mode="scroll" :data="trafficRules" border stripe class="rule-table">
      <el-table-column label="排序" width="72" fixed="left" align="center">
        <template #default="{ row }">
          <span v-if="!row.immutable" class="drag-handle" draggable="true" title="拖动到另一条规则上调整优先级" @dragstart="$emit('startRuleDrag', row)" @dragover.prevent @drop="$emit('dropRule', row)">⋮⋮</span>
          <el-icon v-else title="系统保护规则"><Lock /></el-icon>
        </template>
      </el-table-column>
      <el-table-column prop="priority" label="优先级" width="80" align="center" />
      <el-table-column label="启用" width="75" align="center">
        <template #default="{ row }"><el-switch :model-value="row.enabled" :disabled="row.immutable" @change="$emit('toggleRule', row, $event)" /></template>
      </el-table-column>
      <el-table-column prop="name" label="规则名称" min-width="185" />
      <el-table-column label="IP版本" min-width="90">
        <template #default="{ row }">{{ ipVersionLabel(row.ipVersion) }}</template>
      </el-table-column>
      <el-table-column label="目标线路池" min-width="170">
        <template #default="{ row }">{{ poolLabel(row.targetPoolId) }}</template>
      </el-table-column>
      <el-table-column label="调度模式" min-width="130">
        <template #default="{ row }">{{ schedulingModeLabel(row.schedulingMode) }}</template>
      </el-table-column>
      <el-table-column label="操作" min-width="165" fixed="right">
        <template #default="{ row }">
          <el-button type="primary" link @click="$emit('openRuleEditor', row)">编辑</el-button>
          <el-button link @click="$emit('copyRule', row)">复制</el-button>
          <el-button type="danger" link :disabled="row.immutable" @click="$emit('removeRule', row)">删除</el-button>
        </template>
      </el-table-column>
    </StandardTable>
    <p class="table-hint">拖动左侧手柄可调整优先级。最后一条"默认智能调度"不可删除。</p>
  </SectionCard>
</template>

<script setup>
import { Lock } from '@element-plus/icons-vue'
defineProps({
  trafficRules: { type: Array, required: true },
  ruleTemplates: { type: Array, required: true },
  ruleConflicts: { type: Array, required: true },
  ipVersionLabel: { type: Function, required: true },
  poolLabel: { type: Function, required: true },
  schedulingModeLabel: { type: Function, required: true },
})
defineEmits(['openSimulation', 'openRuleEditor', 'createFromTemplate', 'startRuleDrag', 'dropRule', 'toggleRule', 'copyRule', 'removeRule'])
</script>
