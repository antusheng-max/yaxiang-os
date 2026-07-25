<template>
  <PageContainer>
    <PageHeader title="系统设置" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>系统设置</span></template>
            <el-form :model="config" label-width="140px">
              <el-form-item label="主机名"><el-input v-model="config.hostname" /></el-form-item>
              <el-form-item label="时区">
                <el-select v-model="config.timezone">
                  <el-option label="Asia/Shanghai (UTC+8)" value="CST-8" />
                  <el-option label="Asia/Tokyo (UTC+9)" value="JST-9" />
                  <el-option label="UTC" value="UTC0" />
                </el-select>
              </el-form-item>
              <el-form-item label="NTP服务器"><el-input v-model="config.ntp" /></el-form-item>
              <el-form-item label="系统语言">
                <el-select v-model="config.lang">
                  <el-option label="简体中文" value="zh_cn" />
                  <el-option label="English" value="en" />
                </el-select>
              </el-form-item>
              <el-form-item label="Web端口"><el-input-number v-model="config.webPort" :min="1" :max="65535" /></el-form-item>
              <el-form-item label="HTTPS">
                <el-switch v-model="config.https" />
              </el-form-item>
              <el-form-item><el-button type="primary" @click="ElMessage.success('保存成功')">保存并应用</el-button></el-form-item>
            </el-form>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { reactive } from 'vue'
import { ElMessage } from 'element-plus'
import BRAND from '../../config/brand.js'

const config = reactive({
  hostname: BRAND.gatewayName,
  timezone: 'CST-8',
  ntp: 'ntp.aliyun.com time.windows.com',
  lang: 'zh_cn',
  webPort: 80,
  https: false,
})
</script>
