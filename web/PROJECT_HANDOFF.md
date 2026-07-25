# 亚象网络操作系统 — 项目交接文档

## 一、项目定位

亚象网络操作系统是一个基于 OpenWrt/LuCI 功能全覆盖的企业级路由器管理 UI 原型。所有数据为 Mock，不执行真实系统操作。目标是作为产品原型验证交互逻辑和页面完整性。

## 二、技术栈

- Vue 3 (Composition API, `<script setup>`)
- Vite 5（注意：Vite 7/8 的 rolldown 原生模块在部分环境不兼容，必须用 Vite 5）
- Element Plus（UI 组件库）
- Vue Router 4（Hash 模式 `createWebHashHistory`，适配静态部署）
- ECharts 5（实时监控图表）
- 无后端，纯前端静态站点

## 三、服务器信息

- IP: 8.218.23.229
- SSH: root（端口22；密码仅通过安全渠道提供，禁止写入仓库）
- 项目源码: `/root/LineHub OS V2开发/`
- 线上预览: Nginx 端口 8080，静态文件在 `/var/www/linehub-os/`
- 部署方式: 本地 `npm run build` → 将 `dist/` 目录内容上传到 `/var/www/linehub-os/` → `nginx -s reload`

## 四、目录结构

```
/root/LineHub OS V2开发/
├── index.html                    # 入口HTML（zh-CN, viewport, title）
├── vite.config.js                # Vite配置
├── package.json                  # 依赖（vue3, element-plus, echarts, vue-router, vite5）
├── src/
│   ├── main.js                   # 注册 ElementPlus + 全部图标 + router + global.css
│   ├── App.vue                   # 仅 <router-view />
│   ├── styles/global.css         # 蓝白主题变量 + Element Plus覆写 + 响应式断点
│   ├── router/index.js           # 全部路由（~62条），Hash模式，懒加载
│   ├── layout/MainLayout.vue     # 主布局：侧边栏(10个el-sub-menu) + 顶栏 + 移动端抽屉
│   ├── components/CrudTable.vue  # 核心可复用CRUD组件
│   └── views/                    # 62个页面，按模块分目录
│       ├── monitor/              # 运行监控（7页）
│       ├── network/              # 网络配置（10页）
│       ├── multiwan/             # 多WAN管理（5页）
│       ├── firewall/             # 防火墙（6页）
│       ├── vpn/                  # VPN（3页）
│       ├── services/             # 服务（5页）
│       ├── system/               # 系统管理（10页）
│       ├── config/               # 配置中心（5页）
│       ├── plugins/              # 插件中心（1页）
│       └── linehub/              # 亚象扩展（内部兼容目录名，10页）
```

## 五、核心组件：CrudTable.vue

这是整个项目最核心的可复用组件，所有配置类页面都基于它。

### Props:
```js
{
  title: String,           // 表格标题（显示在左上角，右侧有"添加"按钮）
  columns: Array,          // 列定义 [{ prop, label, width, type, tagType }]
  data: Array,             // 表格数据（直接传ref数组）
  formFields: Array,       // 表单字段 [{ prop, label, type, options, required }]
  extraButtons: Array,     // 额外操作按钮 [{ label, type, handler(row) }]
}
```

### Events:
```js
@add(formData)             // 新增时触发，formData为表单数据对象
@edit(row, formData)       // 编辑时触发，row为原行数据，formData为新值
@delete(row)               // 删除确认后触发
```

### columns 列类型:
- 默认: 纯文本
- `type: 'tag'`: 显示为 el-tag，支持 `tagType: (val) => 'success'|'danger'|...` 自定义颜色
- `type: 'switch'`: 显示为 el-switch
- `type: 'progress'`: 显示为 el-progress 进度条

### formFields 字段类型:
- `type: 'input'`: 文本输入
- `type: 'select'`: 下拉选择（options为字符串数组）
- `type: 'textarea'`: 多行文本

### 移动端适配:
- 窗口 < 500px 时对话框自动全屏
- 表格自带横向滚动

### 典型页面用法:
```vue
<template>
  <div class="page-container">
    <CrudTable
      title="物理网口管理"
      :columns="columns"
      :data="data"
      :form-fields="formFields"
      @add="(f) => { data.push({...f, status:'未连接'}); ElMessage.success('添加成功') }"
      @edit="(r,f) => { Object.assign(r,f); ElMessage.success('修改成功') }"
      @delete="(r) => { data = data.filter(i=>i!==r); ElMessage.success('删除成功') }"
    />
  </div>
</template>
```

## 六、关键设计决策

### 1. WAN管理页面（最复杂的页面）
路径: `src/views/network/Wan.vue`

合并了原来的 PPPoE拨号、VLAN+PPPoE拨号、单线多拨 三个功能为一个页面：
- 每个WAN连接选择连接方式: DHCP / 静态IP / PPPoE拨号 / VLAN虚拟拨号
- PPPoE拨号: 每个物理口最多8个拨号会话（账号+密码）
- VLAN虚拟拨号: 每个会话 = VLAN ID + 账号 + 密码，设备自动命名为 `ethX.VID`
- 每个WAN卡片内嵌运行时状态（IP/网关/DNS/延迟/丢包/速率）
- 每个拨号会话可独立重拨（模拟2秒后成功）

### 2. 配置状态 vs 运行时状态分离
- 配置页面（CrudTable）: 可增删改，代表"待应用的配置"
- 监控页面（monitor/）: 只读，代表"当前运行状态"
- 配置中心（config/）: 展示待应用修改、差异对比、应用/回滚流程

### 3. 实时监控页面
路径: `src/views/monitor/Realtime.vue`

- ECharts 图表，2秒 setInterval 刷新
- 30点滚动窗口
- 6个图表: WAN流量走势(6条线)、带宽仪表盘、连接数、延迟+丢包双轴、CPU、内存
- 使用 ResizeObserver 监听容器尺寸变化自动 resize（解决移动端紧缩bug）
- 响应式分栏: `:xs="24" :md="16/8/12"`

### 4. 移动端适配
- MainLayout: < 768px 侧边栏变 fixed 抽屉 + 遮罩层
- CrudTable 对话框: < 500px 全屏
- 全局CSS: el-descriptions 横向滚动、inline表单竖排、el-col 全宽
- 图表: ResizeObserver + 响应式 el-col

### 5. 路由
- Hash模式（`createWebHashHistory`），适配 Nginx 静态部署无需配置 try_files
- 全部懒加载 `() => import(...)`
- 路由 name 为中文，直接用作面包屑和移动端标题

## 七、主题与样式

蓝白主题，CSS变量定义在 `global.css`:
```css
--lh-primary: #1677ff;
--lh-primary-light: #e6f4ff;
--lh-bg: #f5f7fa;
--lh-border: #e4e7ed;
```
- 侧边栏白底，表头浅蓝 `#f0f5ff`
- 全中文界面
- Element Plus 默认主题 + 少量覆写

## 八、页面完整清单（62页）

| 模块 | 页面 |
|------|------|
| 运行监控 | 系统概览、实时监控(ECharts)、网络状态、接口状态、PPPoE状态、DHCP租约、系统日志 |
| 网络配置 | 物理网口、网络设备、网络接口、WAN管理(合并版)、LAN管理、DHCP/DNS、IPv6、静态路由、路由规则、网络诊断 |
| 多WAN管理 | 线路管理、负载均衡、健康检查、故障切换、分流策略 |
| 防火墙 | 区域、区域转发、端口转发、NAT规则、流量规则、IP集合 |
| VPN | WireGuard、OpenVPN、隧道管理 |
| 服务 | 动态DNS、UPnP、QoS/SQM、Wake on LAN、服务管理 |
| 系统管理 | 系统设置、用户权限、SSH、软件包、启动项、定时任务、挂载、备份恢复、固件升级、重启关机 |
| 配置中心 | 待应用修改、配置差异、应用配置(步骤动画)、回滚、快照 |
| 插件中心 | 插件管理(卡片式) |
| 亚象扩展 | 线路池、PPPoE多拨(批量)、VLAN线路、IPv4出口、IPv6前缀、健康检测、智能负载均衡、故障自动切换、策略分流、服务器出口 |

## 九、已删除/合并的功能

- ~~VLAN管理（独立页面）~~ → 合并到 WAN管理的"VLAN虚拟拨号"连接方式中
- ~~物理PPPoE多拨（独立导航）~~ → 合并到 WAN管理 + 亚象扩展/PPPoE多拨管理
- ~~VLAN PPPoE多拨（独立导航）~~ → 同上

## 十、开发命令

```bash
cd "/root/LineHub OS V2开发"
npm run dev          # 开发模式 (localhost:5173)
npm run dev -- --host  # 外部可访问
npm run build        # 构建到 dist/
```

部署到预览:
```bash
rm -rf /var/www/linehub-os/*
cp -r dist/* /var/www/linehub-os/
nginx -s reload
```

## 十一、注意事项

1. **Vite 版本必须为 5**，package.json 中已锁定 `vite@5`，不要升级到 7/8（rolldown 原生模块兼容问题）
2. CrudTable 的 `data` prop 直接传 ref 数组，组件内部不复制数据，页面自行管理增删
3. 所有 Mock 数据写在各页面的 `<script setup>` 中，无统一数据层
4. 新增页面需要：创建 .vue 文件 → 在 router/index.js 添加路由 → 在 MainLayout.vue 添加菜单项
5. 线上预览通过 Nginx 8080 端口提供，配置文件在 `/etc/nginx/conf.d/` 或 `sites-enabled/`
