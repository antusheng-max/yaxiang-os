<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>IPv6 诊断</h2>
      <p>提供 Ping6、Traceroute6、DNS 查询等 IPv6 网络诊断工具（演示模式：返回模拟结果）</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <el-tabs v-model="activeTab">
                  <!-- Ping6 -->
                  <el-tab-pane label="Ping6" name="ping">
                    <div class="diag-block">
                      <div class="diag-form">
                        <el-input
                          v-model="pingInput"
                          placeholder="输入 IPv6 地址或域名，如 2408:8888::8888 或 ipv6.google.com"
      
                          @keyup.enter="runPing"
                        />
                        <el-input-number
                          v-model="pingCount"
                          :min="1"
                          :max="20"
                          controls-position="right"
      
                        />
                        <el-button
                          type="primary"
                          :loading="pingLoading"
      
                          @click="runPing"
                        >执行</el-button>
                        <el-button @click="pingResult = ''">清空</el-button>
                      </div>
                      <el-input
                        v-model="pingResult"
                        type="textarea"
                        :rows="12"
                        readonly
                        placeholder="结果将显示在此处"
                        class="diag-result"
                      />
                    </div>
                  </el-tab-pane>
      
                  <!-- Traceroute6 -->
                  <el-tab-pane label="Traceroute6" name="traceroute">
                    <div class="diag-block">
                      <div class="diag-form">
                        <el-input
                          v-model="traceInput"
                          placeholder="输入 IPv6 地址或域名，如 2001:4860:4860::8888"
      
                          @keyup.enter="runTrace"
                        />
                        <el-input-number
                          v-model="traceMaxHops"
                          :min="1"
                          :max="64"
                          controls-position="right"
      
                        />
                        <el-button
                          type="primary"
                          :loading="traceLoading"
      
                          @click="runTrace"
                        >执行</el-button>
                        <el-button @click="traceResult = ''">清空</el-button>
                      </div>
                      <el-input
                        v-model="traceResult"
                        type="textarea"
                        :rows="12"
                        readonly
                        placeholder="结果将显示在此处"
                        class="diag-result"
                      />
                    </div>
                  </el-tab-pane>
      
                  <!-- DNS 查询 -->
                  <el-tab-pane label="DNS 查询" name="dns">
                    <div class="diag-block">
                      <div class="diag-form">
                        <el-input
                          v-model="dnsInput"
                          placeholder="输入域名，如 ipv6.google.com"
      
                          @keyup.enter="runDns"
                        />
                        <el-select
                          v-model="dnsType"
      
                        >
                          <el-option label="A" value="A" />
                          <el-option label="AAAA" value="AAAA" />
                          <el-option label="CNAME" value="CNAME" />
                          <el-option label="MX" value="MX" />
                          <el-option label="TXT" value="TXT" />
                          <el-option label="NS" value="NS" />
                          <el-option label="PTR" value="PTR" />
                        </el-select>
                        <el-button
                          type="primary"
                          :loading="dnsLoading"
      
                          @click="runDns"
                        >执行</el-button>
                        <el-button @click="dnsResult = ''">清空</el-button>
                      </div>
                      <el-input
                        v-model="dnsResult"
                        type="textarea"
                        :rows="12"
                        readonly
                        placeholder="结果将显示在此处"
                        class="diag-result"
                      />
                    </div>
                  </el-tab-pane>
                </el-tabs>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

const activeTab = ref('ping')

// Ping6
const pingInput = ref('2408:8888::8888')
const pingCount = ref(4)
const pingLoading = ref(false)
const pingResult = ref('')

// Traceroute6
const traceInput = ref('2001:4860:4860::8888')
const traceMaxHops = ref(30)
const traceLoading = ref(false)
const traceResult = ref('')

// DNS
const dnsInput = ref('ipv6.google.com')
const dnsType = ref('AAAA')
const dnsLoading = ref(false)
const dnsResult = ref('')

function randomLatency(base = 10, jitter = 20) {
  return (base + Math.random() * jitter).toFixed(3)
}

async function runPing() {
  if (!pingInput.value) {
    ElMessage.warning('请输入目标地址')
    return
  }
  pingLoading.value = true
  pingResult.value = ''
  await new Promise(r => setTimeout(r, 600))
  const target = pingInput.value
  const count = pingCount.value
  const lines = []
  lines.push(`PING6 ${target} (${target}): 56 data bytes`)
  for (let i = 0; i < count; i++) {
    const t = randomLatency(8, 15)
    lines.push(`64 bytes from ${target}: icmp_seq=${i + 1} hlim=64 time=${t} ms`)
    await new Promise(r => setTimeout(r, 300))
  }
  lines.push('')
  lines.push(`--- ${target} ping6 statistics ---`)
  lines.push(`${count} packets transmitted, ${count} packets received, 0.0% packet loss`)
  lines.push(`round-trip min/avg/max = ${(8).toFixed(3)}/${(15).toFixed(3)}/${(23).toFixed(3)} ms`)
  pingResult.value = lines.join('\n')
  pingLoading.value = false
  ElMessage.success('Ping6 完成')
}

async function runTrace() {
  if (!traceInput.value) {
    ElMessage.warning('请输入目标地址')
    return
  }
  traceLoading.value = true
  traceResult.value = ''
  await new Promise(r => setTimeout(r, 500))
  const target = traceInput.value
  const hops = Math.min(traceMaxHops.value, 8 + Math.floor(Math.random() * 4))
  const lines = []
  lines.push(`traceroute6 to ${target} (${target}), ${traceMaxHops.value} hops max, 16 byte packets`)
  const gateways = [
    'fe80::aabb:ccdd:eeff',
    'fe80::1',
    '2408:8000::1',
    '2408:8888::1',
    '2001:4860::1',
    target,
  ]
  for (let i = 1; i <= hops; i++) {
    const gw = i <= gateways.length ? gateways[i - 1] : target
    const t1 = randomLatency(5, 10)
    const t2 = randomLatency(5, 10)
    const t3 = randomLatency(5, 10)
    lines.push(` ${i}  ${gw}  ${t1} ms  ${t2} ms  ${t3} ms`)
    await new Promise(r => setTimeout(r, 250))
  }
  traceResult.value = lines.join('\n')
  traceLoading.value = false
  ElMessage.success('Traceroute6 完成')
}

async function runDns() {
  if (!dnsInput.value) {
    ElMessage.warning('请输入域名')
    return
  }
  dnsLoading.value = true
  dnsResult.value = ''
  await new Promise(r => setTimeout(r, 500))
  const domain = dnsInput.value
  const type = dnsType.value
  const lines = []
  lines.push(`; <<>> DiG 9.18 <<>> ${domain} ${type}`)
  lines.push(`;; QUESTION SECTION:`)
  lines.push(`;${domain}.\t\t\tIN\t${type}`)
  lines.push('')
  lines.push(`;; ANSWER SECTION:`)

  if (type === 'AAAA') {
    lines.push(`${domain}.\t\t300\tIN\tAAAA\t2408:8888::8888`)
    lines.push(`${domain}.\t\t300\tIN\tAAAA\t2001:4860:4860::8888`)
  } else if (type === 'A') {
    lines.push(`${domain}.\t\t300\tIN\tA\t8.8.8.8`)
  } else if (type === 'CNAME') {
    lines.push(`${domain}.\t\t300\tIN\tCNAME\t${domain}.cdn.example.com.`)
  } else if (type === 'MX') {
    lines.push(`${domain}.\t\t300\tIN\tMX\t10 mail.${domain}.`)
  } else if (type === 'TXT') {
    lines.push(`${domain}.\t\t300\tIN\tTXT\t"v=spf1 include:_spf.${domain} ~all"`)
  } else if (type === 'NS') {
    lines.push(`${domain}.\t\t300\tIN\tNS\tns1.${domain}.`)
    lines.push(`${domain}.\t\t300\tIN\tNS\tns2.${domain}.`)
  } else if (type === 'PTR') {
    lines.push(`${domain}.\t\t300\tIN\tPTR\t${domain}.`)
  }

  lines.push('')
  lines.push(`;; Query time: ${Math.floor(Math.random() * 50 + 5)} msec`)
  lines.push(`;; SERVER: 2408:8888::8888#53`)
  lines.push(`;; WHEN: ${new Date().toLocaleString()}`)
  dnsResult.value = lines.join('\n')
  dnsLoading.value = false
  ElMessage.success('DNS 查询完成')
}
</script>

<style scoped>
.diag-block { padding-top: 12px; }
.diag-form { margin-bottom: 16px; display: flex; align-items: center; flex-wrap: wrap; }
.diag-result { font-family: monospace; font-size: 13px; }
:deep(.diag-result .el-textarea__inner) {
  font-family: monospace;
  font-size: 13px;
  line-height: 1.5;
}
</style>
