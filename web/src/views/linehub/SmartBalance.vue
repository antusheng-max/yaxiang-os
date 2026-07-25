<template>
  <PageContainer>
    <PageHeader title="SmartBalance" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>智能负载均衡</span></template>
            <el-form :model="config" label-width="140px">
              <el-form-item label="均衡算法">
                <el-select v-model="config.algorithm">
                  <el-option label="智能加权(推荐)" value="smart_weight" />
                  <el-option label="最小延迟" value="min_latency" />
                  <el-option label="带宽比例" value="bandwidth_ratio" />
                  <el-option label="最少连接" value="least_conn" />
                </el-select>
              </el-form-item>
              <el-form-item label="自动权重调整"><el-switch v-model="config.autoWeight" /></el-form-item>
              <el-form-item label="连接保持"><el-switch v-model="config.sticky" /></el-form-item>
              <el-form-item label="调整间隔(秒)"><el-input-number v-model="config.interval" :min="10" :max="300" /></el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存</el-button></el-form-item>
            </el-form>
          </SectionCard>
          <StandardTable layout-mode="fill" :data="lines" border stripe size="small">
            <el-table-column prop="line" label="线路" />
            <el-table-column prop="bandwidth" label="带宽" />
            <el-table-column prop="weight" label="当前权重" />
            <el-table-column prop="connections" label="连接数" />
            <el-table-column prop="throughput" label="吞吐量" />
            <el-table-column prop="ratio" label="流量占比">
              <template #default="{ row }"><el-progress :percentage="row.ratio" :stroke-width="14" /></template>
            </el-table-column>
          </StandardTable>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { usePersistentRef } from '../../composables/usePersistentRef.js'
import { ElMessage } from 'element-plus'

const config = reactive({ algorithm: 'smart_weight', autoWeight: true, sticky: true, interval: 30 })
const lines = usePersistentRef('linehub:smartbalance', [
  { line: '电信主线', bandwidth: '500M', weight: 35, connections: 3256, throughput: '285 Mbps', ratio: 42 },
  { line: '联通备线', bandwidth: '300M', weight: 20, connections: 1890, throughput: '128 Mbps', ratio: 22 },
  { line: '电信VLAN', bandwidth: '500M', weight: 35, connections: 2870, throughput: '256 Mbps', ratio: 30 },
  { line: '企业专线', bandwidth: '100M', weight: 10, connections: 456, throughput: '45 Mbps', ratio: 6 },
])
</script>
