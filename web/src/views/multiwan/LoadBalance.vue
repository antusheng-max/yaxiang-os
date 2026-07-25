<template>
  <PageContainer>
    <PageHeader title="LoadBalance" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>负载均衡策略</span></template>
            <el-form :model="config" label-width="120px">
              <el-form-item label="均衡模式">
                <el-select v-model="config.mode">
                  <el-option label="加权轮询(WRR)" value="wrr" />
                  <el-option label="最小连接数" value="least_conn" />
                  <el-option label="源地址哈希" value="src_hash" />
                  <el-option label="带宽比例" value="bandwidth" />
                </el-select>
              </el-form-item>
              <el-form-item label="连接跟踪">
                <el-switch v-model="config.conntrack" />
              </el-form-item>
              <el-form-item label="粘性会话">
                <el-switch v-model="config.sticky" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="ElMessage.success('保存成功')">保存配置</el-button>
              </el-form-item>
            </el-form>
          </SectionCard>
          <CrudTable
            title="线路权重分配"
            :columns="columns"
            :data="data"
            :form-fields="formFields"
            @add="(f) => { data.push(f); ElMessage.success('添加成功') }"
            @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
            @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
          />
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref, reactive } from 'vue'
import CrudTable from '../../components/CrudTable.vue'
import { ElMessage } from 'element-plus'

const config = reactive({ mode: 'wrr', conntrack: true, sticky: true })

const columns = [
  { prop: 'line', label: '线路', width: 120 },
  { prop: 'interface', label: '接口', width: 80 },
  { prop: 'weight', label: '权重', width: 80 },
  { prop: 'maxConn', label: '最大连接', width: 100 },
  { prop: 'currentConn', label: '当前连接', width: 100 },
  { prop: 'ratio', label: '流量占比', type: 'progress', width: 150 },
]
const formFields = [
  { prop: 'line', label: '线路', type: 'select', options: ['电信主线', '联通备线', '电信VLAN', '专线'] },
  { prop: 'interface', label: '接口', type: 'select', options: ['wan', 'wan2', 'wan3', 'wan4'] },
  { prop: 'weight', label: '权重', type: 'input' },
  { prop: 'maxConn', label: '最大连接数', type: 'input' },
]
let data = ref([
  { line: '电信主线', interface: 'wan', weight: '5', maxConn: '10000', currentConn: '3256', ratio: 42 },
  { line: '联通备线', interface: 'wan2', weight: '3', maxConn: '6000', currentConn: '1890', ratio: 25 },
  { line: '电信VLAN', interface: 'wan3', weight: '5', maxConn: '10000', currentConn: '2870', ratio: 28 },
  { line: '专线', interface: 'wan4', weight: '2', maxConn: '2000', currentConn: '456', ratio: 5 },
])
</script>
