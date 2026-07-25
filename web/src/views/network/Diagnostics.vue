<template>
  <PageContainer>
    <PageHeader title="路由表" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>网络诊断工具</span></template>
            <el-form inline>
              <el-form-item label="目标地址">
                <el-input v-model="target" placeholder="IP或域名" />
              </el-form-item>
              <el-form-item label="工具">
                <el-select v-model="tool">
                  <el-option label="Ping" value="ping" />
                  <el-option label="Traceroute" value="traceroute" />
                  <el-option label="nslookup" value="nslookup" />
                  <el-option label="端口扫描" value="portscan" />
                </el-select>
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="runDiag" :loading="loading">执行</el-button>
              </el-form-item>
            </el-form>
            <div class="diag-output" v-if="output">
              <pre>{{ output }}</pre>
            </div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'

const target = ref('8.8.8.8')
const tool = ref('ping')
const loading = ref(false)
const output = ref('')

function runDiag() {
  loading.value = true
  output.value = ''
  setTimeout(() => {
    if (tool.value === 'ping') {
      output.value = `PING ${target.value} (${target.value}): 56 data bytes\n64 bytes from ${target.value}: seq=0 ttl=54 time=8.234 ms\n64 bytes from ${target.value}: seq=1 ttl=54 time=7.891 ms\n64 bytes from ${target.value}: seq=2 ttl=54 time=8.102 ms\n64 bytes from ${target.value}: seq=3 ttl=54 time=7.956 ms\n64 bytes from ${target.value}: seq=4 ttl=54 time=8.012 ms\n\n--- ${target.value} ping statistics ---\n5 packets transmitted, 5 packets received, 0% packet loss\nround-trip min/avg/max = 7.891/8.039/8.234 ms`
    } else if (tool.value === 'traceroute') {
      output.value = `traceroute to ${target.value}, 30 hops max\n 1  192.168.1.1  0.523 ms  0.412 ms  0.389 ms\n 2  100.64.1.1  3.245 ms  3.102 ms  3.089 ms\n 3  10.255.0.1  5.678 ms  5.534 ms  5.412 ms\n 4  202.97.33.1  8.901 ms  8.756 ms  8.623 ms\n 5  ${target.value}  9.234 ms  9.102 ms  9.056 ms`
    } else if (tool.value === 'nslookup') {
      output.value = `Server:  202.96.128.86\nAddress: 202.96.128.86#53\n\nNon-authoritative answer:\nName: ${target.value}\nAddress: 142.250.80.46\nName: ${target.value}\nAddress: 2404:6800:4008:800::200e`
    } else {
      output.value = `端口扫描: ${target.value}\n  22/tcp   open   ssh\n  80/tcp   open   http\n  443/tcp  open   https\n  53/tcp   open   domain\n  其他端口关闭\n\n扫描完成: 1000个端口, 4个开放`
    }
    loading.value = false
  }, 1500)
}
</script>

<style scoped>
.diag-output { margin-top: 16px; background: #1e1e1e; border-radius: 8px; padding: 16px; }
.diag-output pre { color: #0f0; font-family: 'Courier New', monospace; font-size: 13px; white-space: pre-wrap; margin: 0; }
</style>
