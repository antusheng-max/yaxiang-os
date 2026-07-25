<template>
  <main
    class="installer-terminal"
    data-terminal-layout="terminal"
    data-testid="installer-terminal"
    @mousedown="focusPrompt"
  >
    <header class="terminal-header" aria-label="安装器标题">
      <div class="ascii-rule">+------------------------------------------------------------------------------+</div>
      <div class="terminal-title">
        <BrandLogo class="terminal-brand" mode="installer" inverse :symbol-size="38" />
        <span class="terminal-version">{{ BRAND.installerVersion }}　终端预览 / MOCK / DRY RUN</span>
      </div>
      <div class="ascii-rule">+------------------------------------------------------------------------------+</div>
      <div class="safety-line">
        source: {{ safety.source }}　dryRun: {{ safety.dryRun }}　realDiskAccess: {{ safety.realDiskAccess }}
      </div>
    </header>

    <section ref="terminalBody" class="terminal-body" aria-live="polite">
      <template v-if="phase === 'scanning'">
        <TerminalSectionTitle title="启动与硬件扫描" />
        <div class="output-line">{{ BRAND.productName }}安装环境正在启动...</div>
        <div v-for="line in scanLog" :key="line" class="output-line">{{ line }}</div>
        <div class="output-line">
          <span class="block-cursor" aria-hidden="true">_</span>
        </div>
      </template>

      <template v-else-if="phase === 'disk-select'">
        <TerminalSectionTitle title="选择安装硬盘" />
        <p class="paragraph">自动扫描完成。请输入目标硬盘编号，然后按 Enter。</p>
        <p class="warning-line">警告：被选硬盘上的全部数据将在本次 Mock 演示中被模拟清除。</p>

        <div class="disk-list" data-testid="disk-list">
          <button
            v-for="disk in disks"
            :key="disk.id"
            class="text-option disk-option"
            :class="{ protected: !disk.selectable }"
            type="button"
            :data-testid="`disk-option-${disk.displayNumber.toLowerCase()}`"
            @click.stop="selectDiskByClick(disk)"
          >
            {{ disk.displayNumber }}. {{ disk.model }}　{{ disk.devicePath }}　{{ disk.capacity }}　{{ diskStatus(disk) }}
          </button>
        </div>

        <TerminalPrompt
          ref="activeInput"
          v-model="diskInput"
          label="请选择硬盘编号"
          test-id="disk-input"
          maxlength="3"
          @submit="submitDiskSelection"
        />
        <p v-if="promptError" class="error-line" data-testid="prompt-error">{{ promptError }}</p>
      </template>

      <template v-else-if="phase === 'disk-confirm'">
        <TerminalSectionTitle title="确认安装目标" />
        <p class="paragraph">你选择了以下硬盘：</p>
        <div class="detail-lines" data-testid="selected-disk-details">
          <div>型号：{{ selectedDisk.model }}</div>
          <div>路径：{{ selectedDisk.devicePath }}</div>
          <div>容量：{{ selectedDisk.capacity }}</div>
          <div>序列号：{{ selectedDisk.serialNumber }}</div>
          <div>状态：{{ selectedDisk.containsData ? '包含数据' : '空硬盘' }}</div>
        </div>
        <p class="warning-line">这是唯一一次确认。输入 Y 并按 Enter 后将自动开始模拟安装。</p>
        <div class="inline-options">
          <button class="text-option inline-option" type="button" @click.stop="confirmInstallByClick('Y')">[Y] 确认安装</button>
          <button class="text-option inline-option" type="button" @click.stop="confirmInstallByClick('N')">[N] 返回选盘</button>
        </div>
        <TerminalPrompt
          ref="activeInput"
          v-model="confirmInput"
          label="是否继续 (Y/N)"
          test-id="confirm-input"
          maxlength="1"
          @submit="submitInstallConfirmation"
        />
        <p v-if="promptError" class="error-line" data-testid="prompt-error">{{ promptError }}</p>
      </template>

      <template v-else-if="phase === 'installing'">
        <TerminalSectionTitle :title="`正在模拟安装${BRAND.brandName}系统`" />
        <div class="detail-lines">
          <div>目标硬盘：{{ selectedDisk.model }}　{{ selectedDisk.devicePath }}　{{ selectedDisk.capacity }}</div>
          <div>会话标识：{{ installSessionId }}</div>
        </div>
        <div class="progress-block" data-testid="install-progress">
          <div>写入{{ BRAND.brandName }}系统：</div>
          <div class="progress-line">[{{ progressBar }}] {{ installProgress }}%</div>
          <div>当前步骤：{{ currentInstallStage }}</div>
          <div>已用时间：{{ formattedInstallElapsed }}</div>
        </div>
        <div class="install-log">
          <div v-for="line in installLog" :key="line" class="output-line">{{ line }}</div>
        </div>
        <p class="muted-line">所有操作均在浏览器内存中模拟，没有读取或写入真实硬盘。</p>
      </template>

      <template v-else-if="phase === 'console-menu'">
        <TerminalSectionTitle :title="BRAND.consoleName" />
        <p class="success-line">{{ BRAND.welcomeMessage }}</p>
        <div class="console-summary">
          <div>系统状态：运行中　安装目标：{{ selectedDisk?.devicePath || 'Mock 系统盘' }}</div>
          <div>管理地址：{{ consoleState.managementIpv4 }}/{{ consoleState.prefixLength }}　Web：http://{{ consoleState.managementIpv4 }}:{{ consoleState.webPort }}</div>
          <div>管理网口：{{ managementInterface?.interfaceName || '未设置' }}　识别依据：永久 MAC + PCI 地址</div>
        </div>
        <p class="paragraph">请输入菜单编号，然后按 Enter：</p>
        <div class="console-menu" data-testid="console-menu">
          <button
            v-for="item in consoleMenuItems"
            :key="item.number"
            class="text-option console-option"
            type="button"
            :data-testid="`console-option-${item.number}`"
            @click.stop="selectConsoleActionByClick(item.number)"
          >
            {{ item.number }}. {{ item.label }}
          </button>
        </div>
        <TerminalPrompt
          ref="activeInput"
          v-model="consoleInput"
          :label="BRAND.consolePrompt"
          test-id="console-input"
          maxlength="2"
          @submit="submitConsoleSelection"
        />
        <p v-if="consoleNotice" class="success-line" data-testid="console-notice">{{ consoleNotice }}</p>
        <p v-if="promptError" class="error-line" data-testid="prompt-error">{{ promptError }}</p>
        <p class="principle-line">
          安装后可在{{ BRAND.productName }} Web 中自由调整任意物理网口用途：管理口 / 宽带入口 / 服务器出口 / 普通LAN / 未使用。
        </p>
      </template>

      <template v-else-if="phase === 'console-action'">
        <TerminalSectionTitle :title="activeConsoleTitle" />

        <template v-if="consoleAction === 1">
          <div class="detail-lines" data-testid="system-status">
            <div>主机名：{{ hardware.hostname }}</div>
            <div>架构：{{ hardware.architecture }}</div>
            <div>处理器：{{ hardware.cpu }}</div>
            <div>内存：{{ hardware.memory }}</div>
            <div>启动方式：{{ hardware.bootMode }}</div>
            <div>运行时间：{{ formatUptime(consoleState.uptimeSeconds) }}</div>
            <div>管理网口：{{ managementInterface?.interfaceName || '未设置' }}</div>
            <div>管理地址：{{ consoleState.managementIpv4 }}/{{ consoleState.prefixLength }}</div>
            <div>Web 管理端口：{{ consoleState.webPort }}</div>
          </div>
          <div class="network-status-list">
            <div v-for="port in networkInterfaces" :key="port.permanentMac" class="network-status-row">
              {{ port.interfaceName.padEnd(10) }} {{ port.linkDetected ? '已连接' : '未连接' }}
              {{ String(port.speedMbps || '-').padStart(5) }}Mbps　{{ port.vendor }} {{ port.model }}
            </div>
          </div>
          <ReturnPrompt ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 2">
          <template v-if="actionStage === 'choose-port'">
            <p class="paragraph">选择新的管理网口。任何物理网口都可重复切换，不会被永久锁定。</p>
            <button
              v-for="(port, index) in networkInterfaces"
              :key="port.permanentMac"
              class="text-option port-option"
              type="button"
              @click.stop="choosePortByClick(index + 1)"
            >
              {{ index + 1 }}. {{ port.interfaceName }}　{{ port.linkDetected ? '已连接' : '未连接' }}　
              {{ port.speedMbps ? `${port.speedMbps}Mbps` : '-' }}　{{ port.vendor }} {{ port.model }}
              {{ port.selectedInitialManagementPort ? '　[当前管理口]' : '' }}
            </button>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="网口编号"
              test-id="action-input"
              maxlength="2"
              @submit="submitManagementPort"
            />
          </template>
          <template v-else-if="actionStage === 'confirm-port'">
            <div class="detail-lines">
              <div>接口名称：{{ selectedPort.interfaceName }}</div>
              <div>永久 MAC：{{ selectedPort.permanentMac }}</div>
              <div>PCI 地址：{{ selectedPort.pciAddress }}</div>
              <div>驱动：{{ selectedPort.driver }}</div>
              <div>厂商 / 型号：{{ selectedPort.vendor }} {{ selectedPort.model }}</div>
            </div>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="设为管理网口 (Y/N)"
              test-id="action-input"
              maxlength="1"
              @submit="confirmManagementPort"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 3">
          <template v-if="actionStage === 'input-ip'">
            <p class="paragraph">当前管理地址：{{ consoleState.managementIpv4 }}/{{ consoleState.prefixLength }}</p>
            <p class="muted-line">格式示例：192.168.3.1/24</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="新的 IPv4/前缀"
              test-id="action-input"
              maxlength="21"
              @submit="submitManagementIp"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 4">
          <template v-if="actionStage === 'reidentifying'">
            <div class="output-line">[MOCK] 正在按永久 MAC 和 PCI 地址重新识别物理网口...</div>
            <div class="output-line"><span class="block-cursor">_</span></div>
          </template>
          <template v-else-if="actionStage === 'confirm-rebind'">
            <p class="paragraph">发现以下接口名称变化，身份字段保持不变：</p>
            <div class="detail-lines">
              <div v-for="mapping in rebindMappings" :key="mapping.stableIdentity">
                {{ mapping.previousInterfaceName }} -> {{ mapping.detectedInterfaceName }}　
                {{ mapping.permanentMac }}　{{ mapping.pciAddress }}　{{ mapping.vendor }} {{ mapping.model }}
              </div>
            </div>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="应用重新绑定 (Y/N)"
              test-id="action-input"
              maxlength="1"
              @submit="confirmRebind"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 5">
          <template v-if="actionStage === 'input-web-port'">
            <p class="paragraph">当前 Web 管理端口：{{ consoleState.webPort }}</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="新端口 (1-65535)"
              test-id="action-input"
              maxlength="5"
              @submit="submitWebPort"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 6">
          <template v-if="actionStage === 'password-new'">
            <p class="muted-line">密码至少 8 位；明文只在当前输入中短暂存在，完成后立即清空。</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="passwordInput"
              label="新管理员密码"
              input-type="password"
              test-id="password-input"
              maxlength="64"
              @submit="submitNewPassword"
            />
          </template>
          <template v-else-if="actionStage === 'password-confirm'">
            <TerminalPrompt
              ref="activeInput"
              v-model="passwordConfirmInput"
              label="再次输入密码"
              input-type="password"
              test-id="password-confirm-input"
              maxlength="64"
              @submit="confirmNewPassword"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 7">
          <template v-if="actionStage === 'network-target'">
            <p class="muted-line">输入 IP 或主机名。测试结果由固定 Mock 逻辑生成，不发送网络请求。</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="测试目标"
              test-id="action-input"
              maxlength="64"
              @submit="submitNetworkTest"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 8">
          <template v-if="actionStage === 'choose-backup'">
            <p class="paragraph">检测到以下 Mock 配置备份：</p>
            <button
              v-for="backup in backups"
              :key="backup.id"
              class="text-option backup-option"
              type="button"
              @click.stop="chooseBackupByClick(backup.displayNumber)"
            >
              {{ backup.displayNumber }}. {{ backup.name }}　{{ backup.source }}　{{ backup.createdAt }}
            </button>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="备份编号"
              test-id="action-input"
              maxlength="2"
              @submit="submitBackupSelection"
            />
          </template>
          <template v-else-if="actionStage === 'confirm-backup'">
            <div class="detail-lines">
              <div>备份：{{ selectedBackup.name }}</div>
              <div>来源：{{ selectedBackup.source }}</div>
              <div>管理地址：{{ selectedBackup.managementIpv4 }}/{{ selectedBackup.prefixLength }}</div>
              <div>Web 端口：{{ selectedBackup.webPort }}</div>
            </div>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="导入此配置 (Y/N)"
              test-id="action-input"
              maxlength="1"
              @submit="confirmBackupRestore"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 9">
          <template v-if="actionStage === 'confirm-factory-reset'">
            <p class="warning-line">恢复出厂设置将重置本预览中的管理地址、Web 端口和网口选择。</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="确认恢复出厂设置 (Y/N)"
              test-id="action-input"
              maxlength="1"
              @submit="confirmFactoryReset"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 10">
          <template v-if="actionStage === 'confirm-reboot'">
            <p class="paragraph">配置会保留，运行时间会在 Mock 重启后归零。</p>
            <TerminalPrompt
              ref="activeInput"
              v-model="actionInput"
              label="确认重启系统 (Y/N)"
              test-id="action-input"
              maxlength="1"
              @submit="confirmConsoleReboot"
            />
          </template>
          <ActionResult v-else :message="actionResult" ref="activeInput" @submit="returnToConsole" />
        </template>

        <template v-else-if="consoleAction === 11">
          <p class="warning-line">此操作只会进入浏览器内的模拟关机画面。</p>
          <TerminalPrompt
            ref="activeInput"
            v-model="actionInput"
            label="确认关闭系统 (Y/N)"
            test-id="action-input"
            maxlength="1"
            @submit="confirmShutdown"
          />
        </template>

        <p v-if="promptError" class="error-line" data-testid="prompt-error">{{ promptError }}</p>
      </template>

      <template v-else-if="phase === 'maintenance'">
        <TerminalSectionTitle title="安全维护终端（Mock）" />
        <div class="maintenance-output" data-testid="maintenance-terminal">
          <div>{{ BRAND.installerHostName }} login: root</div>
          <div>{{ BRAND.productName }}安全维护终端。输入 help 查看允许的命令。</div>
          <template v-for="(entry, index) in maintenanceHistory" :key="`${entry.command}-${index}`">
            <div>root@{{ BRAND.installerHostName }}:~# {{ entry.command }}</div>
            <div v-if="entry.output" class="pre-line">{{ entry.output }}</div>
          </template>
        </div>
        <TerminalPrompt
          ref="activeInput"
          v-model="maintenanceInput"
          :label="`root@${BRAND.installerHostName}:~#`"
          test-id="maintenance-input"
          maxlength="80"
          @submit="submitMaintenanceCommand"
        />
        <p class="muted-line">白名单：help / lsblk / ip link / ethtool / reboot / clear / exit</p>
      </template>

      <template v-else-if="phase === 'halted'">
        <TerminalSectionTitle title="系统已关闭（Mock）" />
        <div class="output-line">[  OK  ] {{ BRAND.englishName }} services stopped.</div>
        <div class="output-line">[  OK  ] Mock disks synchronized.</div>
        <div class="output-line">System halted. No real machine was powered off.</div>
        <button class="text-option power-option" type="button" @click.stop="powerOn">
          按 Enter 模拟开机，或点击此行。
        </button>
        <ReturnPrompt ref="activeInput" label="" @submit="powerOn" />
      </template>
    </section>

    <footer class="terminal-footer">
      <span>{{ shortcutHint }}</span>
      <span class="footer-mode">MOCK ONLY / NO REAL DISK OR NETWORK ACCESS</span>
    </footer>
  </main>
</template>

<script setup>
import {
  computed,
  defineComponent,
  h,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
} from 'vue'
import {
  DEFAULT_CONSOLE_STATE,
  INSTALLER_SAFETY,
  MOCK_NETWORK_INTERFACES,
  cloneInstallerData,
  getInterfaceStableIdentity,
} from '../../models/installerPreview.js'
import { installerPreviewService } from '../../services/installerPreviewService.js'
import BRAND from '../../config/brand.js'

const TerminalSectionTitle = defineComponent({
  name: 'TerminalSectionTitle',
  props: { title: { type: String, required: true } },
  setup(props) {
    return () => h('div', { class: 'section-title' }, [
      h('div', { class: 'ascii-rule' }, '+------------------------------------------------------------------------------+'),
      h('div', { class: 'section-title-text' }, `| ${props.title}`),
      h('div', { class: 'ascii-rule' }, '+------------------------------------------------------------------------------+'),
    ])
  },
})

const TerminalPrompt = defineComponent({
  name: 'TerminalPrompt',
  inheritAttrs: false,
  props: {
    modelValue: { type: String, default: '' },
    label: { type: String, required: true },
    inputType: { type: String, default: 'text' },
    testId: { type: String, default: '' },
    maxlength: { type: [String, Number], default: 80 },
  },
  emits: ['update:modelValue', 'submit'],
  setup(props, { emit, expose }) {
    const input = ref(null)
    const focus = () => input.value?.focus()
    expose({ focus })
    return () => h('label', { class: 'terminal-prompt' }, [
      h('span', { class: 'prompt-label' }, `${props.label}${props.label ? ' >' : ''}`),
      h('input', {
        ref: input,
        class: 'prompt-input',
        type: props.inputType,
        value: props.modelValue,
        maxlength: Number(props.maxlength),
        autocomplete: 'off',
        spellcheck: 'false',
        'data-testid': props.testId,
        'aria-label': props.label || '按 Enter 继续',
        onInput: (event) => emit('update:modelValue', event.target.value),
        onKeydown: (event) => {
          if (event.key === 'Enter') {
            event.preventDefault()
            emit('submit')
          }
        },
      }),
    ])
  },
})

const ReturnPrompt = defineComponent({
  name: 'ReturnPrompt',
  props: { label: { type: String, default: '按 Enter 返回控制台菜单' } },
  emits: ['submit'],
  setup(props, { emit, expose }) {
    const input = ref(null)
    const focus = () => input.value?.focus()
    expose({ focus })
    return () => h('label', { class: 'terminal-prompt return-prompt' }, [
      h('span', { class: 'prompt-label' }, props.label),
      h('input', {
        ref: input,
        class: 'prompt-input return-input',
        value: '',
        readonly: true,
        'aria-label': props.label || '按 Enter 继续',
        onKeydown: (event) => {
          if (event.key === 'Enter') {
            event.preventDefault()
            emit('submit')
          }
        },
      }),
    ])
  },
})

const ActionResult = defineComponent({
  name: 'ActionResult',
  props: { message: { type: String, default: '' } },
  emits: ['submit'],
  setup(props, { emit, expose }) {
    const prompt = ref(null)
    expose({ focus: () => prompt.value?.focus() })
    return () => h('div', { class: 'action-result', 'data-testid': 'action-result' }, [
      h('div', { class: 'success-line pre-line' }, props.message),
      h(ReturnPrompt, { ref: prompt, onSubmit: () => emit('submit') }),
    ])
  },
})

const consoleMenuItems = Object.freeze([
  { number: 1, label: '查看系统和网络状态' },
  { number: 2, label: '设置管理网口' },
  { number: 3, label: '设置管理IP地址' },
  { number: 4, label: '重新识别和绑定网口' },
  { number: 5, label: '修改Web管理端口' },
  { number: 6, label: '重置管理员密码' },
  { number: 7, label: '测试网络连接' },
  { number: 8, label: '导入或恢复配置' },
  { number: 9, label: '恢复出厂设置' },
  { number: 10, label: '重启系统' },
  { number: 11, label: '关闭系统' },
  { number: 12, label: '进入维护终端' },
])

const safety = ref({ ...INSTALLER_SAFETY })
const hardware = ref({})
const disks = ref([])
const networkInterfaces = ref([])
const backups = ref([])
const installationStages = ref([])
const consoleState = ref(cloneInstallerData(DEFAULT_CONSOLE_STATE))

const phase = ref('scanning')
const scanLog = ref([])
const diskInput = ref('')
const selectedDisk = ref(null)
const confirmInput = ref('')
const promptError = ref('')
const installProgress = ref(0)
const installElapsedSeconds = ref(0)
const installLog = ref([])
const installSessionId = ref('')
const consoleInput = ref('')
const consoleNotice = ref('')
const consoleAction = ref(0)
const actionStage = ref('')
const actionInput = ref('')
const passwordInput = ref('')
const passwordConfirmInput = ref('')
const actionResult = ref('')
const selectedPort = ref(null)
const selectedBackup = ref(null)
const rebindMappings = ref([])
const maintenanceInput = ref('')
const maintenanceHistory = ref([])

const activeInput = ref(null)
const terminalBody = ref(null)
const timerIds = new Set()
let installTimer = null

const activeConsoleTitle = computed(() => {
  const item = consoleMenuItems.find((entry) => entry.number === consoleAction.value)
  return item ? `${item.number}. ${item.label}` : '本地控制台'
})

const managementInterface = computed(() => (
  networkInterfaces.value.find((item) => item.selectedInitialManagementPort)
))

const currentInstallStage = computed(() => {
  if (!installationStages.value.length) return '准备安装'
  const stageIndex = Math.min(
    installationStages.value.length - 1,
    Math.floor((installProgress.value / 100) * installationStages.value.length),
  )
  return installationStages.value[stageIndex]
})

const progressBar = computed(() => {
  const width = 40
  const filled = Math.round((installProgress.value / 100) * width)
  return `${'='.repeat(Math.max(0, filled - 1))}${filled ? '>' : ''}${' '.repeat(width - filled)}`
})

const formattedInstallElapsed = computed(() => {
  const minutes = Math.floor(installElapsedSeconds.value / 60)
  const seconds = installElapsedSeconds.value % 60
  return `00:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
})

const shortcutHint = computed(() => {
  if (phase.value === 'installing' || phase.value === 'scanning') return '请稍候，当前阶段无需输入'
  if (phase.value === 'console-action' || phase.value === 'maintenance') return 'Enter 确认　Esc 返回控制台'
  if (phase.value === 'disk-confirm') return 'Y/N + Enter 确认　Esc 返回选盘'
  if (phase.value === 'halted') return 'Enter 模拟开机'
  return '数字 + Enter 确认　也可点击文本菜单'
})

function schedule(callback, delay) {
  const id = window.setTimeout(() => {
    timerIds.delete(id)
    callback()
  }, delay)
  timerIds.add(id)
  return id
}

function clearTimers() {
  for (const id of timerIds) window.clearTimeout(id)
  timerIds.clear()
  if (installTimer !== null) {
    window.clearInterval(installTimer)
    installTimer = null
  }
}

function focusPrompt() {
  nextTick(() => activeInput.value?.focus?.())
}

function scrollTerminalToBottom() {
  nextTick(() => {
    if (terminalBody.value) terminalBody.value.scrollTop = terminalBody.value.scrollHeight
  })
}

function resetTerminalScroll() {
  nextTick(() => {
    if (terminalBody.value) terminalBody.value.scrollTop = 0
  })
}

function diskStatus(disk) {
  if (disk.isCurrentInstallMedia) return '当前安装介质，不可选择'
  return disk.containsData ? '包含数据' : '空硬盘'
}

async function loadMockInventory() {
  const response = await installerPreviewService.scanHardware()
  safety.value = { ...response.meta }
  hardware.value = response.data.hardware
  disks.value = response.data.disks
  networkInterfaces.value = response.data.networkInterfaces
  backups.value = response.data.backups
  consoleState.value = response.data.consoleState
  installationStages.value = response.data.installationStages
}

async function startAutomaticScan() {
  phase.value = 'scanning'
  scanLog.value = []
  await loadMockInventory()
  const messages = [
    `[MOCK] 检测启动方式：${hardware.value.bootMode}`,
    `[MOCK] 检测到 ${disks.value.length} 块存储设备，其中 1 块为当前安装介质`,
    `[MOCK] 检测到 ${networkInterfaces.value.length} 个物理网口`,
    '[MOCK] 扫描完成，未访问真实硬盘或真实网络配置',
  ]
  messages.forEach((message, index) => {
    schedule(() => {
      scanLog.value.push(message)
      scrollTerminalToBottom()
    }, 130 + index * 150)
  })
  schedule(() => {
    phase.value = 'disk-select'
    resetTerminalScroll()
    focusPrompt()
  }, 820)
}

async function submitDiskSelection() {
  promptError.value = ''
  const response = await installerPreviewService.inspectDisk(diskInput.value)
  if (!response.data.valid) {
    promptError.value = response.data.reason
    diskInput.value = ''
    focusPrompt()
    return
  }
  selectedDisk.value = response.data.disk
  diskInput.value = ''
  confirmInput.value = ''
  phase.value = 'disk-confirm'
  resetTerminalScroll()
  focusPrompt()
}

function selectDiskByClick(disk) {
  diskInput.value = disk.displayNumber
  submitDiskSelection()
}

async function submitInstallConfirmation() {
  promptError.value = ''
  const answer = confirmInput.value.trim().toLowerCase()
  if (answer === 'n') {
    confirmInput.value = ''
    selectedDisk.value = null
    phase.value = 'disk-select'
    focusPrompt()
    return
  }
  if (answer !== 'y') {
    promptError.value = '请输入 Y 或 N，然后按 Enter。'
    confirmInput.value = ''
    focusPrompt()
    return
  }

  const response = await installerPreviewService.createInstallSession(selectedDisk.value)
  if (!response.data.started) {
    promptError.value = response.data.reason
    confirmInput.value = ''
    focusPrompt()
    return
  }
  installSessionId.value = response.data.sessionId
  startMockInstallation()
}

function confirmInstallByClick(answer) {
  confirmInput.value = answer
  submitInstallConfirmation()
}

function startMockInstallation() {
  clearTimers()
  phase.value = 'installing'
  promptError.value = ''
  installProgress.value = 0
  installElapsedSeconds.value = 0
  installLog.value = ['[MOCK] 安装任务已启动']
  resetTerminalScroll()
  let previousStage = ''
  installTimer = window.setInterval(() => {
    installProgress.value = Math.min(100, installProgress.value + 2)
    installElapsedSeconds.value += 2
    const stage = currentInstallStage.value
    if (stage !== previousStage) {
      previousStage = stage
      installLog.value.push(`[MOCK] ${stage}`)
      if (installLog.value.length > 7) installLog.value.shift()
      scrollTerminalToBottom()
    }
    if (installProgress.value >= 100) {
      window.clearInterval(installTimer)
      installTimer = null
      installLog.value.push('[MOCK] 安装完成，正在进入本地控制台')
      schedule(() => enterConsole(`${BRAND.productName}模拟安装完成。`), 650)
    }
  }, 80)
}

function resetActionState() {
  consoleAction.value = 0
  actionStage.value = ''
  actionInput.value = ''
  passwordInput.value = ''
  passwordConfirmInput.value = ''
  actionResult.value = ''
  selectedPort.value = null
  selectedBackup.value = null
  rebindMappings.value = []
  promptError.value = ''
}

function enterConsole(notice = '') {
  clearTimers()
  resetActionState()
  phase.value = 'console-menu'
  consoleInput.value = ''
  consoleNotice.value = notice
  resetTerminalScroll()
  focusPrompt()
}

function returnToConsole() {
  enterConsole('')
}

function submitConsoleSelection() {
  promptError.value = ''
  const number = Number(consoleInput.value.trim())
  consoleInput.value = ''
  if (!Number.isInteger(number) || number < 1 || number > 12) {
    promptError.value = '请输入 1 到 12 的菜单编号。'
    focusPrompt()
    return
  }
  openConsoleAction(number)
}

function selectConsoleActionByClick(number) {
  consoleInput.value = String(number)
  submitConsoleSelection()
}

function openConsoleAction(number) {
  resetActionState()
  consoleAction.value = number
  phase.value = number === 12 ? 'maintenance' : 'console-action'
  resetTerminalScroll()

  const stages = {
    1: 'status',
    2: 'choose-port',
    3: 'input-ip',
    4: 'reidentifying',
    5: 'input-web-port',
    6: 'password-new',
    7: 'network-target',
    8: 'choose-backup',
    9: 'confirm-factory-reset',
    10: 'confirm-reboot',
    11: 'confirm-shutdown',
  }
  actionStage.value = stages[number] || ''

  if (number === 4) beginInterfaceReidentification()
  if (number === 12) {
    maintenanceInput.value = ''
    maintenanceHistory.value = []
  }
  focusPrompt()
}

function choosePortByClick(number) {
  actionInput.value = String(number)
  submitManagementPort()
}

function submitManagementPort() {
  promptError.value = ''
  const index = Number(actionInput.value.trim()) - 1
  if (!Number.isInteger(index) || !networkInterfaces.value[index]) {
    promptError.value = `请输入 1 到 ${networkInterfaces.value.length} 的网口编号。`
    actionInput.value = ''
    focusPrompt()
    return
  }
  selectedPort.value = networkInterfaces.value[index]
  actionInput.value = ''
  actionStage.value = 'confirm-port'
  focusPrompt()
}

function confirmManagementPort() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()

  const selectedIdentity = getInterfaceStableIdentity(selectedPort.value)
  networkInterfaces.value = networkInterfaces.value.map((port) => ({
    ...port,
    selectedInitialManagementPort: getInterfaceStableIdentity(port) === selectedIdentity,
  }))
  actionResult.value = `管理网口已在 Mock 状态中切换为 ${selectedPort.value.interfaceName}。\n后续仍可再次切换或在 Web 中分配任意角色。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function isValidIpv4(value) {
  const parts = value.split('.')
  return parts.length === 4 && parts.every((part) => {
    if (!/^\d{1,3}$/.test(part)) return false
    const number = Number(part)
    return number >= 0 && number <= 255 && String(number) === part
  })
}

function submitManagementIp() {
  promptError.value = ''
  const [address, prefixText, ...rest] = actionInput.value.trim().split('/')
  const prefix = Number(prefixText)
  if (rest.length || !isValidIpv4(address) || !Number.isInteger(prefix) || prefix < 0 || prefix > 32) {
    promptError.value = '请输入有效的 IPv4/前缀，例如 192.168.3.1/24。'
    focusPrompt()
    return
  }
  consoleState.value.managementIpv4 = address
  consoleState.value.prefixLength = prefix
  actionResult.value = `管理地址已在 Mock 状态中更新为 ${address}/${prefix}。\n未执行真实网络配置命令。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

async function beginInterfaceReidentification() {
  const response = await installerPreviewService.reidentifyInterfaces(networkInterfaces.value)
  rebindMappings.value = response.data.mappings
  schedule(() => {
    if (phase.value === 'console-action' && consoleAction.value === 4) {
      actionStage.value = 'confirm-rebind'
      focusPrompt()
    }
  }, 650)
}

function confirmRebind() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()

  const mappingByIdentity = new Map(
    rebindMappings.value.map((mapping) => [mapping.stableIdentity, mapping]),
  )
  networkInterfaces.value = networkInterfaces.value.map((port) => {
    const mapping = mappingByIdentity.get(getInterfaceStableIdentity(port))
    return mapping ? { ...port, interfaceName: mapping.detectedInterfaceName } : port
  })
  actionResult.value = '重新绑定已应用。永久 MAC、PCI 地址、驱动、厂商和型号均保持不变。'
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function submitWebPort() {
  promptError.value = ''
  const port = Number(actionInput.value.trim())
  if (!/^\d+$/.test(actionInput.value.trim()) || !Number.isInteger(port) || port < 1 || port > 65535) {
    promptError.value = '请输入 1 到 65535 之间的整数端口。'
    focusPrompt()
    return
  }
  consoleState.value.webPort = port
  actionResult.value = `Web 管理端口已在 Mock 状态中更新为 ${port}。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function submitNewPassword() {
  promptError.value = ''
  if (passwordInput.value.length < 8) {
    promptError.value = '密码长度不能少于 8 位。'
    focusPrompt()
    return
  }
  actionStage.value = 'password-confirm'
  focusPrompt()
}

function confirmNewPassword() {
  promptError.value = ''
  if (passwordInput.value !== passwordConfirmInput.value) {
    promptError.value = '两次输入的密码不一致，请重新输入。'
    passwordInput.value = ''
    passwordConfirmInput.value = ''
    actionStage.value = 'password-new'
    focusPrompt()
    return
  }
  consoleState.value.passwordConfigured = true
  consoleState.value.passwordResetCount += 1
  passwordInput.value = ''
  passwordConfirmInput.value = ''
  actionResult.value = '管理员密码已在 Mock 状态中重置。浏览器内未保留密码明文。'
  actionStage.value = 'result'
  focusPrompt()
}

async function submitNetworkTest() {
  promptError.value = ''
  if (!actionInput.value.trim()) {
    promptError.value = '测试目标不能为空。'
    focusPrompt()
    return
  }
  const response = await installerPreviewService.testNetwork(actionInput.value, consoleState.value)
  const result = response.data
  actionResult.value = result.successful
    ? `PING ${result.target} (Mock)：成功\n延迟：${result.latencyMs}ms　丢包：${result.packetLoss}\n没有发送真实网络请求。`
    : `PING ${result.target} (Mock)：失败\n丢包：${result.packetLoss}\n没有发送真实网络请求。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function chooseBackupByClick(displayNumber) {
  actionInput.value = String(displayNumber)
  submitBackupSelection()
}

function submitBackupSelection() {
  promptError.value = ''
  const backup = backups.value.find((item) => item.displayNumber === actionInput.value.trim())
  if (!backup) {
    promptError.value = '请输入列表中的备份编号。'
    actionInput.value = ''
    focusPrompt()
    return
  }
  selectedBackup.value = backup
  actionInput.value = ''
  actionStage.value = 'confirm-backup'
  focusPrompt()
}

function confirmBackupRestore() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()

  consoleState.value.managementIpv4 = selectedBackup.value.managementIpv4
  consoleState.value.prefixLength = selectedBackup.value.prefixLength
  consoleState.value.webPort = selectedBackup.value.webPort
  consoleState.value.restoredBackupName = selectedBackup.value.name
  actionResult.value = `Mock 配置 ${selectedBackup.value.name} 已恢复。\n没有读取真实U盘或配置文件。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function confirmFactoryReset() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()

  consoleState.value = cloneInstallerData(DEFAULT_CONSOLE_STATE)
  networkInterfaces.value = cloneInstallerData(MOCK_NETWORK_INTERFACES)
  actionResult.value = 'Mock 控制台配置已恢复出厂默认值。硬件库存和安装结果保持不变。'
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function confirmConsoleReboot() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()

  consoleState.value.uptimeSeconds = 0
  actionResult.value = `${BRAND.productName}已完成 Mock 重启。现有配置保持不变。`
  actionInput.value = ''
  actionStage.value = 'result'
  focusPrompt()
}

function confirmShutdown() {
  const answer = parseYesNo(actionInput.value)
  if (!answer) return invalidYesNo()
  if (answer === 'n') return returnToConsole()
  actionInput.value = ''
  phase.value = 'halted'
  resetTerminalScroll()
  focusPrompt()
}

function powerOn() {
  consoleState.value.uptimeSeconds = 0
  enterConsole(`${BRAND.productName}已完成 Mock 开机。`)
}

function parseYesNo(value) {
  const answer = value.trim().toLowerCase()
  return answer === 'y' || answer === 'n' ? answer : ''
}

function invalidYesNo() {
  promptError.value = '请输入 Y 或 N，然后按 Enter。'
  actionInput.value = ''
  focusPrompt()
}

async function submitMaintenanceCommand() {
  const command = maintenanceInput.value.trim()
  maintenanceInput.value = ''
  if (!command) {
    focusPrompt()
    return
  }
  const response = await installerPreviewService.runMaintenanceCommand(command, {
    networkInterfaces: networkInterfaces.value,
    consoleState: consoleState.value,
  })
  if (response.data.action === 'clear') {
    maintenanceHistory.value = []
  } else if (response.data.action === 'exit') {
    returnToConsole()
    return
  } else {
    maintenanceHistory.value.push({
      command,
      output: response.data.output,
    })
    if (maintenanceHistory.value.length > 18) maintenanceHistory.value.shift()
  }
  scrollTerminalToBottom()
  focusPrompt()
}

function formatUptime(seconds) {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const remaining = seconds % 60
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(remaining).padStart(2, '0')}`
}

function handleGlobalKeydown(event) {
  if (event.key !== 'Escape') return
  if (phase.value === 'disk-confirm') {
    event.preventDefault()
    selectedDisk.value = null
    confirmInput.value = ''
    promptError.value = ''
    phase.value = 'disk-select'
    focusPrompt()
  } else if (phase.value === 'console-action' || phase.value === 'maintenance') {
    event.preventDefault()
    returnToConsole()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleGlobalKeydown)
  startAutomaticScan()
})

onBeforeUnmount(() => {
  clearTimers()
  window.removeEventListener('keydown', handleGlobalKeydown)
})
</script>

<style scoped>
.installer-terminal {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: auto minmax(0, 1fr) auto;
  width: 100vw;
  height: 100vh;
  height: 100dvh;
  overflow: hidden;
  background: #050505;
  color: #d8d8d8;
  font-family: "Cascadia Mono", "Courier New", "Noto Sans Mono CJK SC", monospace;
  font-size: 15px;
  line-height: 1.48;
  text-align: left;
}

.installer-terminal,
.installer-terminal * {
  box-sizing: border-box;
  border-radius: 0;
  box-shadow: none;
}

.installer-terminal * {
  font-family: inherit;
}

.terminal-header {
  min-width: 0;
  padding: 10px 18px 7px;
  color: #f1f1f1;
}

.ascii-rule,
.terminal-title,
.section-title-text {
  width: 100%;
  overflow: hidden;
  white-space: nowrap;
}

.ascii-rule {
  color: #8d8d8d;
  letter-spacing: 0.02em;
}

.terminal-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  min-height: 50px;
  color: #fff;
  font-weight: 700;
}

.terminal-brand {
  flex: 0 1 auto;
  min-width: 0;
}

.terminal-version {
  flex: 0 0 auto;
  color: #bdbdbd;
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.02em;
}

.terminal-brand :deep(.brand-primary) {
  color: #fff;
  font-family: inherit;
}

.terminal-brand :deep(.brand-secondary) {
  color: #74b9ff;
  font-family: inherit;
}

.safety-line {
  padding-top: 5px;
  color: #8e8e8e;
  font-size: 13px;
}

.terminal-body {
  min-width: 0;
  min-height: 0;
  padding: 8px 24px 22px;
  overflow-x: hidden;
  overflow-y: auto;
  scrollbar-color: #606060 #090909;
}

.section-title {
  margin-bottom: 14px;
  color: #e6e6e6;
}

.section-title-text {
  color: #fff;
}

.paragraph,
.warning-line,
.muted-line,
.error-line,
.success-line,
.principle-line {
  margin: 9px 0;
}

.warning-line {
  color: #fff;
}

.muted-line {
  color: #888;
}

.error-line {
  color: #fff;
  background: #6b0000;
  white-space: pre-wrap;
}

.success-line {
  color: #fff;
}

.principle-line {
  color: #a7a7a7;
}

.output-line,
.pre-line {
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.disk-list,
.console-menu,
.network-status-list {
  margin: 13px 0;
}

.text-option {
  display: block;
  width: 100%;
  min-width: 0;
  margin: 0;
  padding: 2px 4px;
  border: 0;
  outline: 0;
  background: transparent;
  color: #e0e0e0;
  font: inherit;
  line-height: inherit;
  text-align: left;
  white-space: normal;
  overflow-wrap: anywhere;
  cursor: pointer;
}

.text-option:hover,
.text-option:focus-visible {
  background: #d8d8d8;
  color: #050505;
}

.text-option.protected {
  color: #737373;
  cursor: not-allowed;
}

.text-option.protected:hover,
.text-option.protected:focus-visible {
  background: #3a3a3a;
  color: #c5c5c5;
}

.console-menu {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  max-width: 940px;
  column-gap: 28px;
}

.inline-options {
  display: flex;
  flex-wrap: wrap;
  gap: 0 24px;
  margin: 10px 0;
}

.inline-option {
  width: auto;
}

.terminal-prompt {
  display: flex;
  align-items: baseline;
  min-width: 0;
  margin-top: 14px;
  color: #fff;
  cursor: text;
}

.prompt-label {
  flex: 0 0 auto;
  white-space: pre-wrap;
}

.prompt-input {
  flex: 1 1 auto;
  min-width: 2ch;
  max-width: 720px;
  margin: 0;
  padding: 0 0 0 1ch;
  border: 0;
  outline: 0;
  background: transparent;
  color: #fff;
  caret-color: #fff;
  font: inherit;
  line-height: inherit;
}

.return-input {
  flex: 0 0 2ch;
  width: 2ch;
  padding-left: 1ch;
}

.installer-terminal :deep(.terminal-prompt) {
  display: flex;
  align-items: baseline;
  min-width: 0;
  margin-top: 14px;
  color: #fff;
  cursor: text;
}

.installer-terminal :deep(.prompt-label) {
  flex: 0 0 auto;
  white-space: pre-wrap;
}

.installer-terminal :deep(.prompt-input) {
  appearance: none;
  flex: 1 1 auto;
  min-width: 2ch;
  max-width: 720px;
  margin: 0;
  padding: 0 0 0 1ch;
  border: 0;
  outline: 0;
  background: transparent;
  color: #fff;
  caret-color: #fff;
  font: inherit;
  line-height: inherit;
}

.installer-terminal :deep(.return-input) {
  flex: 0 0 2ch;
  width: 2ch;
  padding-left: 1ch;
}

.installer-terminal :deep(.section-title .ascii-rule),
.installer-terminal :deep(.section-title-text) {
  width: 100%;
  overflow: hidden;
  white-space: nowrap;
}

.installer-terminal :deep(.section-title .ascii-rule) {
  color: #8d8d8d;
  letter-spacing: 0.02em;
}

.installer-terminal :deep(.section-title-text) {
  color: #fff;
}

.installer-terminal :deep(.action-result .pre-line) {
  margin: 9px 0;
  color: #fff;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.detail-lines,
.progress-block,
.console-summary,
.maintenance-output {
  margin: 12px 0;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.progress-line {
  color: #fff;
  white-space: pre-wrap;
}

.install-log {
  margin: 14px 0;
  color: #bcbcbc;
}

.network-status-row {
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.port-option,
.backup-option {
  margin: 2px 0;
}

.action-result {
  margin-top: 8px;
}

.power-option {
  width: auto;
  margin-top: 14px;
}

.block-cursor {
  display: inline-block;
  color: #fff;
  animation: terminal-blink 1s steps(1, end) infinite;
}

.terminal-footer {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  min-width: 0;
  padding: 7px 18px;
  border-top: 1px solid #555;
  background: #101010;
  color: #cfcfcf;
  font-size: 13px;
  white-space: nowrap;
  overflow: hidden;
}

.footer-mode {
  color: #777;
  overflow: hidden;
  text-overflow: ellipsis;
}

@keyframes terminal-blink {
  0%,
  49% {
    opacity: 1;
  }

  50%,
  100% {
    opacity: 0;
  }
}

@media (max-width: 760px) {
  .installer-terminal {
    font-size: 13px;
  }

  .terminal-header {
    padding-right: 10px;
    padding-left: 10px;
  }

  .terminal-title {
    min-height: 46px;
  }

  .terminal-version {
    display: none;
  }

  .terminal-body {
    padding-right: 12px;
    padding-left: 12px;
  }

  .console-menu {
    grid-template-columns: minmax(0, 1fr);
  }

  .terminal-footer {
    padding-right: 10px;
    padding-left: 10px;
  }

  .footer-mode {
    display: none;
  }
}
</style>
