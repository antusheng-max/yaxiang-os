<template>
  <PageContainer>
    <PageHeader title="Diff" />
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard shadow="never">
            <template #header><span>配置差异对比</span></template>
            <el-form inline>
              <el-form-item label="配置文件">
                <el-select v-model="selectedFile">
                  <el-option v-for="f in files" :key="f" :label="f" :value="f" />
                </el-select>
              </el-form-item>
              <el-form-item><el-button type="primary" @click="showDiff = true">对比</el-button></el-form-item>
            </el-form>
            <div v-if="showDiff" class="diff-viewer">
              <pre>{{ diffContent }}</pre>
            </div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import { ref } from 'vue'

const files = ['/etc/config/network', '/etc/config/firewall', '/etc/config/dhcp', '/etc/config/wireguard']
const selectedFile = ref(files[0])
const showDiff = ref(true)

const diffContent = `--- /etc/config/network (运行中)
+++ /etc/config/network (待应用)

 config interface 'wan'
-    option proto 'dhcp'
+    option proto 'pppoe'
+    option username 'user003@gd'
+    option password '********'
     option device 'eth2'
     option mtu '1500'

 config interface 'wan3'
-    option proto 'static'
-    option ipaddr '172.16.0.10/24'
+    option proto 'pppoe'
+    option username 'vlan_user3@gd'
+    option password '********'
+    option device 'eth0.300'`
</script>

<style scoped>
.diff-viewer { background: #1e1e1e; border-radius: 8px; padding: 16px; overflow-x: auto; }
.diff-viewer pre { color: #d4d4d4; font-family: 'Courier New', monospace; font-size: 13px; margin: 0; white-space: pre-wrap; }
</style>
