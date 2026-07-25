<template>
  <PageContainer>
    <PageHeader title="固件升级" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>固件升级</span></template>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="当前版本">{{ BRAND.firmwareName }} V2.1.0 (r24001)</el-descriptions-item>
              <el-descriptions-item label="内核版本">Linux 6.1.82 x86_64</el-descriptions-item>
              <el-descriptions-item label="编译时间">2026-06-15</el-descriptions-item>
              <el-descriptions-item label="可用空间">180MB / 256MB</el-descriptions-item>
            </el-descriptions>
            <el-alert title="当前已是最新版本" type="success" :closable="false" />
            <el-divider content-position="left">手动升级</el-divider>
            <el-upload action="#" :auto-upload="false" :on-change="upload" drag>
              <el-icon style="font-size:40px;color:#409eff"><upload-filled /></el-icon>
              <div>将固件文件拖到此处，或<em>点击上传</em></div>
              <template #tip><div class="el-upload__tip">支持 .bin / .img / .sysupgrade 格式</div></template>
            </el-upload>
            <div>
              <el-checkbox v-model="keepConfig">保留配置</el-checkbox>
              <el-button type="danger" @click="flash" :disabled="!firmware">刷写固件</el-button>
            </div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import BRAND from '../../config/brand.js'

const keepConfig = ref(true)
const firmware = ref(null)

function upload(file) { firmware.value = file.name; ElMessage.success(`已选择: ${file.name}`) }
function flash() {
  ElMessageBox.confirm('确定要刷写固件吗？此操作不可逆！', '警告', { type: 'warning', confirmButtonText: '确认刷写' }).then(() => {
    ElMessage.info('固件刷写中，请勿断电...')
    setTimeout(() => ElMessage.success('固件刷写完成，设备即将重启'), 3000)
  }).catch(() => {})
}
</script>
