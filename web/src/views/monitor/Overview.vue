<template>
  <PageContainer>
    <PageHeader class="page-header"><h2>系统概览</h2><p>{{ BRAND.productName }}运行状态总览</p></PageHeader>
    <SectionCard class="page-section-frame" shadow="never" content-padding="none">
      <el-row :gutter="16">
            <el-col :xs="12" :sm="6"><SectionCard shadow="hover"><el-statistic title="系统运行时间" value="15天 8小时 32分" /></SectionCard></el-col>
            <el-col :xs="12" :sm="6"><SectionCard shadow="hover"><el-statistic title="CPU 使用率" value="12%" /></SectionCard></el-col>
            <el-col :xs="12" :sm="6"><SectionCard shadow="hover"><el-statistic title="内存使用" value="256MB / 1024MB" /></SectionCard></el-col>
            <el-col :xs="12" :sm="6"><SectionCard shadow="hover"><el-statistic title="活跃连接数" value="3,847" /></SectionCard></el-col>
          </el-row>
          <el-row :gutter="16">
            <el-col :xs="24" :sm="12">
              <SectionCard><template #header>系统信息</template>
                <el-descriptions :column="1" border>
                  <el-descriptions-item label="主机名">{{ BRAND.gatewayName }}</el-descriptions-item>
                  <el-descriptions-item label="系统">OpenWrt 23.05.3 r24012</el-descriptions-item>
                  <el-descriptions-item label="内核">Linux 5.15.150 x86_64</el-descriptions-item>
                  <el-descriptions-item label="架构">x86_64 / Intel i5-8250U</el-descriptions-item>
                  <el-descriptions-item label="固件版本">{{ BRAND.firmwareName }} V2.0.1-alpha</el-descriptions-item>
                </el-descriptions>
              </SectionCard>
            </el-col>
            <el-col :xs="24" :sm="12">
              <SectionCard><template #header>网络概况</template>
                <el-descriptions :column="1" border>
                  <el-descriptions-item label="WAN接口数">4</el-descriptions-item>
                  <el-descriptions-item label="在线线路">3 / 4</el-descriptions-item>
                  <el-descriptions-item label="LAN IP">192.168.1.1/24</el-descriptions-item>
                  <el-descriptions-item label="DHCP客户端">28</el-descriptions-item>
                  <el-descriptions-item label="DNS服务器">223.5.5.5, 119.29.29.29</el-descriptions-item>
                  <el-descriptions-item label="IPv6前缀">2408:8456:3a01::/48</el-descriptions-item>
                </el-descriptions>
              </SectionCard>
            </el-col>
          </el-row>
    </SectionCard>
  </PageContainer>
</template>

<script setup>
import BRAND from '../../config/brand.js'
</script>
