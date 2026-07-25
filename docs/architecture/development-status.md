# LineHub OS 开发状态

## 当前分支

`feature/ui-v5-rebuild`

## 当前已经完成

- LineHub OS 项目骨架
- 现代 LuCI 阶段1结构
- POSIX Shell/AWK 正式 UCI 校验器
- fixtures 和单元测试
- 本地 preview 管理界面
- 面向本轮验收的 12 个一级功能入口和响应式视觉层
- 独立策略路由与端口映射页面
- 进程内安全 Mock API、Linux 预览服务和可重复的前端构建/检查脚本
- 专业软路由控制台 V5：蓝白浅色分组侧栏、实时顶部状态、动态图表与高密度卡片工作台
- 仪表盘、内外网设置、VLAN、WAN / PPPoE、多 WAN、防火墙和系统设置重点页面视觉升级
- 内外网设置 V6：端口角色、独立 LAN/WAN 网络对象、出口绑定、WAN 线路组、实时拓扑和四步快速向导
- `/api/network/*` 端口、网络对象、线路组、出口绑定及草稿/预览/模拟应用契约
- LAN/WAN 接口选择逻辑
- DHCP、静态 IP、PPPoE 设计
- 单线多拨设计
- VLAN 拨号与 VLAN 多拨设计
- 虚拟 IPv4 和 ULA IPv6 双栈汇聚设计
- IPv4 线路池和 IPv6 线路池设计
- NPTv6、NAT66 和原生 IPv6 模式预览

## 当前尚未完成

- 单线多拨账号行和密码输入逻辑仍需从预览原型完善为生产实现
- VLAN 多账号拨号仍需从预览原型完善为生产实现
- preview 与真实 LuCI 尚未完全同步
- ucode 尚未在 OpenWrt 环境验证
- NAT44、NPTv6、NAT66 真实后端尚未实现
- 策略路由和回程一致性的真实后端尚未实现（当前仅有交互原型）
- OpenWrt SDK 编译尚未进行
- ISO 或磁盘镜像尚未制作

## 下次开发优先级

1. 冻结前端状态对象与 rpcd/ubus API schema，并增加契约测试
2. 将 12 个阶段页面逐步迁移到真实 LuCI 组件
3. 为 `linehubd` 实现 UCI 事务、校验、审计与可回滚 revision
4. 完成单线/VLAN 多拨账号行的生产实现和敏感字段处理
5. 实现每地址族策略路由、conntrack flow mark 与回程一致性
6. 在隔离的 OpenWrt 环境验证 ucode/rpcd 后再评审 SDK 构建

## 本地预览

启动方式：

```text
preview/start-preview.cmd
```

Linux 预览方式：

```sh
npm install
npm run dev
```

预览服务监听 `0.0.0.0:4173`；浏览器访问 `http://<服务器地址>:4173/`。

预览使用虚构演示数据，不应录入、导出或提交真实运营商账号和密码。
