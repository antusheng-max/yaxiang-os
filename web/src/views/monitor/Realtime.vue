<template>
  <PageContainer>
    <PageHeader class="page-header">
      <h2>实时监控</h2>
      <p>流量走势、连接数、延迟、丢包率、网络使用率（每2秒自动刷新）</p>
    </PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <!-- 顶部实时指标卡片 -->
          <el-row :gutter="12">
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value">{{ metrics.totalRx }}</div><div class="metric-label">总下行</div></SectionCard></el-col>
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value">{{ metrics.totalTx }}</div><div class="metric-label">总上行</div></SectionCard></el-col>
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value">{{ metrics.connections }}</div><div class="metric-label">活跃连接数</div></SectionCard></el-col>
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value">{{ metrics.avgLatency }}ms</div><div class="metric-label">平均延迟</div></SectionCard></el-col>
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value" :class="{'status-warn': metrics.lossRate > 1}">{{ metrics.lossRate }}%</div><div class="metric-label">丢包率</div></SectionCard></el-col>
            <el-col :xs="12" :sm="8" :md="4"><SectionCard shadow="hover" class="metric-card"><div class="metric-value">{{ metrics.cpuLoad }}%</div><div class="metric-label">CPU使用率</div></SectionCard></el-col>
          </el-row>
      
          <!-- 流量走势图 -->
          <el-row :gutter="16">
            <el-col :xs="24" :md="16">
              <SectionCard><template #header>WAN 流量走势（实时）</template>
                <div ref="trafficChart" class="chart-box" style="height:280px"></div>
              </SectionCard>
            </el-col>
            <el-col :xs="24" :md="8">
              <SectionCard><template #header>各线路带宽使用率</template>
                <div ref="usageChart" class="chart-box" style="height:280px"></div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <!-- 连接数 + 延迟/丢包 -->
          <el-row :gutter="16">
            <el-col :xs="24" :md="12">
              <SectionCard><template #header>连接数走势</template>
                <div ref="connChart" class="chart-box" style="height:220px"></div>
              </SectionCard>
            </el-col>
            <el-col :xs="24" :md="12">
              <SectionCard><template #header>延迟 & 丢包率</template>
                <div ref="latencyChart" class="chart-box" style="height:220px"></div>
              </SectionCard>
            </el-col>
          </el-row>
      
          <!-- CPU/内存 -->
          <el-row :gutter="16">
            <el-col :xs="24" :md="12">
              <SectionCard><template #header>CPU 使用率</template>
                <div ref="cpuChart" class="chart-box" style="height:200px"></div>
              </SectionCard>
            </el-col>
            <el-col :xs="24" :md="12">
              <SectionCard><template #header>内存使用</template>
                <div ref="memChart" class="chart-box" style="height:200px"></div>
              </SectionCard>
            </el-col>
          </el-row>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'

const trafficChart = ref(null)
const usageChart = ref(null)
const connChart = ref(null)
const latencyChart = ref(null)
const cpuChart = ref(null)
const memChart = ref(null)

let charts = []
let observers = []
let timer = null
const MAX_POINTS = 30

const metrics = reactive({
  totalRx: '0 Mbps', totalTx: '0 Mbps', connections: 0,
  avgLatency: 0, lossRate: 0, cpuLoad: 0
})

const timeLabels = []
const wan1Rx = [], wan1Tx = [], wan2Rx = [], wan2Tx = [], wan3Rx = [], wan3Tx = []
const connData = [], latencyData = [], lossData = [], cpuData = [], memData = []

function rand(min, max) { return Math.round((Math.random() * (max - min) + min) * 10) / 10 }
function timeStr() {
  const d = new Date()
  return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}:${String(d.getSeconds()).padStart(2,'0')}`
}

function pushData() {
  const t = timeStr()
  timeLabels.push(t)
  if (timeLabels.length > MAX_POINTS) timeLabels.shift()

  const r1 = rand(30, 60), t1 = rand(8, 18)
  const r2 = rand(20, 40), t2 = rand(5, 12)
  const r3 = rand(15, 35), t3 = rand(4, 10)
  wan1Rx.push(r1); wan1Tx.push(t1)
  wan2Rx.push(r2); wan2Tx.push(t2)
  wan3Rx.push(r3); wan3Tx.push(t3)
  ;[wan1Rx,wan1Tx,wan2Rx,wan2Tx,wan3Rx,wan3Tx].forEach(a => { if(a.length>MAX_POINTS) a.shift() })

  const conns = Math.round(rand(3200, 4200))
  connData.push(conns); if(connData.length>MAX_POINTS) connData.shift()

  const lat = rand(6, 20)
  latencyData.push(lat); if(latencyData.length>MAX_POINTS) latencyData.shift()

  const loss = rand(0, 1.5)
  lossData.push(loss); if(lossData.length>MAX_POINTS) lossData.shift()

  const cpu = rand(8, 25)
  cpuData.push(cpu); if(cpuData.length>MAX_POINTS) cpuData.shift()

  const mem = rand(22, 30)
  memData.push(mem); if(memData.length>MAX_POINTS) memData.shift()

  const totalR = r1 + r2 + r3
  const totalT = t1 + t2 + t3
  metrics.totalRx = totalR.toFixed(1) + ' Mbps'
  metrics.totalTx = totalT.toFixed(1) + ' Mbps'
  metrics.connections = conns
  metrics.avgLatency = lat
  metrics.lossRate = loss
  metrics.cpuLoad = cpu
}

function initCharts() {
  const tc = echarts.init(trafficChart.value)
  tc.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['wan1↓','wan1↑','wan2↓','wan2↑','wan3↓','wan3↑'], bottom: 0, type: 'scroll' },
    grid: { top: 10, right: 20, bottom: 40, left: 50, containLabel: false },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: { type: 'value', name: 'Mbps' },
    series: [
      { name: 'wan1↓', type: 'line', data: wan1Rx, smooth: true, showSymbol: false, areaStyle: { opacity: 0.1 }, lineStyle: { width: 2 } },
      { name: 'wan1↑', type: 'line', data: wan1Tx, smooth: true, showSymbol: false, lineStyle: { width: 1.5, type: 'dashed' } },
      { name: 'wan2↓', type: 'line', data: wan2Rx, smooth: true, showSymbol: false, areaStyle: { opacity: 0.1 }, lineStyle: { width: 2 } },
      { name: 'wan2↑', type: 'line', data: wan2Tx, smooth: true, showSymbol: false, lineStyle: { width: 1.5, type: 'dashed' } },
      { name: 'wan3↓', type: 'line', data: wan3Rx, smooth: true, showSymbol: false, areaStyle: { opacity: 0.1 }, lineStyle: { width: 2 } },
      { name: 'wan3↑', type: 'line', data: wan3Tx, smooth: true, showSymbol: false, lineStyle: { width: 1.5, type: 'dashed' } },
    ]
  })
  charts.push(tc)

  const uc = echarts.init(usageChart.value)
  uc.setOption({
    series: [
      { type: 'gauge', center: ['30%','55%'], radius: '65%', min: 0, max: 500, detail: { formatter: '{value}M', fontSize: 12 }, title: { text: 'wan1', offsetCenter: [0, '70%'] }, data: [{ value: 45, name: 'wan1' }], axisLine: { lineStyle: { width: 12 } } },
      { type: 'gauge', center: ['72%','55%'], radius: '65%', min: 0, max: 300, detail: { formatter: '{value}M', fontSize: 12 }, title: { text: 'wan2', offsetCenter: [0, '70%'] }, data: [{ value: 32, name: 'wan2' }], axisLine: { lineStyle: { width: 12 } } },
    ]
  })
  charts.push(uc)

  const cc = echarts.init(connChart.value)
  cc.setOption({
    tooltip: { trigger: 'axis' },
    grid: { top: 10, right: 20, bottom: 30, left: 55 },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: { type: 'value', name: '连接数' },
    series: [{ name: '连接数', type: 'line', data: connData, smooth: true, showSymbol: false, areaStyle: { opacity: 0.15, color: '#1677ff' }, lineStyle: { width: 2, color: '#1677ff' }, itemStyle: { color: '#1677ff' } }]
  })
  charts.push(cc)

  const lc = echarts.init(latencyChart.value)
  lc.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['延迟(ms)','丢包率(%)'], bottom: 0 },
    grid: { top: 10, right: 50, bottom: 35, left: 50 },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: [
      { type: 'value', name: 'ms', position: 'left' },
      { type: 'value', name: '%', position: 'right', max: 5 }
    ],
    series: [
      { name: '延迟(ms)', type: 'line', data: latencyData, smooth: true, showSymbol: false, lineStyle: { width: 2, color: '#faad14' }, itemStyle: { color: '#faad14' } },
      { name: '丢包率(%)', type: 'bar', yAxisIndex: 1, data: lossData, itemStyle: { color: '#ff4d4f', opacity: 0.6 } }
    ]
  })
  charts.push(lc)

  const cpuC = echarts.init(cpuChart.value)
  cpuC.setOption({
    tooltip: { trigger: 'axis' },
    grid: { top: 10, right: 20, bottom: 30, left: 45 },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: { type: 'value', name: '%', max: 100 },
    series: [{ name: 'CPU', type: 'line', data: cpuData, smooth: true, showSymbol: false, areaStyle: { opacity: 0.15, color: '#52c41a' }, lineStyle: { width: 2, color: '#52c41a' }, itemStyle: { color: '#52c41a' } }]
  })
  charts.push(cpuC)

  const memC = echarts.init(memChart.value)
  memC.setOption({
    tooltip: { trigger: 'axis' },
    grid: { top: 10, right: 20, bottom: 30, left: 45 },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: { type: 'value', name: '%', max: 100 },
    series: [{ name: '内存', type: 'line', data: memData, smooth: true, showSymbol: false, areaStyle: { opacity: 0.15, color: '#722ed1' }, lineStyle: { width: 2, color: '#722ed1' }, itemStyle: { color: '#722ed1' } }]
  })
  charts.push(memC)

  // ResizeObserver: 容器尺寸变化时自动 resize 图表
  const containers = [trafficChart, usageChart, connChart, latencyChart, cpuChart, memChart]
  containers.forEach((elRef, i) => {
    const ro = new ResizeObserver(() => { charts[i]?.resize() })
    ro.observe(elRef.value)
    observers.push(ro)
  })
}

function updateCharts() {
  pushData()
  charts[0]?.setOption({ xAxis: { data: timeLabels }, series: [{data:wan1Rx},{data:wan1Tx},{data:wan2Rx},{data:wan2Tx},{data:wan3Rx},{data:wan3Tx}] })
  charts[1]?.setOption({ series: [{ data: [{ value: Math.round(wan1Rx[wan1Rx.length-1]||45) }] }, { data: [{ value: Math.round(wan2Rx[wan2Rx.length-1]||32) }] }] })
  charts[2]?.setOption({ xAxis: { data: timeLabels }, series: [{ data: connData }] })
  charts[3]?.setOption({ xAxis: { data: timeLabels }, series: [{ data: latencyData }, { data: lossData }] })
  charts[4]?.setOption({ xAxis: { data: timeLabels }, series: [{ data: cpuData }] })
  charts[5]?.setOption({ xAxis: { data: timeLabels }, series: [{ data: memData }] })
}

onMounted(async () => {
  for (let i = 0; i < MAX_POINTS; i++) pushData()
  await nextTick()
  initCharts()
  timer = setInterval(updateCharts, 2000)
})

onUnmounted(() => {
  clearInterval(timer)
  observers.forEach(ro => ro.disconnect())
  charts.forEach(c => c.dispose())
  charts = []
  observers = []
})
</script>

<style scoped>
.metric-card { text-align: center; margin-bottom: var(--layout-section-gap); }
.metric-value { font-size: 20px; font-weight: 700; color: var(--lh-primary); }
.metric-label { font-size: 12px; color: #909399; margin-top: 4px; }
.status-warn { color: #ff4d4f ; }
.chart-box { width: 100%; }
</style>
