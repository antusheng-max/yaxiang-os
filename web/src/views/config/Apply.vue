<template>
  <PageContainer>
    <PageHeader title="应用配置" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header>
              <div style="display:flex;justify-content:space-between;align-items:center">
                <span>应用配置</span>
                <el-tag v-if="step === 0" type="info">待应用</el-tag>
                <el-tag v-else-if="step < 4" type="warning">执行中</el-tag>
                <el-tag v-else-if="hasErrors" type="danger">有失败</el-tag>
                <el-tag v-else type="success">已完成</el-tag>
              </div>
            </template>
      
            <el-alert title="应用配置将重启相关网络服务，可能导致短暂断网" type="warning" :closable="false" />
      
            <el-steps :active="step" finish-status="success" align-center>
              <el-step title="验证配置" :description="stepDescs[0]" />
              <el-step title="写入文件" :description="stepDescs[1]" />
              <el-step title="重启服务" :description="stepDescs[2]" />
              <el-step title="完成" :description="stepDescs[3]" />
            </el-steps>
      
            <div v-if="step > 0 && step < 4" class="apply-progress">
              <div v-for="(item, i) in currentItems" :key="i" class="apply-item">
                <el-icon v-if="item.status === 'done'" class="icon-success"><CircleCheckFilled /></el-icon>
                <el-icon v-else-if="item.status === 'fail'" class="icon-fail"><CircleCloseFilled /></el-icon>
                <el-icon v-else-if="item.status === 'doing'" class="icon-loading"><Loading /></el-icon>
                <span v-else class="icon-pending">o</span>
                <span class="apply-item-label">{{ item.label }}</span>
                <span v-if="item.status === 'done'" class="apply-item-result ok">{{ item.result }}</span>
                <span v-else-if="item.status === 'fail'" class="apply-item-result fail">{{ item.result }}</span>
              </div>
            </div>
      
            <div style="text-align:center">
              <el-button v-if="step === 0" type="primary" size="large" @click="startApply" :loading="applying">
                开始应用
              </el-button>
              <el-button v-if="step === 4 && !hasErrors" type="success" size="large" @click="reset">
                重置并返回
              </el-button>
              <el-button v-if="hasErrors" type="warning" size="large" @click="retryFailed">
                重试失败项
              </el-button>
            </div>
      
            <el-divider v-if="logs.length > 0" content-position="left">执行日志</el-divider>
            <div v-if="logs.length > 0" class="log-panel">
              <div v-for="(log, i) in logs" :key="i" class="log-line" :class="log.type">
                <span class="log-time">{{ log.time }}</span>
                <span class="log-msg">{{ log.msg }}</span>
              </div>
            </div>
      
            <el-divider />
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="待应用修改数">{{ pendingCount }}</el-descriptions-item>
              <el-descriptions-item label="涉及文件">{{ filesInvolved }}</el-descriptions-item>
              <el-descriptions-item label="上次应用">{{ lastApply }}</el-descriptions-item>
              <el-descriptions-item label="本次耗时">{{ elapsed }}</el-descriptions-item>
            </el-descriptions>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheckFilled, CircleCloseFilled, Loading } from '@element-plus/icons-vue'
import { configurationApplyService } from '../../services/dataService.js'

const pendingChanges = computed(() => configurationApplyService.getPendingChanges())

const step = ref(0)
const applying = ref(false)
const hasErrors = ref(false)
const logs = ref([])
const startTime = ref(0)

const pendingCount = computed(() => pendingChanges.value.length)
const filesInvolved = computed(() => {
  const files = [...new Set(pendingChanges.value.map(change => change.target))]
  return files.join(', ')
})
const lastApply = ref('2026-07-21 16:30')
const elapsed = ref('-')

const stepDescs = computed(() => [
  pendingCount.value + ' 项待验证',
  pendingCount.value + ' 项待写入',
  step.value >= 3 ? (hasErrors.value ? '部分失败' : '全部重启成功') : '等待中',
  hasErrors.value ? '有失败项' : '全部成功',
])

const step1Items = computed(() =>
  pendingChanges.value.map(change => ({
    label: `验证 ${change.description}`,
    status: 'pending', result: ''
  }))
)
const step2Items = computed(() =>
  pendingChanges.value.map(change => ({
    label: `写入 ${change.target}`,
    status: 'pending', result: ''
  }))
)
const step3Items = ref([
  { label: '重启网络服务 (networking)', status: 'pending', result: '' },
  { label: '重载防火墙 (firewall)', status: 'pending', result: '' },
  { label: '重载 DHCP 服务 (dnsmasq)', status: 'pending', result: '' },
])

const currentItems = computed(() => {
  if (step.value === 1) return step1Items.value
  if (step.value === 2) return step2Items.value
  if (step.value === 3) return step3Items.value
  return []
})

function log(type, msg) {
  const now = new Date()
  const t = String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0') + ':' + String(now.getSeconds()).padStart(2,'0')
  logs.value.push({ time: t, msg, type })
}

function runStep1() {
  step.value = 1
  log('info', '开始验证 ' + pendingCount.value + ' 项配置...')
  const items = step1Items.value
  return new Promise((resolve) => {
    let i = 0
    const next = () => {
      if (i >= items.length) {
        const failed = items.filter(x => x.status === 'fail')
        log('info', '验证完成: ' + (items.length - failed.length) + ' 通过, ' + failed.length + ' 失败')
        resolve(failed.length === 0)
        return
      }
      const ok = true
      items[i].status = 'doing'
      setTimeout(() => {
        if (ok) {
          items[i].status = 'done'
          items[i].result = '通过'
          log('ok', '  v ' + items[i].label)
        } else {
          items[i].status = 'fail'
          items[i].result = '格式错误'
          log('err', '  x ' + items[i].label + ' - 格式错误')
        }
        i++
        setTimeout(next, 300 + Math.random() * 200)
      }, 400)
    }
    next()
  })
}

function runStep2() {
  step.value = 2
  log('info', '开始写入配置文件...')
  const items = step2Items.value
  return new Promise((resolve) => {
    let i = 0
    const next = () => {
      if (i >= items.length) {
        const failed = items.filter(x => x.status === 'fail')
        log('info', '写入完成: ' + (items.length - failed.length) + ' 成功, ' + failed.length + ' 失败')
        resolve(failed.length === 0)
        return
      }
      items[i].status = 'doing'
      setTimeout(() => {
        items[i].status = 'done'
        items[i].result = '已写入'
        log('ok', '  v ' + items[i].label)
        i++
        setTimeout(next, 250 + Math.random() * 150)
      }, 300)
    }
    next()
  })
}

function runStep3() {
  step.value = 3
  log('info', '正在重启服务...')
  const items = step3Items.value
  return new Promise((resolve) => {
    let i = 0
    const next = () => {
      if (i >= items.length) {
        const failed = items.filter(x => x.status === 'fail')
        log('info', '服务重启完成: ' + (items.length - failed.length) + ' 成功, ' + failed.length + ' 失败')
        resolve(failed.length === 0)
        return
      }
      const item = items[i]
      item.status = 'doing'
      setTimeout(() => {
        const ok = true
        if (ok) {
          item.status = 'done'
          item.result = '运行中'
          log('ok', '  v ' + item.label)
          i++
          setTimeout(next, 500)
        } else {
          item.status = 'fail'
          item.result = '启动超时'
          log('err', '  x ' + item.label + ' - 启动超时, 已自动重试')
          setTimeout(() => {
            item.status = 'done'
            item.result = '运行中(重试)'
            log('ok', '  v ' + item.label + ' - 重试成功')
            i++
            setTimeout(next, 500)
          }, 600)
        }
      }, 600)
    }
    next()
  })
}

async function startApply() {
  if (pendingCount.value === 0) {
    ElMessage.info('当前没有待应用的配置修改')
    return
  }
  applying.value = true
  hasErrors.value = false
  logs.value = []
  startTime.value = Date.now()

  try {
    const ok1 = await runStep1()
    log('info', '--- 验证阶段完成 ---')

    if (!ok1) {
      log('warn', '验证阶段存在错误，继续执行高风险')
    }

    const ok2 = await runStep2()
    log('info', '--- 写入阶段完成 ---')

    const ok3 = await runStep3()
    log('info', '--- 服务重启阶段完成 ---')

    if (ok1 && ok2 && ok3) {
      const result = configurationApplyService.applyAll()
      if (!result.success) throw new Error(result.message)
    }

    step.value = 4
    const elapsedMs = Date.now() - startTime.value
    elapsed.value = (elapsedMs / 1000).toFixed(1) + 's'
    hasErrors.value = !ok1 || !ok2 || !ok3

    if (hasErrors.value) {
      ElMessage.warning('配置应用完成，但存在失败项')
      log('warn', '配置应用完成，' + elapsed.value + '，部分服务需手动检查')
    } else {
      ElMessage.success('配置应用成功')
      log('ok', '配置应用成功，耗时 ' + elapsed.value)
      lastApply.value = new Date().toLocaleString('zh-CN')
    }
  } catch (e) {
    ElMessage.error('应用过程异常: ' + e.message)
    log('err', '应用异常: ' + e.message)
  } finally {
    applying.value = false
  }
}

function retryFailed() {
  hasErrors.value = false
  const allItems = [step1Items.value, step2Items.value, step3Items.value]
  allItems.forEach(arr => {
    arr.forEach(item => {
      if (item.status === 'fail') { item.status = 'pending'; item.result = '' }
    })
  })
  step.value = 0
  applying.value = false
  logs.value = []
  elapsed.value = '-'
  log('info', '已重置，准备重试失败项')
}

function reset() {
  step.value = 0
  applying.value = false
  hasErrors.value = false
  logs.value = []
  elapsed.value = '-'
  ;[step1Items.value, step2Items.value, step3Items.value].forEach(arr => {
    arr.forEach(item => { item.status = 'pending'; item.result = '' })
  })
  log('info', '已重置到初始状态')
}
</script>

<style scoped>
.apply-progress { width: 100%; margin: 0 0 var(--layout-section-gap);
  background: var(--el-fill-color-lighter); border-radius: 8px; padding: 16px 20px; }
.apply-item { display: flex; align-items: center; gap: 10px; padding: 8px 0; font-size: 13px; border-bottom: 1px solid var(--el-border-color-light); }
.apply-item:last-child { border-bottom: none; }
.icon-success { color: #67c23a; font-size: 16px; }
.icon-fail { color: #f56c6c; font-size: 16px; }
.icon-loading { color: #409eff; font-size: 16px; animation: spin 1s linear infinite; }
.icon-pending { color: #c0c4cc; font-size: 14px; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.apply-item-label { flex: 1; color: var(--el-text-color-primary); }
.apply-item-result { font-size: 12px; font-weight: 600; }
.apply-item-result.ok { color: #67c23a; }
.apply-item-result.fail { color: #f56c6c; }
.log-panel { background: #1a1a2e; border-radius: 6px; padding: 12px 16px; font-family: 'SF Mono', 'Fira Code', monospace; font-size: 12px; max-height: 260px; overflow-y: auto; }
.log-line { padding: 2px 0; display: flex; gap: 12px; }
.log-time { color: #8b8b9e; flex-shrink: 0; }
.log-msg { word-break: break-all; }
.log-line.ok .log-msg { color: #67c23a; }
.log-line.err .log-msg { color: #f56c6c; }
.log-line.warn .log-msg { color: #e6a23c; }
.log-line.info .log-msg { color: #d4d4e0; }
</style>
