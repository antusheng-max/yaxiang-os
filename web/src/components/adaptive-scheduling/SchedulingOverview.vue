<template>
  <div class="scheduling-overview">
    <AnalyticsMetricGrid :items="metricItems" :column-span="6" />

    <SectionCard shadow="never">
      <template #header>
        <HeaderHelp
          label="线路接入到调度的执行顺序"
          text="系统先读取运营商实际返回的信息，再验证连通性和入站能力，最后进行业务匹配与调度。"
        />
      </template>
      <div class="process-grid">
        <div v-for="(step, index) in executionSteps" :key="step" class="process-item">
          <span>{{ index + 1 }}</span>
          <p>{{ step }}</p>
        </div>
      </div>
    </SectionCard>

    <el-row :gutter="16">
      <el-col :xs="24" :lg="13">
        <SectionCard shadow="never">
          <template #header>自动识别结果</template>
          <div class="summary-grid">
            <div class="summary-item">
              <span>已识别线路</span>
              <strong>{{ capabilitySummary.total }} 条</strong>
              <small>覆盖宽带账号拨号、自动获取和指定VLAN通道接入。</small>
            </div>
            <div class="summary-item">
              <span>原生IPv6 + PD</span>
              <strong>{{ capabilitySummary.ipv6Pd }} 条</strong>
              <small>PD是运营商委派给路由器、可供局域网和服务器使用的IPv6公网前缀。</small>
            </div>
          </div>
        </SectionCard>
      </el-col>
      <el-col :xs="24" :lg="11">
        <SectionCard shadow="never">
          <template #header>
            <HeaderHelp
              label="接入参数从哪里获得"
              text="VLAN只是逻辑隔离通道；地址、域名服务器和默认路由来自VLAN通道上的宽带拨号或自动获取。"
            />
          </template>
          <el-alert type="warning" show-icon :closable="false" :title="sourceExplanation.notice" />
          <div class="source-list">
            <div v-for="source in sourceExplanation.sources" :key="source.title">
              <strong>{{ source.title }}</strong>
              <small>{{ source.description }}</small>
            </div>
          </div>
        </SectionCard>
      </el-col>
    </el-row>

    <SectionCard shadow="never">
      <template #header>
        <HeaderHelp label="调度边界" text="业务分流决定允许使用的线路池和调度模式；智能调度只在线路池内选择具体线路。" />
      </template>
      <div class="boundary-grid">
        <div><strong>业务分流</strong><p>识别业务、选择IPv4或IPv6线路池、设置优先级与故障兜底。</p></div>
        <el-icon><Right /></el-icon>
        <div><strong>智能线路调度</strong><p>过滤无资格线路，根据实时质量和权重为新连接选择具体出口。</p></div>
        <el-icon><Right /></el-icon>
        <div><strong>连接保持</strong><p>保存连接线路标记，已经建立的连接后续流量继续使用原线路。</p></div>
      </div>
    </SectionCard>
  </div>
</template>

<script setup>
import { Right } from '@element-plus/icons-vue'
import AnalyticsMetricGrid from '../AnalyticsMetricGrid.vue'

defineProps({
  metricItems: { type: Array, required: true },
  executionSteps: { type: Array, required: true },
  capabilitySummary: { type: Object, required: true },
  sourceExplanation: { type: Object, required: true },
})
</script>
