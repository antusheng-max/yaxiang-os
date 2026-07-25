<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>系统日志</h2><p>系统运行日志（最近记录）</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <SectionCard>
            <template #header><div style="display:flex;justify-content:space-between;align-items:center"><span>系统日志</span><el-button size="small" @click="refresh">刷新</el-button></div></template>
            <div class="log-viewer"><pre>{{ logContent }}</pre></div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>
<script setup>
import { ElMessage } from 'element-plus'
const refresh = () => ElMessage.success('日志已刷新（Mock）')
const logContent = `Tue Jul 22 09:35:01 2026 daemon.info dnsmasq[2841]: DHCPREQUEST(br-lan) 192.168.1.101 aa:bb:cc:01:01:01
Tue Jul 22 09:35:01 2026 daemon.info dnsmasq[2841]: DHCPACK(br-lan) 192.168.1.101 aa:bb:cc:01:01:01 Office-PC-01
Tue Jul 22 09:34:58 2026 kern.info kernel: [1325698.123] br-lan: port 2(eth4) entered forwarding state
Tue Jul 22 09:34:55 2026 daemon.notice netifd: pppoe-wan1 (3012): PPPoE connection established
Tue Jul 22 09:34:55 2026 daemon.notice netifd: Interface 'wan1' is now up
Tue Jul 22 09:34:50 2026 daemon.info pppd[3012]: Connected to 00:11:22:33:44:55 via eth0
Tue Jul 22 09:34:45 2026 user.notice firewall: Reloading firewall due to interface change
Tue Jul 22 09:34:40 2026 daemon.warn netifd: pppoe-wan4 (3018): PPPoE timeout, retrying...
Tue Jul 22 09:34:35 2026 daemon.info dnsmasq[2841]: query[A] www.example.com from 192.168.1.101
Tue Jul 22 09:34:30 2026 cron.info crond[1523]: Job 'ntp_sync' started
Tue Jul 22 09:34:28 2026 daemon.notice netifd: Network device 'eth3' link is down`
</script>
<style scoped>
.log-viewer { max-height: 500px; overflow-y: auto; background: #1e1e1e; border-radius: 4px; padding: 12px; }
.log-viewer pre { color: #d4d4d4; font-size: 12px; line-height: 1.6; font-family: 'JetBrains Mono', monospace; white-space: pre-wrap; }
</style>
