<template>
  <div>
    <SectionCard shadow="never">
      <template #header>
        <HeaderHelp label="调度目标与权重" text="调度权重只表示新连接的相对选择概率；故障线路仍会按IPv4和IPv6分别摘除。" />
      </template>
      <el-form :model="settings" label-width="150px">
        <el-form-item>
          <template #label><HeaderHelp label="当前调度目标" text="IPv4和IPv6使用相同页面结构，但分别维护线路池、评分、排名和权重。" /></template>
          <el-radio-group v-model="settings.schedulingGoal" class="goal-options">
            <el-radio v-for="goal in schedulingGoals" :key="goal.value" :value="goal.value" border class="goal-option">
              <span class="goal-title">{{ goal.label }}<el-tag v-if="goal.badge" :type="goal.badge === '推荐' ? 'success' : 'warning'" size="small">{{ goal.badge }}</el-tag></span>
              <small>{{ goal.description }}</small>
            </el-radio>
          </el-radio-group>
          <div class="form-hint">{{ selectedGoal.detail }}</div>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :xs="24" :md="8"><el-form-item label="自动调度"><el-switch v-model="settings.enabled" /><div class="form-hint">只调整新连接；已建立连接保持原出口。</div></el-form-item></el-col>
          <el-col :xs="24" :md="8"><el-form-item label="最小权重"><el-input-number v-model="settings.minimumWeight" :min="1" :max="settings.maximumWeight" /><div class="form-hint">健康线路参与调度时允许使用的最低权重。</div></el-form-item></el-col>
          <el-col :xs="24" :md="8"><el-form-item label="最大权重"><el-input-number v-model="settings.maximumWeight" :min="settings.minimumWeight" :max="500" /><div class="form-hint">单条线路自动升权时不能超过此值。</div></el-form-item></el-col>
        </el-row>
        <div class="settings-actions">
          <el-button @click="$emit('resetSettings')">恢复默认值</el-button>
          <el-button type="primary" @click="$emit('saveSettings')">保存演示设置</el-button>
        </div>
      </el-form>
    </SectionCard>
    <el-row :gutter="16">
      <el-col :xs="24" :lg="12">
        <SectionCard shadow="never">
          <template #header><HeaderHelp label="网络优化评分参数" text="各项比例表示该指标在网络优化综合评分中的权重，合计100%。" /></template>
          <div class="score-weight-list">
            <div v-for="item in scoreWeightItems" :key="item.label" class="score-weight-item">
              <div><strong>{{ item.label }}</strong><small>{{ item.description }}</small></div>
              <b>{{ item.value }}%</b>
            </div>
          </div>
        </SectionCard>
      </el-col>
      <el-col :xs="24" :lg="12">
        <SectionCard shadow="never">
          <template #header><HeaderHelp label="故障阈值" text="故障阈值用于快速保护业务，恢复阈值设置得更高可避免线路反复加入和退出。" /></template>
          <StandardTable layout-mode="fill" :data="thresholdRows" border>
            <el-table-column prop="label" label="参数" min-width="150" />
            <el-table-column prop="value" label="当前值" min-width="100" />
            <el-table-column prop="description" label="中文说明" min-width="240" />
          </StandardTable>
        </SectionCard>
      </el-col>
    </el-row>
    <SectionCard shadow="never">
      <template #header>智能调度规则</template>
      <div class="process-grid">
        <div v-for="(rule, index) in schedulingRules" :key="rule" class="process-item">
          <span>{{ index + 1 }}</span>
          <p>{{ rule }}</p>
        </div>
      </div>
    </SectionCard>
  </div>
</template>

<script setup>
defineProps({
  settings: { type: Object, required: true },
  schedulingGoals: { type: Array, required: true },
  selectedGoal: { type: Object, required: true },
  scoreWeightItems: { type: Array, required: true },
  thresholdRows: { type: Array, required: true },
  schedulingRules: { type: Array, required: true },
})
defineEmits(['resetSettings', 'saveSettings'])
</script>
