<template>
  <PageContainer>
    <PageHeader><h2>网络拓扑</h2>
    <p style="color:var(--el-text-color-secondary);font-size:13px">
      软路由三线拓扑：eth0(千兆)管理口 → 电脑主机, eth1(万兆) → 万兆交换机, eth2(万兆) → 服务器
    </p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <!-- 第一层：物理网口 -->
          <SectionCard shadow="never" class="layer-card">
            <template #header><span><strong>① 物理网口</strong> — 插了 3 根网线</span></template>
            <div class="port-row">
              <!-- eth0 千兆管理口 -->
              <div class="port-card port-green">
                <div class="port-led led-on" />
                <div class="port-title">eth0 <el-tag size="small" type="success">已连接</el-tag></div>
                <div class="port-info">速率: 1000M · 全双工</div>
                <div class="port-info">MAC: AA:BB:CC:DD:EE:01</div>
                <el-divider />
                <div class="port-detail">用途: <strong>管理电脑</strong></div>
                <div class="port-detail ipv4">管理 IP: 192.168.3.1/24</div>
                <div class="port-detail">DHCP: 192.168.3.100 - 149</div>
              </div>
      
              <!-- eth1 万兆交换机 -->
              <div class="port-card port-blue">
                <div class="port-led led-on" />
                <div class="port-title">eth1 <el-tag size="small" type="success">已连接</el-tag></div>
                <div class="port-info">速率: <strong>10000M</strong> · 全双工</div>
                <div class="port-info">MAC: AA:BB:CC:DD:EE:02</div>
                <div class="port-info">驱动: ixgbe (万兆网卡)</div>
                <el-divider />
                <div class="port-detail">用途: <strong>万兆交换机</strong></div>
                <div class="port-detail">VLAN: 100-109 (10 线拨号)</div>
              </div>
      
              <!-- eth2 万兆服务器 -->
              <div class="port-card port-orange">
                <div class="port-led led-on" />
                <div class="port-title">eth2 <el-tag size="small" type="success">已连接</el-tag></div>
                <div class="port-info">速率: <strong>10000M</strong> · 全双工</div>
                <div class="port-info">MAC: AA:BB:CC:DD:EE:03</div>
                <div class="port-info">驱动: ixgbe (万兆网卡)</div>
                <el-divider />
                <div class="port-detail">用途: <strong>服务器 (万兆直连)</strong></div>
                <div class="port-detail ipv4">LAN IP: 10.10.10.1/24</div>
                <div class="port-detail">DHCP: 10.10.10.10 - 29</div>
              </div>
      
              <!-- 未使用的端口 -->
              <div class="port-card port-off">
                <div class="port-led led-off" />
                <div class="port-title">eth3-5 <el-tag size="small" type="info">未连接</el-tag></div>
                <div class="port-info">预留端口，暂未使用</div>
              </div>
            </div>
          </SectionCard>
      
          <div class="flow-row">
            <div class="flow-group">
              <div class="flow-arrow">↓ 管理流量</div>
              <div class="flow-node">电脑主机 (192.168.3.x)<br/><small>浏览器打开 http://192.168.3.1 管理路由</small></div>
            </div>
            <div class="flow-group">
              <div class="flow-arrow">↓ WAN 流量</div>
              <div class="flow-node">万兆交换机<br/><small>VLAN 100-109 / 10 线 PPPoE 拨号</small></div>
            </div>
            <div class="flow-group">
              <div class="flow-arrow">↓ 服务器流量</div>
              <div class="flow-node">服务器 (10.10.10.x)<br/><small>万兆直连，全速访问</small></div>
            </div>
          </div>
      
          <!-- 第二层：逻辑接口 -->
          <SectionCard shadow="never" class="layer-card">
            <template #header><span><strong>② 逻辑接口</strong> — 端口绑定与路由</span></template>
            <div class="logic-row">
              <SectionCard shadow="hover" class="logic-card">
                <div class="logic-title"><el-tag type="success" effect="dark" size="small">LAN</el-tag> 管理网络</div>
                <div class="logic-info">eth0 · 192.168.3.1/24</div>
                <div class="logic-info">DHCP: 192.168.3.100-149</div>
                <div class="logic-info">DNS: 192.168.3.1</div>
                <div class="logic-arrow">→ 电脑主机可管理路由</div>
              </SectionCard>
      
              <SectionCard shadow="hover" class="logic-card logic-wan">
                <div class="logic-title"><el-tag type="primary" effect="dark" size="small">WAN</el-tag> 外网出口 (eth1 聚合)</div>
                <div class="logic-info">PPPoE × 10 线 · VLAN 100-109</div>
                <div class="logic-info">聚合带宽: 10 × 100Mbps</div>
                <div class="logic-info">负载均衡: 故障自动切换</div>
                <div class="logic-arrow">→ 所有 LAN 共享出口</div>
              </SectionCard>
      
              <SectionCard shadow="hover" class="logic-card logic-server">
                <div class="logic-title"><el-tag type="warning" effect="dark" size="small">LAN</el-tag> 服务器网络</div>
                <div class="logic-info">eth2 · 10.10.10.1/24</div>
                <div class="logic-info">DHCP: 10.10.10.10-29</div>
                <div class="logic-info">DNS: 10.10.10.1 / 223.5.5.5</div>
                <div class="logic-arrow">→ 服务器万兆直连路由</div>
              </SectionCard>
            </div>
          </SectionCard>
      
          <!-- 第三层：数据流向 -->
          <SectionCard shadow="never" class="layer-card">
            <template #header><span><strong>③ 数据流示意</strong></span></template>
            <div class="flow-diagram">
              <pre style="font-family:'SF Mono','Fira Code',monospace;font-size:13px;line-height:1.8">
      电脑主机 (192.168.3.100)
        │ 管理流量
        ▼
      eth0 ─── LAN: 192.168.3.1/24
        │
        ▼
      {{ BRAND.gatewayName }} ─── NAT / 路由转发
        │                        │
        ▼                        ▼
      eth1 (万兆)              eth2 (万兆)
        │                        │
        ▼                        ▼
      万兆交换机                服务器 (10.10.10.10)
        │
        ├── VLAN 100 PPPoE user001
        ├── VLAN 101 PPPoE user002
        ├── ...
        └── VLAN 109 PPPoE user010
        │
        ▼
      Internet (多线聚合)
              </pre>
            </div>
          </SectionCard>
    </SectionCard>
  </PageContainer>
</template>

<style scoped>
.layer-card { margin-bottom: 8px; }
.port-row { display: flex; gap: 14px; flex-wrap: wrap; }
.port-card { width: 220px; border: 1px solid var(--el-border-color-light); border-radius: 8px; padding: 14px; flex: 1; min-width: 200px; }
.port-green { background: #f0f9eb; }
.port-blue { background: #ecf5ff; }
.port-orange { background: #fdf6ec; }
.port-off { background: var(--el-fill-color-lighter); opacity: 0.6; }
.port-led { width: 10px; height: 10px; border-radius: 50%; margin-bottom: 6px; }
.led-on { background: #67c23a; box-shadow: 0 0 6px #67c23a; }
.led-off { background: #c0c4cc; }
.port-title { font-weight: 700; font-size: 15px; display: flex; align-items: center; gap: 8px; }
.port-info { font-size: 12px; color: var(--el-text-color-regular); padding: 1px 0; }
.port-detail { font-size: 12px; padding: 2px 0; }
.port-detail.ipv4 { color: #409eff; font-weight: 500; }

.flow-row { display: flex; gap: 16px; justify-content: center; padding: 12px 0; flex-wrap: wrap; }
.flow-group { text-align: center; }
.flow-arrow { font-size: 13px; color: var(--el-text-color-secondary); padding: 4px 0; font-weight: 500; }
.flow-node { background: var(--el-fill-color-lighter); border-radius: 8px; padding: 12px 18px; font-size: 13px; border: 1px solid var(--el-border-color-light); min-width: 180px; }

.logic-row { display: flex; gap: 14px; flex-wrap: wrap; }
.logic-card { flex: 1; min-width: 220px; }
.logic-title { font-weight: 600; font-size: 14px; display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.logic-info { font-size: 12px; padding: 2px 0; color: var(--el-text-color-regular); }
.logic-arrow { margin-top: 8px; font-size: 12px; color: #409eff; font-weight: 500; }
.logic-wan :deep(.el-card__body) { background: #ecf5ff; }
.logic-server :deep(.el-card__body) { background: #fdf6ec; }

.flow-diagram { max-width: 100%; overflow-x: auto; }
.flow-diagram pre { background: #1a1a2e; color: #d4d4e0; padding: 16px 20px; border-radius: 8px; }
</style>
<script setup>
import BRAND from '../../config/brand.js'
</script>
