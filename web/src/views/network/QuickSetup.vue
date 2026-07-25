<template>
  <PageContainer>
    <PageHeader
      title="快速上网"
      description="自动识别网口和接入方式，支持宽带拨号、DHCP 自动获取与静态 IP"
    >
      <template #actions>
        <el-button size="small" :loading="detecting" @click="runSmartDetection">
          重新智能检测
        </el-button>
        <el-tag type="warning" effect="dark">演示数据</el-tag>
      </template>
    </PageHeader>

    <SectionCard
      class="page-section-frame"
      shadow="never"
      content-padding="none"
      v-loading="loading"
    >
      <el-alert
        class="demo-alert"
        type="warning"
        show-icon
        :closable="false"
        title="本向导只生成前端演示摘要，不会写入 UCI，也不会修改拨号、VLAN、LAN、IPv6 或负载均衡配置。"
      />

      <SectionCard shadow="never" class="wizard-card">
        <el-steps :active="currentStep" align-center finish-status="success">
          <el-step title="智能识别" description="自动发现宽带与服务器网口" />
          <el-step title="上网方式" description="拨号、自动获取或固定地址" />
          <el-step title="服务器出口" description="选择连接服务器的网口" />
          <el-step title="汇聚模式" description="选择线路使用方式" />
        </el-steps>

        <el-divider />

        <div class="wizard-content">
          <section v-show="currentStep === 0" class="wizard-stage">
            <div class="stage-heading">
              <span class="stage-number">1</span>
              <div>
                <h3>智能识别网络连接</h3>
                <p>系统会根据链路状态、速率和服务响应推荐宽带入口与服务器出口，也可以手动调整。</p>
              </div>
            </div>

            <div class="auto-detect-panel">
              <div class="detect-status">
                <span class="detect-icon"><el-icon><MagicStick /></el-icon></span>
                <div>
                  <strong>{{ detecting ? '正在识别网络连接…' : '智能检测已完成' }}</strong>
                  <p v-if="detection">
                    推荐使用 {{ detection.uplinkPort }} 接入宽带、{{ detection.lanPort }} 连接服务器，
                    推荐上网方式为 {{ recommendedAccessModeName }}。
                  </p>
                </div>
              </div>
              <div v-if="detection" class="confidence">
                <span>推荐可信度</span>
                <strong>{{ detection.confidence }}%</strong>
              </div>
            </div>

            <div v-if="detection" class="detection-grid">
              <div v-for="finding in detection.findings" :key="finding.label" class="detection-item">
                <div class="detection-label">
                  <el-icon><CircleCheck /></el-icon>
                  <span>{{ finding.label }}</span>
                </div>
                <strong>{{ finding.value }}</strong>
                <p>{{ finding.detail }}</p>
              </div>
            </div>

            <div class="selection-heading">宽带入口网口</div>
            <el-radio-group v-model="form.broadbandPort" class="option-grid">
              <el-radio
                v-for="port in ports"
                :key="port.id"
                :value="port.id"
                :disabled="port.status !== '已连接'"
                border
                class="option-radio"
                :class="{ 'is-selected-card': form.broadbandPort === port.id }"
              >
                <div class="port-card">
                  <div class="option-title-row">
                    <strong>{{ port.label }}</strong>
                    <div class="option-tags">
                      <el-tag v-if="detection?.uplinkPort === port.id" type="primary" size="small">智能推荐</el-tag>
                      <el-tag :type="port.status === '已连接' ? 'success' : 'info'" size="small">
                        {{ port.status }}
                      </el-tag>
                    </div>
                  </div>
                  <div class="port-name">{{ port.name }} · {{ port.speed }}</div>
                  <div class="option-description">{{ port.hint }}</div>
                </div>
              </el-radio>
            </el-radio-group>
          </section>

          <section v-show="currentStep === 1" class="wizard-stage">
            <div class="stage-heading">
              <span class="stage-number">2</span>
              <div>
                <h3>选择上网方式</h3>
                <p>系统已根据检测结果给出推荐，也可以根据运营商提供的信息手动选择。</p>
              </div>
            </div>

            <el-radio-group v-model="form.accessMode" class="mode-grid access-mode-grid">
              <el-radio
                v-for="mode in accessModes"
                :key="mode.id"
                :value="mode.id"
                border
                class="option-radio mode-radio access-mode-radio"
                :class="{ 'is-selected-card': form.accessMode === mode.id }"
              >
                <div class="mode-card">
                  <div class="option-title-row">
                    <div>
                      <strong>{{ mode.name }}</strong>
                      <span class="mode-short-name">{{ mode.shortName }}</span>
                    </div>
                    <el-tag
                      v-if="detection?.recommendedMode === mode.id"
                      type="success"
                      size="small"
                    >
                      智能推荐
                    </el-tag>
                  </div>
                  <div class="option-description">{{ mode.description }}</div>
                </div>
              </el-radio>
            </el-radio-group>

            <div v-if="form.accessMode === 'pppoe'" class="access-configuration">
              <div class="table-toolbar">
                <div>
                  <strong>宽带账号</strong>
                  <span class="toolbar-hint">当前 {{ form.accounts.length }} 条，可批量添加</span>
                </div>
                <div class="toolbar-actions">
                  <el-button size="small" @click="restoreDemoAccounts">恢复演示账号</el-button>
                  <el-button type="primary" size="small" @click="addAccount">添加一条宽带</el-button>
                </div>
              </div>

              <StandardTable
                layout-mode="scroll"
                :data="form.accounts"
                border
                stripe
                size="default"
                class="account-table"
              >
                <el-table-column type="index" label="#" width="56" fixed="left" />
                <el-table-column label="VLAN ID（0=无VLAN）" min-width="170">
                  <template #default="{ row }">
                    <el-input-number
                      v-model="row.vlanId"
                      :min="0"
                      :max="4094"
                      controls-position="right"
                      size="small"
                    />
                  </template>
                </el-table-column>
                <el-table-column label="PPPoE账号" min-width="190">
                  <template #default="{ row }">
                    <el-input v-model="row.account" size="small" placeholder="请输入宽带账号" />
                  </template>
                </el-table-column>
                <el-table-column label="密码" min-width="180">
                  <template #default="{ row }">
                    <el-input
                      v-model="row.password"
                      type="password"
                      show-password
                      size="small"
                      placeholder="请输入密码"
                    />
                  </template>
                </el-table-column>
                <el-table-column label="备注" min-width="150">
                  <template #default="{ row }">
                    <el-input v-model="row.remark" size="small" placeholder="选填" />
                  </template>
                </el-table-column>
                <el-table-column label="IPv4" width="88" align="center">
                  <template #default="{ row }">
                    <el-switch v-model="row.ipv4" />
                  </template>
                </el-table-column>
                <el-table-column label="IPv6" width="88" align="center">
                  <template #default="{ row }">
                    <el-switch v-model="row.ipv6" />
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="88" align="center" fixed="right">
                  <template #default="{ row }">
                    <el-button
                      type="danger"
                      link
                      :disabled="form.accounts.length === 1"
                      @click="removeAccount(row.id)"
                    >
                      删除
                    </el-button>
                  </template>
                </el-table-column>
              </StandardTable>
            </div>

            <div v-else-if="form.accessMode === 'dhcp'" class="access-configuration access-form-card">
              <div class="configuration-title">
                <div>
                  <strong>自动获取地址设置</strong>
                  <p>大多数家庭光猫、园区网络和上级路由器使用此方式，通常无需额外填写。</p>
                </div>
                <el-tag type="success">即插即用</el-tag>
              </div>
              <el-form :model="form.dhcp" label-position="top" class="access-form">
                <el-row :gutter="16">
                  <el-col :xs="24" :md="8">
                    <el-form-item label="VLAN ID（0 表示无 VLAN）">
                      <el-input-number
                        v-model="form.dhcp.vlanId"
                        :min="0"
                        :max="4094"
                        controls-position="right"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="8">
                    <el-form-item label="设备名称">
                      <el-input v-model="form.dhcp.hostname" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="8">
                    <el-form-item label="网络协议">
                      <div class="switch-row">
                        <span>IPv4</span><el-switch v-model="form.dhcp.ipv4" />
                        <span>IPv6</span><el-switch v-model="form.dhcp.ipv6" />
                      </div>
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="8">
                    <el-form-item label="DNS 设置">
                      <el-radio-group v-model="form.dhcp.dnsMode">
                        <el-radio-button value="auto">自动获取</el-radio-button>
                        <el-radio-button value="manual">手动指定</el-radio-button>
                      </el-radio-group>
                    </el-form-item>
                  </el-col>
                  <template v-if="form.dhcp.dnsMode === 'manual'">
                    <el-col :xs="24" :md="8">
                      <el-form-item label="首选 DNS">
                        <el-input v-model="form.dhcp.primaryDns" />
                      </el-form-item>
                    </el-col>
                    <el-col :xs="24" :md="8">
                      <el-form-item label="备用 DNS">
                        <el-input v-model="form.dhcp.secondaryDns" />
                      </el-form-item>
                    </el-col>
                  </template>
                </el-row>
              </el-form>
            </div>

            <div v-else class="access-configuration access-form-card">
              <div class="configuration-title">
                <div>
                  <strong>固定地址设置</strong>
                  <p>请填写运营商或机房提供的地址、前缀长度、网关和 DNS。</p>
                </div>
                <el-tag type="info">专线场景</el-tag>
              </div>
              <el-form :model="form.staticIp" label-position="top" class="access-form">
                <el-row :gutter="16">
                  <el-col :xs="24" :md="6">
                    <el-form-item label="VLAN ID（0 表示无 VLAN）">
                      <el-input-number
                        v-model="form.staticIp.vlanId"
                        :min="0"
                        :max="4094"
                        controls-position="right"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="IPv4 地址">
                      <el-input v-model="form.staticIp.ipv4Address" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="IPv4 前缀长度">
                      <el-input-number v-model="form.staticIp.ipv4PrefixLength" :min="1" :max="32" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="IPv4 网关">
                      <el-input v-model="form.staticIp.ipv4Gateway" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="首选 DNS">
                      <el-input v-model="form.staticIp.primaryDns" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="备用 DNS">
                      <el-input v-model="form.staticIp.secondaryDns" />
                    </el-form-item>
                  </el-col>
                  <el-col :xs="24" :md="6">
                    <el-form-item label="启用 IPv6">
                      <el-switch v-model="form.staticIp.ipv6" />
                    </el-form-item>
                  </el-col>
                  <template v-if="form.staticIp.ipv6">
                    <el-col :xs="24" :md="6">
                      <el-form-item label="IPv6 地址">
                        <el-input v-model="form.staticIp.ipv6Address" />
                      </el-form-item>
                    </el-col>
                    <el-col :xs="24" :md="6">
                      <el-form-item label="IPv6 前缀长度">
                        <el-input-number v-model="form.staticIp.ipv6PrefixLength" :min="1" :max="128" />
                      </el-form-item>
                    </el-col>
                    <el-col :xs="24" :md="6">
                      <el-form-item label="IPv6 网关">
                        <el-input v-model="form.staticIp.ipv6Gateway" />
                      </el-form-item>
                    </el-col>
                  </template>
                </el-row>
              </el-form>
            </div>
          </section>

          <section v-show="currentStep === 2" class="wizard-stage">
            <div class="stage-heading">
              <span class="stage-number">3</span>
              <div>
                <h3>选择服务器 LAN 出口</h3>
                <p>请选择连接服务器、核心交换机或内部网络的网口。</p>
              </div>
            </div>

            <el-radio-group v-model="form.lanPort" class="option-grid">
              <el-radio
                v-for="port in availableLanPorts"
                :key="port.id"
                :value="port.id"
                :disabled="port.status !== '已连接'"
                border
                class="option-radio"
                :class="{ 'is-selected-card': form.lanPort === port.id }"
              >
                <div class="port-card">
                  <div class="option-title-row">
                    <strong>{{ port.label }}</strong>
                    <div class="option-tags">
                      <el-tag v-if="detection?.lanPort === port.id" type="primary" size="small">智能推荐</el-tag>
                      <el-tag :type="port.status === '已连接' ? 'success' : 'info'" size="small">
                        {{ port.status }}
                      </el-tag>
                    </div>
                  </div>
                  <div class="port-name">{{ port.name }} · {{ port.speed }}</div>
                  <div class="option-description">{{ port.hint }}</div>
                </div>
              </el-radio>
            </el-radio-group>
          </section>

          <section v-show="currentStep === 3" class="wizard-stage">
            <div class="stage-heading">
              <span class="stage-number">4</span>
              <div>
                <h3>选择汇聚模式</h3>
                <p>无需理解线路权重或调度策略，选择最符合使用场景的方式即可。</p>
              </div>
            </div>

            <el-radio-group v-model="form.aggregationMode" class="mode-grid">
              <el-radio
                v-for="mode in aggregationModes"
                :key="mode.id"
                :value="mode.id"
                border
                class="option-radio mode-radio"
                :class="{ 'is-selected-card': form.aggregationMode === mode.id }"
              >
                <div class="mode-card">
                  <div class="option-title-row">
                    <strong>{{ mode.name }}</strong>
                    <el-tag v-if="mode.recommended" type="success" size="small">推荐</el-tag>
                  </div>
                  <div class="option-description">{{ mode.description }}</div>
                </div>
              </el-radio>
            </el-radio-group>

            <el-alert
              v-if="connectionCount === 1"
              class="single-line-alert"
              type="info"
              show-icon
              :closable="false"
              title="当前只有一条上网连接，暂不执行多线路分流；系统会先启用健康检测，新增线路后自动启用所选汇聚模式。"
            />

            <div class="smart-policy-panel">
              <div class="configuration-title">
                <div>
                  <strong>智能自动化策略</strong>
                  <p>根据当前接入方式和线路数量自动生成，无需理解权重、健康检测或策略对象。</p>
                </div>
                <el-button type="primary" plain size="small" @click="applySmartRecommendation">
                  使用智能推荐
                </el-button>
              </div>
              <div class="automation-grid">
                <div v-for="item in automationFeatures" :key="item.title" class="automation-item">
                  <el-icon><CircleCheckFilled /></el-icon>
                  <div>
                    <strong>{{ item.title }}</strong>
                    <p>{{ item.description }}</p>
                  </div>
                </div>
              </div>
            </div>

            <div class="configuration-summary">
              <div class="summary-heading">
                <div>
                  <h3>配置摘要</h3>
                  <p>系统将按下面的方式准备网络。此处仍然只是演示预览。</p>
                </div>
                <el-tag type="warning">不会应用到系统</el-tag>
              </div>
              <div class="summary-list">
                <div v-for="line in summaryLines" :key="line" class="summary-line">
                  <el-icon><CircleCheckFilled /></el-icon>
                  <span>{{ line }}</span>
                </div>
              </div>
            </div>
          </section>
        </div>

        <div class="wizard-footer">
          <el-button :disabled="currentStep === 0" @click="currentStep--">上一步</el-button>
          <div class="footer-note">第 {{ currentStep + 1 }} 步，共 4 步</div>
          <el-button v-if="currentStep < 3" type="primary" @click="goNext">
            下一步
          </el-button>
          <el-button v-else type="primary" :loading="saving" @click="completeDemo">
            完成演示配置
          </el-button>
        </div>
      </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { quickSetupService } from '../../services/quickSetupService.js'

const loading = ref(true)
const saving = ref(false)
const detecting = ref(false)
const currentStep = ref(0)
const ports = ref([])
const accessModes = ref([])
const aggregationModes = ref([])
const demoAccounts = ref([])
const detection = ref(null)
const nextAccountId = ref(7)

const form = reactive({
  broadbandPort: '',
  accessMode: '',
  accounts: [],
  dhcp: {},
  staticIp: {},
  lanPort: '',
  aggregationMode: '',
})

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

onMounted(async () => {
  const response = await quickSetupService.getWizardData()
  ports.value = response.data.ports
  accessModes.value = response.data.accessModes
  aggregationModes.value = response.data.aggregationModes
  demoAccounts.value = response.data.accounts
  form.broadbandPort = response.data.defaults.broadbandPort
  form.accessMode = response.data.defaults.accessMode
  form.lanPort = response.data.defaults.lanPort
  form.aggregationMode = response.data.defaults.aggregationMode
  form.accounts = clone(response.data.accounts)
  form.dhcp = clone(response.data.dhcp)
  form.staticIp = clone(response.data.staticIp)
  await runSmartDetection(false)
  loading.value = false
})

const availableLanPorts = computed(() => (
  ports.value.filter((port) => port.id !== form.broadbandPort)
))

const selectedMode = computed(() => (
  aggregationModes.value.find((mode) => mode.id === form.aggregationMode)
))

const connectionCount = computed(() => (
  form.accessMode === 'pppoe' ? form.accounts.length : 1
))

const recommendedAccessModeName = computed(() => (
  accessModes.value.find((mode) => mode.id === detection.value?.recommendedMode)?.shortName || '自动判断'
))

const automationFeatures = computed(() => {
  const ipv6Enabled = form.accessMode === 'pppoe'
    ? form.accounts.filter((account) => account.ipv6).length
    : form.accessMode === 'dhcp'
      ? Number(form.dhcp.ipv6)
      : Number(form.staticIp.ipv6)
  const total = connectionCount.value

  return [
    {
      title: '自动健康检测',
      description: '持续观察连通性、延迟和丢包，异常线路自动降低优先级。',
    },
    {
      title: '智能 DNS',
      description: form.accessMode === 'dhcp' && form.dhcp.dnsMode === 'auto'
        ? '跟随上级网络自动获取 DNS，并在异常时提示切换。'
        : '检查已填写的 DNS 可用性并推荐更稳定的服务器。',
    },
    {
      title: '双栈自动配置',
      description: ipv6Enabled === total
        ? `全部 ${total} 条连接同时启用 IPv4 与 IPv6，并分别检查可用性。`
        : ipv6Enabled > 0
          ? `${ipv6Enabled}/${total} 条连接启用 IPv6，系统会分别检查双栈可用性。`
        : '当前仅启用 IPv4，后续检测到 IPv6 时会给出开启建议。',
    },
    {
      title: '平滑线路调度',
      description: total > 1
        ? '只为新连接选择线路，已建立连接保持原出口，避免频繁切换。'
        : '当前为单线路，仅启用健康检测；新增线路后自动开始平滑调度。',
    },
  ]
})

function formatVlan(value) {
  return Number(value) === 0 ? '无 VLAN（VLAN ID 0）' : `VLAN ${value}`
}

const summaryLines = computed(() => {
  const broadbandPort = form.broadbandPort || '未选择网口'
  const lanPort = form.lanPort || '未选择网口'
  const aggregation = selectedMode.value?.name || '未选择的汇聚方式'

  if (form.accessMode === 'dhcp') {
    const protocols = [
      form.dhcp.ipv4 ? 'IPv4' : '',
      form.dhcp.ipv6 ? 'IPv6' : '',
    ].filter(Boolean).join(' 和 ')
    return [
      `将使用${broadbandPort}通过 DHCP 自动获取 ${protocols || '网络'} 地址`,
      `宽带入口使用${formatVlan(form.dhcp.vlanId)}`,
      `将使用${lanPort}连接服务器`,
      form.dhcp.dnsMode === 'auto'
        ? '将自动获取 DNS，并启用健康检测'
        : `将使用指定 DNS ${form.dhcp.primaryDns}，并启用健康检测`,
      `新增线路后将自动启用${aggregation}`,
    ]
  }

  if (form.accessMode === 'static') {
    return [
      `将使用${broadbandPort}的固定地址${form.staticIp.ipv4Address}/${form.staticIp.ipv4PrefixLength}接入互联网`,
      `宽带入口使用${formatVlan(form.staticIp.vlanId)}`,
      `将使用${lanPort}连接服务器`,
      `将使用网关 ${form.staticIp.ipv4Gateway} 和 DNS ${form.staticIp.primaryDns}`,
      form.staticIp.ipv6
        ? `将同时启用 IPv6；新增线路后自动启用${aggregation}`
        : `新增线路后将自动启用${aggregation}`,
    ]
  }

  const total = form.accounts.length
  const vlanValues = [...new Set(form.accounts.map((account) => Number(account.vlanId)))]
  const vlanDescription = vlanValues.length === 1
    ? formatVlan(vlanValues[0])
    : `多个 VLAN（${vlanValues.join('、')}）`
  const ipv4Count = form.accounts.filter((account) => account.ipv4).length
  const ipv6Count = form.accounts.filter((account) => account.ipv6).length
  const protocolSummary = ipv4Count === total && ipv6Count === total
    ? `将创建${total}条IPv4和IPv6拨号线路`
    : `将创建${ipv4Count}条IPv4拨号线路和${ipv6Count}条IPv6拨号线路`
  return [
    `将使用${broadbandPort}以${vlanDescription}方式接入${total}条宽带`,
    `将使用${lanPort}连接服务器`,
    protocolSummary,
    `将启用${aggregation}`,
  ]
})

watch(() => form.broadbandPort, () => {
  if (form.lanPort === form.broadbandPort) {
    form.lanPort = availableLanPorts.value.find((port) => port.status === '已连接')?.id
      || availableLanPorts.value[0]?.id
      || ''
  }
})

async function runSmartDetection(showMessage = true) {
  detecting.value = true
  const response = await quickSetupService.detectNetwork()
  detection.value = response.data
  form.broadbandPort = response.data.uplinkPort
  form.lanPort = response.data.lanPort
  form.accessMode = response.data.recommendedMode
  detecting.value = false
  if (showMessage) {
    ElMessage.success(`已识别 ${response.data.uplinkPort} 为宽带入口，并推荐 ${recommendedAccessModeName.value}`)
  }
}

function addAccount() {
  const id = nextAccountId.value++
  form.accounts.push({
    id,
    vlanId: 0,
    account: '',
    password: '',
    remark: `宽带 ${id}`,
    ipv4: true,
    ipv6: true,
  })
}

function removeAccount(id) {
  form.accounts = form.accounts.filter((account) => account.id !== id)
}

function restoreDemoAccounts() {
  form.accounts = clone(demoAccounts.value)
  nextAccountId.value = Math.max(...form.accounts.map((account) => account.id)) + 1
  ElMessage.success('已恢复 6 条演示宽带账号')
}

function isValidVlan(value) {
  return Number.isInteger(value) && value >= 0 && value <= 4094
}

function isValidIpv4(value) {
  const parts = String(value || '').trim().split('.')
  return parts.length === 4 && parts.every((part) => (
    /^\d{1,3}$/.test(part) && Number(part) >= 0 && Number(part) <= 255
  ))
}

function isValidIpv6(value) {
  const text = String(value || '').trim()
  return text.includes(':') && /^[0-9a-fA-F:]+$/.test(text)
}

function validateCurrentStep() {
  if (currentStep.value === 0 && !form.broadbandPort) {
    ElMessage.warning('请选择宽带入口网口')
    return false
  }

  if (currentStep.value === 1) {
    if (!form.accessMode) {
      ElMessage.warning('请选择上网方式')
      return false
    }
    if (form.accessMode === 'pppoe') {
      if (!form.accounts.length) {
        ElMessage.warning('请至少添加一条宽带账号')
        return false
      }
      const invalid = form.accounts.some((account) => (
        !isValidVlan(account.vlanId)
        || !String(account.account || '').trim()
        || !String(account.password || '').trim()
      ))
      if (invalid) {
        ElMessage.warning('请填写有效的 VLAN ID（0–4094）、账号和密码')
        return false
      }
      if (form.accounts.some((account) => !account.ipv4 && !account.ipv6)) {
        ElMessage.warning('每条宽带至少需要启用 IPv4 或 IPv6')
        return false
      }
    }
    if (form.accessMode === 'dhcp') {
      if (!isValidVlan(form.dhcp.vlanId)) {
        ElMessage.warning('DHCP 的 VLAN ID 必须在 0–4094 之间')
        return false
      }
      if (!form.dhcp.ipv4 && !form.dhcp.ipv6) {
        ElMessage.warning('IPv4 和 IPv6 至少需要启用一种')
        return false
      }
      if (form.dhcp.dnsMode === 'manual' && (
        !isValidIpv4(form.dhcp.primaryDns)
        || (form.dhcp.secondaryDns && !isValidIpv4(form.dhcp.secondaryDns))
      )) {
        ElMessage.warning('请输入有效的首选 DNS 和备用 DNS 地址')
        return false
      }
    }
    if (form.accessMode === 'static') {
      if (!isValidVlan(form.staticIp.vlanId)) {
        ElMessage.warning('静态 IP 的 VLAN ID 必须在 0–4094 之间')
        return false
      }
      if (
        !isValidIpv4(form.staticIp.ipv4Address)
        || !isValidIpv4(form.staticIp.ipv4Gateway)
        || !isValidIpv4(form.staticIp.primaryDns)
        || (form.staticIp.secondaryDns && !isValidIpv4(form.staticIp.secondaryDns))
      ) {
        ElMessage.warning('请输入有效的固定 IPv4 地址、网关和 DNS')
        return false
      }
      if (form.staticIp.ipv6 && (
        !isValidIpv6(form.staticIp.ipv6Address)
        || !isValidIpv6(form.staticIp.ipv6Gateway)
      )) {
        ElMessage.warning('请输入有效的 IPv6 地址和 IPv6 网关')
        return false
      }
    }
  }

  if (currentStep.value === 2 && !form.lanPort) {
    ElMessage.warning('请选择服务器 LAN 出口')
    return false
  }

  return true
}

function goNext() {
  if (!validateCurrentStep()) return
  currentStep.value += 1
}

function applySmartRecommendation() {
  form.aggregationMode = 'smart'
  if (form.accessMode === 'dhcp') {
    form.dhcp.dnsMode = 'auto'
    form.dhcp.ipv4 = true
    form.dhcp.ipv6 = true
  }
  ElMessage.success(connectionCount.value > 1
    ? '已采用智能汇聚、自动健康检测和双栈优先建议'
    : '已启用自动健康检测；新增线路后智能汇聚将自动生效')
}

async function completeDemo() {
  if (!form.aggregationMode) {
    ElMessage.warning('请选择汇聚模式')
    return
  }
  saving.value = true
  await quickSetupService.saveDemoDraft({
    broadbandPort: form.broadbandPort,
    accessMode: form.accessMode,
    accounts: form.accounts,
    dhcp: form.dhcp,
    staticIp: form.staticIp,
    lanPort: form.lanPort,
    aggregationMode: form.aggregationMode,
  })
  saving.value = false
  ElMessage.success('演示配置已生成，没有写入 UCI 或任何真实网络设置')
}
</script>

<style scoped>
.demo-alert {
  margin-bottom: var(--layout-section-gap);
}

.wizard-card {
  margin-bottom: 0;
}

.wizard-content {
  width: 100%;
  min-width: 0;
  min-height: 520px;
}

.wizard-stage {
  width: 100%;
  min-width: 0;
}

.stage-heading {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 24px;
}

.stage-number {
  width: 32px;
  height: 32px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: 50%;
  background: var(--lh-primary);
  color: #fff;
  font-weight: 700;
}

.stage-heading h3,
.configuration-summary h3 {
  margin: 2px 0 4px;
  font-size: 18px;
  color: var(--lh-text);
}

.stage-heading p,
.configuration-summary p,
.configuration-title p {
  margin: 0;
  color: var(--lh-text-secondary);
  font-size: 13px;
  line-height: 20px;
}

.auto-detect-panel {
  width: 100%;
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 16px;
  padding: 18px 20px;
  border: 1px solid color-mix(in srgb, var(--lh-primary) 28%, var(--lh-border));
  border-radius: var(--layout-radius);
  background: color-mix(in srgb, var(--lh-primary) 5%, #fff);
}

.detect-status {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}

.detect-status p {
  margin: 4px 0 0;
  color: var(--lh-text-secondary);
  font-size: 13px;
  line-height: 20px;
}

.detect-icon {
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: 50%;
  background: var(--lh-primary);
  color: #fff;
  font-size: 20px;
}

.confidence {
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-shrink: 0;
  color: var(--lh-text-secondary);
}

.confidence strong {
  color: var(--lh-primary);
  font-size: 22px;
}

.detection-grid,
.automation-grid {
  width: 100%;
  min-width: 0;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.detection-grid {
  margin-bottom: 24px;
}

.detection-item,
.automation-item {
  min-width: 0;
  padding: 14px;
  border: 1px solid var(--lh-border);
  border-radius: var(--layout-radius);
  background: #fff;
}

.detection-label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  color: var(--lh-text-secondary);
  font-size: 12px;
}

.detection-label .el-icon,
.automation-item > .el-icon {
  color: var(--el-color-success);
}

.detection-item > strong {
  color: var(--lh-text);
  font-size: 15px;
}

.detection-item p,
.automation-item p {
  margin: 6px 0 0;
  color: var(--lh-text-secondary);
  font-size: 12px;
  line-height: 18px;
}

.selection-heading {
  margin-bottom: 12px;
  color: var(--lh-text);
  font-weight: 600;
}

.option-grid,
.mode-grid {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.mode-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.access-mode-grid {
  margin-bottom: 24px;
}

.option-radio {
  width: 100%;
  height: auto;
  min-height: 132px;
  margin: 0;
  padding: 18px;
  align-items: flex-start;
  box-sizing: border-box;
  white-space: normal;
}

.mode-radio {
  min-height: 122px;
}

.access-mode-radio {
  min-height: 142px;
}

.option-radio.is-selected-card {
  border-color: var(--lh-primary);
  background: color-mix(in srgb, var(--lh-primary) 6%, #fff);
  box-shadow: 0 0 0 1px color-mix(in srgb, var(--lh-primary) 18%, transparent);
}

.option-radio :deep(.el-radio__input) {
  margin-top: 4px;
}

.option-radio :deep(.el-radio__label) {
  width: 100%;
  min-width: 0;
  padding-left: 12px;
  white-space: normal;
}

.port-card,
.mode-card {
  width: 100%;
  min-width: 0;
}

.option-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 10px;
  color: var(--lh-text);
}

.option-tags {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
}

.mode-short-name {
  margin-left: 8px;
  color: var(--lh-text-secondary);
  font-size: 12px;
  font-weight: 400;
}

.port-name {
  margin-bottom: 8px;
  color: var(--lh-primary);
  font-size: 14px;
  font-weight: 600;
}

.option-description {
  color: var(--lh-text-secondary);
  font-size: 13px;
  line-height: 20px;
}

.table-toolbar {
  width: 100%;
  min-width: 0;
  min-height: 48px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 12px;
}

.toolbar-hint {
  margin-left: 8px;
  color: var(--lh-text-secondary);
  font-size: 13px;
}

.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.account-table {
  --standard-table-scroll-width: 1120px;
}

.account-table :deep(.el-input-number) {
  width: 100%;
}

.access-configuration {
  width: 100%;
  min-width: 0;
}

.access-form-card,
.smart-policy-panel {
  padding: 20px 22px;
  border: 1px solid var(--lh-border);
  border-radius: var(--layout-radius);
  background: var(--el-fill-color-lighter);
}

.configuration-title {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 18px;
}

.configuration-title strong {
  display: block;
  margin-bottom: 4px;
  color: var(--lh-text);
  font-size: 15px;
}

.access-form :deep(.el-input-number) {
  width: 100%;
}

.switch-row {
  width: 100%;
  min-height: 32px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.smart-policy-panel {
  width: 100%;
  min-width: 0;
  margin-top: 24px;
  box-sizing: border-box;
}

.single-line-alert {
  margin-top: 16px;
}

.automation-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px;
}

.automation-item > .el-icon {
  flex-shrink: 0;
  margin-top: 2px;
  font-size: 17px;
}

.automation-item strong {
  color: var(--lh-text);
  font-size: 13px;
}

.configuration-summary {
  width: 100%;
  min-width: 0;
  margin-top: 28px;
  padding: 22px 24px;
  border: 1px solid var(--lh-border);
  border-radius: var(--layout-radius);
  background: var(--el-fill-color-light);
  box-sizing: border-box;
}

.summary-heading {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 18px;
}

.summary-list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.summary-line {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  min-height: 44px;
  padding: 0 14px;
  border: 1px solid var(--lh-border);
  border-radius: 6px;
  background: #fff;
  color: var(--lh-text);
  font-size: 14px;
  box-sizing: border-box;
}

.summary-line .el-icon {
  flex-shrink: 0;
  color: var(--el-color-success);
  font-size: 18px;
}

.wizard-footer {
  width: 100%;
  min-width: 0;
  min-height: 64px;
  display: grid;
  grid-template-columns: 140px minmax(0, 1fr) 140px;
  align-items: center;
  gap: 16px;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--lh-border);
}

.wizard-footer > .el-button {
  width: 100%;
  margin: 0;
}

.footer-note {
  text-align: center;
  color: var(--lh-text-secondary);
  font-size: 13px;
}

@media (max-width: 991px) {
  .mode-grid,
  .summary-list,
  .detection-grid,
  .automation-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 767px) {
  .wizard-content {
    min-height: 460px;
  }

  .table-toolbar,
  .summary-heading,
  .configuration-title,
  .auto-detect-panel {
    align-items: stretch;
    flex-direction: column;
  }

  .toolbar-actions {
    width: 100%;
  }

  .toolbar-actions .el-button {
    flex: 1;
  }

  .wizard-footer {
    grid-template-columns: 1fr 1fr;
  }

  .footer-note {
    grid-column: 1 / -1;
    grid-row: 1;
  }
}
</style>
