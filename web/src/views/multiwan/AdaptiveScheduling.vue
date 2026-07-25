<template>
  <PageContainer>
    <PageHeader title="智能线路调度" description="先自动识别每条线路的IPv4、IPv6与内容分发能力，再按业务分流规则选择线路池，并只为新连接选择具体出口。">
      <template #actions>
        <el-tag type="warning" effect="dark">前端Mock演示</el-tag>
        <el-button size="small" :loading="loading" @click="loadData">重新检测</el-button>
      </template>
    </PageHeader>

    <SectionCard class="page-section-frame" shadow="never" content-padding="none" v-loading="loading">
      <el-alert type="info" show-icon :closable="false" title="本页面只读取并修改前端Mock数据，不会写入拨号、路由、UCI、nftables、防火墙或系统网络接口。" />

      <el-tabs v-model="activeTab" class="scheduling-tabs">
        <el-tab-pane label="调度总览" name="overview">
          <SchedulingOverview :metric-items="metricItems" :execution-steps="executionSteps" :capability-summary="capabilitySummary" :source-explanation="sourceExplanation" />
        </el-tab-pane>
        <el-tab-pane label="线路排名" name="ranking">
          <LineRanking :capability-rows="capabilityRows" :yes-no="yesNo" @open-capability="openCapability" />
        </el-tab-pane>
        <el-tab-pane label="业务分流" name="business">
          <BusinessRouting :traffic-rules="trafficRules" :rule-templates="ruleTemplates" :rule-conflicts="ruleConflicts" :ip-version-label="ipVersionLabel" :pool-label="poolLabel" :scheduling-mode-label="schedulingModeLabel" @open-simulation="simulationVisible = true" @open-rule-editor="openRuleEditor" @create-from-template="createFromTemplate" @start-rule-drag="startRuleDrag" @drop-rule="dropRule" @toggle-rule="toggleRule" @copy-rule="copyRule" @remove-rule="removeRule" />
        </el-tab-pane>
        <el-tab-pane label="IPv4调度" name="ipv4">
          <IPv4Scheduling :ipv4-rows="ipv4Rows" :thresholds="thresholds" />
        </el-tab-pane>
        <el-tab-pane label="IPv6调度" name="ipv6">
          <IPv6Scheduling :ipv6-rows="ipv6Rows" :thresholds="thresholds" />
        </el-tab-pane>
        <el-tab-pane label="命中记录" name="hits">
          <HitRecords :hit-metric-items="hitMetricItems" :hit-records="hitRecords" :change-logs="changeLogs" :rule-label="ruleLabel" :pool-label="poolLabel" :line-label="lineLabel" :format-bytes="formatBytes" />
        </el-tab-pane>
        <el-tab-pane label="高级参数" name="advanced">
          <AdvancedParameters :settings="settings" :scheduling-goals="schedulingGoals" :selected-goal="selectedGoal" :score-weight-items="scoreWeightItems" :threshold-rows="thresholdRows" :scheduling-rules="schedulingRules" @reset-settings="resetSettings" @save-settings="saveSettings" />
        </el-tab-pane>
        <el-tab-pane label="本网流量控制" name="provincial-traffic">
          <ProvincialTrafficControl :provincial-config="provincialConfig" :provincial-metrics="provincialMetrics" :carrier-options="carrierOptions" :control-mode-options="controlModeOptions" :ipv4-classification="ipv4Classification" :ipv6-classification="ipv6Classification" :provincial-line-details="provincialLineDetails" :format-bytes="formatBytes" />
        </el-tab-pane>
        <el-tab-pane label="网络优化" name="network-optimization">
          <NetworkOptimization :probe-lines="probeLines" :probe-summary-metrics="probeSummaryMetrics" :probe-stage-tag-type="probeStageTagType" />
        </el-tab-pane>
        <el-tab-pane label="次网络优化" name="sub-network-optimization">
          <SecondaryNetworkOptimization :sub-probe-summary-metrics="subProbeSummaryMetrics" :sub-probe-ranking="subProbeRanking" />
        </el-tab-pane>
        <el-tab-pane label="优化记录" name="optimization-history">
          <OptimizationHistory :probe-history="probeHistory" />
        </el-tab-pane>
      </el-tabs>
    </SectionCard>

    <StandardDrawer v-model="capabilityDrawerVisible" size="large" title="线路能力详情">
      <template v-if="selectedCapability">
        <div class="drawer-title">
          <div><h3>{{ selectedCapability.lineName }}</h3><p>{{ selectedCapability.carrier }} · {{ selectedCapability.accessMeta.label }}</p></div>
          <el-button size="small" @click="redetectLine(selectedCapability)">重新检测Mock</el-button>
        </div>
        <el-descriptions :column="2" border class="capability-descriptions">
          <el-descriptions-item label="IPv4调度资格">{{ qualificationText(selectedCapability.ipv4SchedulingEligible, selectedCapability.ipv4IneligibleReason) }}</el-descriptions-item>
          <el-descriptions-item label="IPv6调度资格">{{ qualificationText(selectedCapability.ipv6SchedulingEligible, selectedCapability.ipv6IneligibleReason) }}</el-descriptions-item>
          <el-descriptions-item label="IPv6原生LAN资格">{{ selectedCapability.ipv6NativeLanEligible ? '具备，可向局域网提供原生公网前缀' : '不具备，未获得可分配的运营商前缀' }}</el-descriptions-item>
          <el-descriptions-item label="系统自动处理方式">{{ autoHandlingText(selectedCapability) }}</el-descriptions-item>
          <el-descriptions-item label="IPv4 入站资格">{{ qualificationText(selectedCapability.cdnIpv4InboundEligible, selectedCapability.inboundFailureReason) }}</el-descriptions-item>
          <el-descriptions-item label="IPv6 入站资格">{{ qualificationText(selectedCapability.cdnIpv6InboundEligible, selectedCapability.inboundFailureReason) }}</el-descriptions-item>
          <el-descriptions-item label="回程对称性">{{ selectedCapability.returnPathSymmetric ? '通过，入站和回程使用同一线路' : '未通过或尚未确认' }}</el-descriptions-item>
          <el-descriptions-item label="公网端口可达性">{{ selectedCapability.publicReachability === 'reachable' ? '可达，公网连接测试通过' : '不可达或尚未确认' }}</el-descriptions-item>
          <el-descriptions-item label="发布地址" :span="2">{{ selectedCapability.publishedAddresses.join('、') || '没有可发布的公网地址' }}</el-descriptions-item>
          <el-descriptions-item label="不可用原因" :span="2">{{ unavailableReason(selectedCapability) }}</el-descriptions-item>
        </el-descriptions>
        <h4 class="drawer-section-title">参数识别结果<el-tooltip content="域名服务器负责把域名转换为IP地址。IPv6-PD是运营商委派给局域网使用的公网前缀。"><el-icon><QuestionFilled /></el-icon></el-tooltip></h4>
        <StandardTable layout-mode="fill" :data="capabilityParameters" border stripe>
          <el-table-column prop="group" label="参数组" min-width="95" />
          <el-table-column prop="label" label="参数" min-width="170" />
          <el-table-column label="状态" min-width="95"><template #default="{ row }"><el-tag :type="parameterStateMeta(row.state).tagType" size="small">{{ parameterStateMeta(row.state).label }}</el-tag></template></el-table-column>
          <el-table-column prop="value" label="实际返回值" min-width="230" />
        </StandardTable>
        <h4 class="drawer-section-title">接入方式说明</h4>
        <p class="drawer-help">{{ selectedCapability.accessMeta.detail }}</p>
      </template>
    </StandardDrawer>

    <StandardModal v-model="ruleEditorVisible" :title="editingRule.id ? '编辑业务分流规则' : '添加业务分流规则'" size="large" @submit="saveRule">
      <el-form :model="editingRule" label-width="125px">
        <el-row :gutter="16">
          <el-col :xs="24" :md="12"><el-form-item label="规则名称"><el-input v-model="editingRule.name" /></el-form-item></el-col>
          <el-col :xs="24" :md="6"><el-form-item label="启用状态"><el-switch v-model="editingRule.enabled" /></el-form-item></el-col>
          <el-col :xs="24" :md="6"><el-form-item label="IP版本"><el-select v-model="editingRule.ipVersion"><el-option v-for="option in ipVersionOptions" :key="option.value" :label="option.label" :value="option.value" /></el-select></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="来源局域网"><el-input v-model="editingRule.sourceLan" placeholder="例如：办公局域网" /></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="来源设备"><el-input v-model="editingRule.sourceDevice" placeholder="可选设备名称" /></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="来源IP或网段"><el-input v-model="editingRule.sourceCidr" placeholder="例如：192.168.1.0/24" /></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="目标域名"><el-input v-model="editingRule.destinationDomain" placeholder="可使用逗号分隔" /></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="业务类型"><el-select v-model="editingRule.businessType"><el-option v-for="type in businessTypes" :key="type" :label="type" :value="type" /></el-select></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="目标线路池"><el-select v-model="editingRule.targetPoolId"><el-option v-for="pool in linePools" :key="pool.id" :label="pool.name" :value="pool.id" /></el-select></el-form-item></el-col>
          <el-col :xs="24" :md="12"><el-form-item label="调度模式"><el-select v-model="editingRule.schedulingMode"><el-option v-for="mode in schedulingModes" :key="mode.value" :label="mode.label" :value="mode.value" /></el-select></el-form-item></el-col>
        </el-row>
      </el-form>
    </StandardModal>

    <StandardModal v-model="simulationVisible" title="业务分流模拟匹配" size="standard" @submit="runSimulation">
      <el-form :model="simulationInput" label-width="120px">
        <el-form-item label="来源IP"><el-input v-model="simulationInput.sourceIp" placeholder="例如：192.168.1.20" /></el-form-item>
        <el-form-item label="目标IP或域名"><el-input v-model="simulationInput.destination" placeholder="例如：upload.cdn.example" /></el-form-item>
        <el-form-item label="协议"><el-select v-model="simulationInput.protocol"><el-option label="TCP" value="TCP" /><el-option label="UDP" value="UDP" /></el-select></el-form-item>
        <el-form-item label="目标端口"><el-input v-model="simulationInput.port" placeholder="例如：443" /></el-form-item>
        <el-form-item label="IP版本"><el-select v-model="simulationInput.ipVersion"><el-option label="IPv4" value="IPv4" /><el-option label="IPv6" value="IPv6" /></el-select></el-form-item>
      </el-form>
      <el-descriptions v-if="simulationResult" :column="1" border class="simulation-result">
        <el-descriptions-item label="业务识别">{{ simulationResult.classification.businessType }}：{{ simulationResult.classification.reason }}</el-descriptions-item>
        <el-descriptions-item label="命中的规则">{{ simulationResult.matchedRule?.name || '默认智能调度' }}</el-descriptions-item>
        <el-descriptions-item label="进入的线路池">{{ simulationResult.pool?.name || '没有可用线路池' }}</el-descriptions-item>
        <el-descriptions-item label="有资格的线路">{{ simulationResult.eligibleLines.map(item => item.lineName).join('、') || '暂无' }}</el-descriptions-item>
        <el-descriptions-item label="当前可能选择">{{ simulationResult.possibleLine?.lineName || '暂无可选线路' }}</el-descriptions-item>
        <el-descriptions-item label="选择原因">{{ simulationResult.reason }}</el-descriptions-item>
      </el-descriptions>
    </StandardModal>
  </PageContainer>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, reactive, ref } from 'vue'
import { ElIcon, ElMessage, ElMessageBox, ElTooltip } from 'element-plus'
import { QuestionFilled } from '@element-plus/icons-vue'
import SchedulingOverview from '../../components/adaptive-scheduling/SchedulingOverview.vue'
import LineRanking from '../../components/adaptive-scheduling/LineRanking.vue'
import BusinessRouting from '../../components/adaptive-scheduling/BusinessRouting.vue'
import IPv4Scheduling from '../../components/adaptive-scheduling/IPv4Scheduling.vue'
import IPv6Scheduling from '../../components/adaptive-scheduling/IPv6Scheduling.vue'
import HitRecords from '../../components/adaptive-scheduling/HitRecords.vue'
import AdvancedParameters from '../../components/adaptive-scheduling/AdvancedParameters.vue'
import ProvincialTrafficControl from '../../components/adaptive-scheduling/ProvincialTrafficControl.vue'
import NetworkOptimization from '../../components/adaptive-scheduling/NetworkOptimization.vue'
import SecondaryNetworkOptimization from '../../components/adaptive-scheduling/SecondaryNetworkOptimization.vue'
import OptimizationHistory from '../../components/adaptive-scheduling/OptimizationHistory.vue'
import { getAccessTypeMeta, getIpv6CapabilityMeta, PARAMETER_STATE_OPTIONS } from '../../models/lineCapability.js'
import { IP_VERSION_OPTIONS, RULE_EXECUTION_STEPS, RULE_SCHEDULING_MODES, createTrafficRule } from '../../models/trafficRules.js'
import { SCHEDULING_GOALS, SCORE_FACTOR_DESCRIPTIONS } from '../../models/trafficAnalytics.js'
import { flowClassificationService, lineCapabilityService, lineDetectionService, linePoolService, ruleHitStatisticsService, schedulingSimulationService, trafficRuleService } from '../../services/networkIntelligenceServices.js'
import { probeSchedulingService } from '../../services/probeSchedulingService.js'
import { provincialTrafficTelemetryService, flowRegionClassifierService, provincialRateControllerService, platformRegionAdapterService } from '../../services/provincialTrafficControlService.js'
import { CONTROL_MODE_LABEL, CARRIERS, createProvincialTrafficConfig } from '../../models/provincialTrafficControl.js'
import { PROBE_STAGE, PROBE_STAGE_LABEL, OPTIMIZATION_MODE } from '../../models/probeLineOptimization.js'
import { adaptiveSchedulingService, lineQualityService } from '../../services/trafficAnalyticsServices.js'
import { formatBytes } from '../../utils/trafficFormat.js'

const HeaderHelp = defineComponent({
  props: { label: { type: String, required: true }, text: { type: String, required: true } },
  setup(props) {
    return () => h('span', { class: 'header-help' }, [props.label, h(ElTooltip, { content: props.text }, { default: () => h(ElIcon, null, { default: () => h(QuestionFilled) }) })])
  },
})

const activeTab = ref('overview')
const loading = ref(false)
const capabilities = ref([])
const qualityLines = ref([])
const recommendations = ref([])
const trafficRules = ref([])
const linePools = ref([])
const ruleTemplates = ref([])
const businessTypes = ref([])
const ruleConflicts = ref([])
const hitRecords = ref([])
const changeLogs = ref([])
const capabilityParameters = ref([])
const capabilitySummary = reactive({ total: 0, ipv4Eligible: 0, ipv6Eligible: 0, ipv6Pd: 0, ipv6NoPd: 0, abnormal: 0 })
const hitSummary = reactive({ totalHits: 0, totalBytes: 0, activeRules: 0, fallbackHits: 0 })
const sourceExplanation = reactive({ notice: '', sources: [] })
const settings = reactive({})
const schedulingRules = ref([])
const scoreWeights = ref({})
const thresholds = reactive({ packetLossFastDropPercent: 3, retransmissionFastDropPercent: 3, failureRemovalScore: 35, recoveryJoinScore: 65 })
const capabilityDrawerVisible = ref(false)
const selectedCapability = ref(null)
const ruleEditorVisible = ref(false)
const editingRule = reactive(createTrafficRule())
const simulationVisible = ref(false)
const simulationInput = reactive({ sourceIp: '192.168.1.20', destination: 'upload.cdn.example', protocol: 'TCP', port: '443', ipVersion: 'IPv6' })
const simulationResult = ref(null)
const draggedRuleId = ref('')

// 本网流量控制
const provincialConfig = reactive(createProvincialTrafficConfig())
const provincialOverview = ref({})
const provincialLineDetails = ref([])
const ipv4Classification = ref([])
const ipv6Classification = ref([])
const ipv4Stats = ref({})
const ipv6Stats = ref({})
const controlState = ref({ status: 'normal', statusLabel: '正常调度', currentRate: 0, targetRate: 30, hardLimitRate: 50, reason: '' })
const provincialPlatformHasData = ref(false)
const provincialPlatformNotice = ref('')
const carrierOptions = CARRIERS
const controlModeOptions = Object.entries(CONTROL_MODE_LABEL).map(([value, label]) => ({ value, label }))

// 极限探测
const probeLines = ref([])
const probeSummary = ref({})
const subProbeLines = ref([])
const subProbeSummary = ref({})
const subProbeRanking = ref([])
const probeHistory = ref([
  { time: '2026-07-24 17:20:00', lineId: 'probe-001', lineName: '电信线路 A', ipFamily: 'ipv4', targetBefore: 460, targetAfter: 480, weightBefore: 36, weightAfter: 38, breakthroughPercent: 119, reason: '有效上传持续增长，加压至480Mbps', triggerMetrics: 'effective=470Mbps, retrans=1.6%', result: '持续极限476M已确认' },
  { time: '2026-07-24 17:18:00', lineId: 'probe-004', lineName: '广电线路 D', ipFamily: 'ipv4', targetBefore: 450, targetAfter: 460, weightBefore: 28, weightAfter: 30, breakthroughPercent: 115, reason: '突发可达520M，验证持续极限', triggerMetrics: 'burst=520Mbps, effective=445Mbps', result: '持续极限460M确认中' },
])
const probeHasPlatformData = ref(false)

const executionSteps = RULE_EXECUTION_STEPS
const schedulingGoals = SCHEDULING_GOALS
const schedulingModes = RULE_SCHEDULING_MODES
const ipVersionOptions = IP_VERSION_OPTIONS

const selectedGoal = computed(() => schedulingGoals.find(item => item.value === settings.schedulingGoal) || schedulingGoals[0])
const capabilityRows = computed(() => capabilities.value.map((line) => ({ ...line, accessMeta: getAccessTypeMeta(line.accessType), ipv6Meta: getIpv6CapabilityMeta(line), qualityScore: qualityById.value.get(line.lineId)?.totalScore || 0 })))
const qualityById = computed(() => new Map(qualityLines.value.map(item => [item.lineId, item])))
const protocolRows = protocol => recommendations.value.map((line) => ({ ...line, protocol: line.protocolScheduling[protocol], ruleHitCount: hitRecords.value.filter(item => item.lineId === line.lineId && item.ipVersion.toLowerCase() === protocol).length })).sort((a, b) => (a.protocol.rank ?? 999) - (b.protocol.rank ?? 999))
const ipv4Rows = computed(() => protocolRows('ipv4'))
const ipv6Rows = computed(() => protocolRows('ipv6'))

const metricItems = computed(() => {
  const configured = recommendations.value.reduce((sum, item) => sum + item.configuredUploadMbps, 0)
  const uploading = recommendations.value.reduce((sum, item) => sum + item.currentUploadMbps, 0)
  const utilization = configured ? uploading / configured * 100 : 0
  return [
    { label: '总配置上行', value: `${configured.toFixed(0)} 兆比特/秒`, hint: '所有宽带配置上行能力之和。' },
    { label: '当前总上传', value: `${uploading.toFixed(1)} 兆比特/秒`, tone: 'primary', hint: '所有线路当前上传速率之和。' },
    { label: '当前综合利用率', value: `${utilization.toFixed(1)}%`, tone: utilization >= Number(settings.targetUtilization || 93) ? 'warning' : 'success', hint: '当前上传占总配置上行比例。' },
    { label: 'IPv4可用线路', value: `${capabilitySummary.ipv4Eligible} 条`, tone: 'success', hint: 'IPv4参数、连通性和健康检查均通过。' },
    { label: 'IPv6可用线路', value: `${capabilitySummary.ipv6Eligible} 条`, tone: 'success', hint: '无PD但兼容出站检测通过的线路也会计入。' },
    { label: '当前调度模式', value: selectedGoal.value.label, tone: 'primary', hint: selectedGoal.value.description },
    { label: '预计剩余上行能力', value: `${Math.max(0, configured - uploading).toFixed(1)} 兆比特/秒`, tone: 'success', hint: '配置上行减去当前上传的估算值。' },
  ]
})

const hitMetricItems = computed(() => [
  { label: '累计命中次数', value: hitSummary.totalHits.toLocaleString(), tone: 'primary', hint: '所有Mock规则累计命中次数。' },
  { label: '累计命中流量', value: formatBytes(hitSummary.totalBytes), tone: 'success', hint: '所有Mock规则累计处理流量。' },
  { label: '启用规则', value: `${hitSummary.activeRules} 条`, hint: '包含系统保护的默认兜底规则。' },
  { label: '兜底规则命中', value: hitSummary.fallbackHits.toLocaleString(), tone: 'warning', hint: '未命中其他规则后进入默认智能调度的次数。' },
])

const scoreWeightItems = computed(() => Object.entries(SCORE_FACTOR_DESCRIPTIONS).map(([key, item]) => ({ ...item, value: Number(((scoreWeights.value[key] || 0) * 100).toFixed(0)) })))
const thresholdRows = computed(() => [
  { label: '高丢包快速降权', value: `${thresholds.packetLossFastDropPercent}%`, description: '丢包达到该比例时快速减少新连接权重。' },
  { label: '高传输重试快速降权', value: `${thresholds.retransmissionFastDropPercent}%`, description: 'TCP传输重试达到该比例时快速减少新连接权重。' },
  { label: '故障摘除参考分', value: thresholds.failureRemovalScore, description: '评分低于参考值时停止向该协议分配新连接。' },
  { label: '恢复加入参考分', value: thresholds.recoveryJoinScore, description: '线路恢复并达到参考分后逐步重新加入。' },
])

const provincialMetrics = computed(() => {
  const o = provincialOverview.value
  return [
    { label: '本地省份', value: o.localProvince || '--' }, { label: '本地运营商', value: o.localCarrier || '--' },
    { label: '当前总有效上传', value: formatBytes(o.currentTotalEffectiveUpload || 0) },
    { label: '同省同网流量', value: formatBytes(o.sameProvinceSameCarrierBytes || 0) },
    { label: '跨省同网流量', value: formatBytes(o.crossProvinceSameCarrierBytes || 0) },
    { label: '总体出省率', value: `${o.overallCrossProvinceRate || 0}%` }, { label: '本网出省率', value: `${o.carrierCrossProvinceRate || 0}%` },
    { label: '目标出省率', value: `${o.targetCrossProvinceRate || 0}%` }, { label: 'IPv4出省率', value: `${o.ipv4CrossProvinceRate || 0}%` },
    { label: 'IPv6出省率', value: `${o.ipv6CrossProvinceRate || 0}%` }, { label: '识别覆盖率', value: `${o.identificationCoverage || 0}%` },
    { label: '未知流量比例', value: `${o.unknownRatio || 0}%` },
  ]
})

const probeSummaryMetrics = computed(() => {
  const s = probeSummary.value
  return [
    { label: '总标称上行', value: `${s.totalAdvertisedUploadMbps || 0} Mbps` },
    { label: '当前总有效上传', value: `${s.currentTotalEffectiveUploadMbps || 0} Mbps` },
    { label: '已发现持续极限', value: `${s.discoveredSustainedMaximumMbps || 0} Mbps` },
    { label: '历史突发极限', value: `${s.historicalBurstMaximumMbps || 0} Mbps` },
    { label: '综合标称突破率', value: `${s.comprehensiveBreakthroughPercent || 0}%` },
    { label: '当前极限利用率', value: `${s.currentMaximumUtilizationPercent || 0}%` },
  ]
})

const subProbeSummaryMetrics = computed(() => {
  const s = subProbeSummary.value
  return [
    { label: '总标称上行', value: `${s.totalAdvertisedUploadMbps || 0} Mbps` },
    { label: '当前总有效上传', value: `${s.currentTotalEffectiveUploadMbps || 0} Mbps` },
    { label: '已发现持续极限', value: `${s.discoveredSustainedMaximumMbps || 0} Mbps` },
    { label: '历史突发极限', value: `${s.historicalBurstMaximumMbps || 0} Mbps` },
    { label: '综合标称突破率', value: `${s.comprehensiveBreakthroughPercent || 0}%` },
    { label: '当前极限利用率', value: `${s.currentMaximumUtilizationPercent || 0}%` },
  ]
})

function yesNo(v) { return v ? '可用' : '不可用' }
function parameterStateMeta(state) { return PARAMETER_STATE_OPTIONS[state] || PARAMETER_STATE_OPTIONS.missing }
function qualificationText(eligible, reason) { return eligible ? '具备，可加入对应线路池' : `暂不具备：${reason || '能力检测未通过'}` }
function autoHandlingText(line) {
  if (line.ipv6NativeLanEligible) return '使用运营商原生IPv6前缀参与双栈调度'
  if (line.ipv6SchedulingEligible && line.ipv6GlobalAddresses.length) return line.ipv6CompatibilityMode === 'nat66_outbound' ? '使用NAT66兼容出站（高级）' : '保留IPv6出站资格'
  if (line.ipv4SchedulingEligible) return '仅退出IPv6线路池，IPv4继续参与调度'
  return '对应协议暂时摘除，等待健康检测恢复'
}
function unavailableReason(line) { return [line.ipv4IneligibleReason && `IPv4：${line.ipv4IneligibleReason}`, line.ipv6IneligibleReason && `IPv6：${line.ipv6IneligibleReason}`, line.inboundFailureReason && `入站：${line.inboundFailureReason}`].filter(Boolean).join('；') || '当前没有不可用项' }
function ipVersionLabel(v) { return ipVersionOptions.find(i => i.value === v)?.label || '双栈' }
function schedulingModeLabel(v) { return schedulingModes.find(i => i.value === v)?.label || '网络优化' }
function poolLabel(id) { return linePools.value.find(i => i.id === id)?.name || '默认健康线路池' }
function lineLabel(id) { return capabilities.value.find(i => i.lineId === id)?.lineName || '未知线路' }
function ruleLabel(id) { return trafficRules.value.find(i => i.id === id)?.name || '已迁移规则' }
function probeStageTagType(stage) { const map = { [PROBE_STAGE.WAITING]: 'info', [PROBE_STAGE.NOMINAL]: 'info', [PROBE_STAGE.STEPPING]: 'warning', [PROBE_STAGE.FAST_BREAKTHROUGH]: 'success', [PROBE_STAGE.SUSTAINED_VERIFY]: 'success', [PROBE_STAGE.BURST_VERIFY]: 'success', [PROBE_STAGE.STAGNATION]: 'warning', [PROBE_STAGE.CONGESTION_BACKOFF]: 'warning', [PROBE_STAGE.REPROBE]: 'info', [PROBE_STAGE.LOCKED]: 'success', [PROBE_STAGE.FAULT]: 'danger' }; return map[stage] || 'info' }

async function loadData() {
  loading.value = true
  try {
    const [capRes, sumRes, srcRes, qRes, recRes, setRes, modRes, ruleRes, poolRes, tplRes, typeRes, confRes, hitRes, hitSumRes, chgRes] = await Promise.all([
      lineCapabilityService.list(), lineCapabilityService.getSummary(), lineDetectionService.getSourceExplanation(), lineQualityService.listLines(),
      adaptiveSchedulingService.getRecommendations(), adaptiveSchedulingService.getSettings(), adaptiveSchedulingService.getModelDescription(),
      trafficRuleService.list(), linePoolService.list(), trafficRuleService.listTemplates(), flowClassificationService.listBusinessTypes(),
      trafficRuleService.getConflicts(), ruleHitStatisticsService.list(), ruleHitStatisticsService.getSummary(), trafficRuleService.listChangeLogs(),
    ])
    capabilities.value = capRes.data; Object.assign(capabilitySummary, sumRes.data); Object.assign(sourceExplanation, srcRes.data)
    qualityLines.value = qRes.data; recommendations.value = recRes.data; Object.assign(settings, setRes.data)
    schedulingRules.value = modRes.data.rules; scoreWeights.value = modRes.data.scoreWeights; Object.assign(thresholds, modRes.data.thresholds)
    trafficRules.value = ruleRes.data; linePools.value = poolRes.data; ruleTemplates.value = tplRes.data; businessTypes.value = typeRes.data
    ruleConflicts.value = confRes.data; hitRecords.value = hitRes.data; Object.assign(hitSummary, hitSumRes.data); changeLogs.value = chgRes.data
  } finally { loading.value = false }
}

async function loadProvincialData() {
  const cfg = { ...provincialConfig }
  const [oR, lR, v4R, v6R, cR, pR] = await Promise.all([provincialTrafficTelemetryService.getOverview(cfg), provincialTrafficTelemetryService.getLineDetails(cfg), flowRegionClassifierService.getClassificationStats('ipv4', cfg), flowRegionClassifierService.getClassificationStats('ipv6', cfg), provincialRateControllerService.evaluateAndControl(cfg, { overallCrossProvinceRate: 0, identificationCoverage: 80 }), platformRegionAdapterService.getPlatformData()])
  provincialOverview.value = oR.data; provincialLineDetails.value = lR.data; ipv4Stats.value = v4R.data; ipv6Stats.value = v6R.data; controlState.value = cR.data; provincialPlatformHasData.value = pR.data.hasData; provincialPlatformNotice.value = pR.data.message
  const buildTable = (s) => { const t = s.totalEffectiveBytes || 1; return ['同省同网','同省异网','跨省同网','跨省异网','无法确认'].map((l, i) => ({ categoryLabel: l, bytes: [s.sameProvinceSameCarrierBytes, s.sameProvinceDiffCarrierBytes, s.crossProvinceSameCarrierBytes, s.crossProvinceDiffCarrierBytes, s.unknownBytes][i], ratio: Math.round(([s.sameProvinceSameCarrierBytes, s.sameProvinceDiffCarrierBytes, s.crossProvinceSameCarrierBytes, s.crossProvinceDiffCarrierBytes, s.unknownBytes][i] / t) * 10000) / 100 })) }
  ipv4Classification.value = buildTable(v4R.data); ipv6Classification.value = buildTable(v6R.data)
}

async function loadProbeData() {
  const [lR, sR, rR] = await Promise.all([probeSchedulingService.getLines(OPTIMIZATION_MODE.NETWORK), probeSchedulingService.getSummary(OPTIMIZATION_MODE.NETWORK), probeSchedulingService.getBreakthroughRanking()])
  probeLines.value = lR.data; probeSummary.value = sR.data; subProbeRanking.value = rR.data
  const [sLR, sSR] = await Promise.all([probeSchedulingService.getLines(OPTIMIZATION_MODE.SUB_NETWORK), probeSchedulingService.getSummary(OPTIMIZATION_MODE.SUB_NETWORK)])
  subProbeLines.value = sLR.data; subProbeSummary.value = sSR.data
}

async function openCapability(row) { selectedCapability.value = row; capabilityParameters.value = (await lineCapabilityService.getParameterStates(row.lineId)).data; capabilityDrawerVisible.value = true }
async function redetectLine(row) { await lineDetectionService.detect(row.lineId); await loadData(); await loadProbeData(); await loadProvincialData(); const u = capabilityRows.value.find(i => i.lineId === row.lineId); if (u) await openCapability(u); ElMessage.success('Mock线路能力已重新判定') }
function openRuleEditor(rule = null) { const n = rule ? createTrafficRule(rule) : createTrafficRule({ enabled: true, ipVersion: 'dual', sourceLan: '任意局域网', protocol: '任意', businessType: '普通上网', targetPoolId: 'pool_default_dual', schedulingMode: 'network_optimization', fallbackPoolId: 'pool_default_dual', effectiveTime: '全天' }); for (const k of Object.keys(editingRule)) delete editingRule[k]; Object.assign(editingRule, n); ruleEditorVisible.value = true }
async function saveRule() { if (!editingRule.name.trim()) { ElMessage.warning('请输入规则名称'); return }; if (editingRule.id) await trafficRuleService.update(editingRule.id, editingRule); else await trafficRuleService.create(editingRule); ruleEditorVisible.value = false; await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('Mock业务分流规则已保存') }
async function toggleRule(row, enabled) { await trafficRuleService.toggle(row.id, enabled); await loadData(); await loadProbeData(); await loadProvincialData() }
async function copyRule(row) { await trafficRuleService.copy(row.id); await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('规则已复制') }
async function removeRule(row) { if (row.immutable) return; await ElMessageBox.confirm(`确定删除"${row.name}"吗？`, '删除规则', { type: 'warning' }); await trafficRuleService.remove(row.id); await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('Mock规则已删除') }
async function createFromTemplate(id) { await trafficRuleService.createFromTemplate(id); await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('已从模板创建Mock规则') }
function startRuleDrag(row) { draggedRuleId.value = row.id }
async function dropRule(target) { if (!draggedRuleId.value || target.immutable || draggedRuleId.value === target.id) return; const o = trafficRules.value.filter(i => !i.immutable).map(i => i.id); const f = o.indexOf(draggedRuleId.value); const t = o.indexOf(target.id); if (f < 0 || t < 0) return; const [m] = o.splice(f, 1); o.splice(t, 0, m); await trafficRuleService.reorder(o); draggedRuleId.value = ''; await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('优先级已调整') }
async function runSimulation() { simulationResult.value = (await schedulingSimulationService.simulate(simulationInput)).data }
async function saveSettings() { await adaptiveSchedulingService.updateSimulationSettings(settings); await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('演示调度参数已保存') }
async function resetSettings() { await adaptiveSchedulingService.resetSimulationSettings(); await loadData(); await loadProbeData(); await loadProvincialData(); ElMessage.success('已恢复默认调度参数') }

onMounted(async () => { await loadData(); await loadProbeData(); await loadProvincialData() })
</script>

<style scoped>
.page-section-frame > :deep(.el-card__body) > .card-content > .card-content__inner > .el-alert { margin-bottom: var(--layout-section-gap); }
.scheduling-tabs { min-width: 0; }
.scheduling-tabs :deep(.el-tabs__header) { padding: 0 var(--layout-card-padding-x); background: var(--el-bg-color); }
.scheduling-tabs :deep(.el-tabs__content) { min-width: 0; }
.scheduling-tabs :deep(.el-tab-pane) { min-width: 0; }
:deep(.header-help) { display: inline-flex; align-items: center; gap: 6px; }
:deep(.header-help .el-icon) { color: var(--lh-primary); cursor: help; }
.process-grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 10px; }
.process-item { display: flex; min-height: 70px; align-items: flex-start; gap: 9px; padding: 12px; border-radius: 6px; background: var(--el-fill-color-lighter); }
.process-item span { display: grid; width: 22px; height: 22px; flex-shrink: 0; place-items: center; border-radius: 50%; background: var(--lh-primary); color: white; font-size: 12px; }
.process-item p, .boundary-grid p, .drawer-title p, .drawer-help { margin: 0; color: var(--lh-text-secondary); font-size: 13px; line-height: 21px; }
.summary-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
.summary-item { display: flex; min-height: 112px; flex-direction: column; gap: 5px; padding: 14px; border: 1px solid var(--el-border-color-lighter); border-radius: 6px; }
.summary-item span, .summary-item small { color: var(--lh-text-secondary); font-size: 12px; line-height: 18px; }
.summary-item strong { color: var(--lh-primary); font-size: 24px; }
.boundary-grid { display: grid; grid-template-columns: 1fr auto 1fr auto 1fr; align-items: center; gap: 14px; }
.boundary-grid > div { min-height: 92px; padding: 15px; border-radius: 6px; background: var(--el-fill-color-lighter); }
.boundary-grid > .el-icon { color: var(--lh-primary); }
.card-header-actions { display: flex; width: 100%; align-items: center; justify-content: space-between; gap: 12px; }
.template-grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 10px; margin-bottom: 14px; }
.template-card { display: flex; min-width: 0; min-height: 130px; flex-direction: column; gap: 6px; padding: 12px; border: 1px solid var(--el-border-color); border-radius: 6px; background: var(--el-bg-color); color: var(--lh-text); text-align: left; cursor: pointer; }
.template-card:hover { border-color: var(--lh-primary); }
.template-card span { font-weight: 600; }
.template-card small { flex: 1; color: var(--lh-text-secondary); line-height: 18px; }
.template-card em { color: var(--lh-primary); font-size: 12px; font-style: normal; }
.rule-table { --standard-table-scroll-width: 1720px; }
.drag-handle { display: inline-flex; padding: 4px 8px; border-radius: 4px; color: var(--lh-text-secondary); cursor: grab; font-weight: 700; letter-spacing: -2px; }
.drag-handle:hover { background: var(--el-fill-color); color: var(--lh-primary); }
.table-hint, .form-hint { color: var(--lh-text-secondary); font-size: 12px; }
.table-hint { margin: 10px 0 0; }
.drawer-title { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 16px; }
.drawer-title h3 { margin: 0 0 5px; }
.capability-descriptions { margin-bottom: 18px; }
.drawer-section-title { display: flex; align-items: center; gap: 6px; margin: 20px 0 10px; }
.drawer-section-title .el-icon { color: var(--lh-primary); cursor: help; }
.simulation-result { margin-top: 18px; }
.goal-options { display: grid; width: 100%; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
.goal-options :deep(.el-radio) { width: 100%; height: auto; min-height: 76px; margin: 0; padding: 12px 14px; align-items: flex-start; white-space: normal; }
.goal-options :deep(.el-radio__label) { display: flex; min-width: 0; flex-direction: column; gap: 5px; white-space: normal; }
.goal-title { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; }
.goal-option small { color: var(--lh-text-secondary); font-size: 12px; }
.form-hint { width: 100%; margin-top: 4px; }
.settings-actions { display: flex; justify-content: flex-end; gap: 8px; }
.score-weight-list { display: flex; flex-direction: column; gap: 12px; }
.score-weight-item { display: flex; align-items: flex-start; justify-content: space-between; gap: 14px; padding-bottom: 10px; border-bottom: 1px solid var(--el-border-color-lighter); }
.score-weight-item > div { display: flex; flex-direction: column; gap: 4px; }
.score-weight-item b { color: var(--lh-primary); }
.source-list { display: flex; flex-direction: column; gap: 12px; margin-top: 14px; }
.source-list > div { display: flex; flex-direction: column; gap: 3px; }
.capability-table { --standard-table-scroll-width: 1280px; }
.capability-table small, .rule-table small { display: block; margin-top: 4px; }
.rule-conflict-alert { margin-bottom: 12px; }
.rule-name { display: flex; align-items: center; gap: 6px; }
.conflict-icon { color: #e6a23c; cursor: help; }
@media (max-width: 1199px) { .process-grid, .template-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 767px) { .process-grid, .summary-grid, .template-grid, .goal-options, .boundary-grid { grid-template-columns: 1fr; } .boundary-grid > .el-icon { transform: rotate(90deg); justify-self: center; } .card-header-actions { align-items: flex-start; flex-direction: column; } }
</style>
