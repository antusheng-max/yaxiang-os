# 安全 Mock API 契约

`tools/preview-server.mjs` 为 Web 原型提供静态资源、只读模拟清单，以及仅存在于当前 Node.js 进程内的配置草稿流程。服务不读取 UCI、不调用 ubus，也不执行 shell、网卡、路由、DNS 或防火墙命令。

`/api/health` 继续返回 `mode: "mock-read-only"`：这里的“只读”指宿主机配置始终只读。下列 `POST` 只创建、校验和转换内存对象，响应均明确包含：

```json
{
  "mock": true,
  "executed": false,
  "hostConfigurationChanged": false,
  "systemCommands": []
}
```

服务重启后，草稿、预览和模拟应用记录全部丢弃。

## 启动

```sh
npm run dev
```

默认监听 `0.0.0.0:4173`。监听地址仅用于外部浏览器访问原型，不代表允许 API 修改宿主机状态。

## 查询端点

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/api/health` | 预览服务健康状态，保持第一阶段响应兼容。 |
| `GET` | `/api/v1/capabilities` | IPv4/IPv6 独立状态、流亲和与单连接能力边界。 |
| `GET` | `/api/v1/system/summary` | 虚构系统资源和 WAN 摘要。 |
| `GET` | `/api/network/ports` | 虚构物理端口清单。 |
| `GET` | `/api/network/wans` | 虚构 WAN 清单；IPv4 与 IPv6 分开表达。 |
| `GET` | `/api/network/lans` | 虚构 LAN/网桥清单。 |
| `GET` | `/api/network/wan-groups` | 虚构 WAN 线路组。 |
| `GET` | `/api/network/egress-bindings` | 虚构源网络出口绑定。 |

集合响应包含 `revision`、`count`、`items`，同时提供与资源同名的字段，例如 `wanGroups`，便于前端逐步迁移。

线路组的当前最小契约为：

```json
{
  "id": "wan-group-server",
  "name": "服务器线路组",
  "mode": "weighted-balance",
  "members": [
    { "wan": "wan1", "weight": 1 },
    { "wan": "wan2", "weight": 1 },
    { "wan": "wan3", "weight": 2 }
  ],
  "healthCheck": true,
  "sessionPersistence": "src-dst-hash"
}
```

`weight` 用于新建流的选路权重。已建立的 TCP/UDP 流保持在选定 WAN；普通多 WAN 不聚合单条 TCP 连接带宽。

出口绑定的当前最小契约为：

```json
{
  "id": "binding-server-01",
  "name": "服务器出口",
  "sourceNetwork": "lan2",
  "sourcePorts": ["eth1"],
  "mode": "single-wan",
  "target": "wan3",
  "nat": true,
  "failBehavior": "stay-offline",
  "priority": 100,
  "enabled": true
}
```

## 内存草稿流程

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/api/network/drafts/ports` | 校验并保存端口草稿。 |
| `POST` | `/api/network/drafts/wans` | 校验并保存 WAN 草稿。 |
| `POST` | `/api/network/drafts/lans` | 校验并保存 LAN 草稿。 |
| `POST` | `/api/network/drafts/wan-groups` | 严格校验线路组结构后保存草稿。 |
| `POST` | `/api/network/drafts/egress-bindings` | 严格校验出口绑定结构后保存草稿。 |
| `POST` | `/api/network/config-preview` | 汇总草稿并返回结构化变更预览。 |
| `POST` | `/api/network/apply` | 创建“待确认”的模拟应用记录，不执行配置。 |
| `POST` | `/api/network/confirm` | 将模拟应用记录标记为已确认。 |
| `POST` | `/api/network/rollback` | 将模拟应用记录标记为已回滚。 |

草稿既可直接提交资源对象，也可使用信封：

```json
{
  "operation": "update",
  "targetId": "wan-group-server",
  "baseRevision": "mock-config-0001",
  "payload": {
    "id": "wan-group-server",
    "name": "服务器线路组",
    "mode": "weighted-balance",
    "members": [{ "wan": "wan1", "weight": 2 }],
    "healthCheck": true,
    "sessionPersistence": "src-dst-hash"
  }
}
```

后续调用顺序如下：

1. 从草稿响应读取 `draft.id`。
2. 向 `/api/network/config-preview` 提交 `{ "draftIds": ["draft-0001"] }`。
3. 向 `/api/network/apply` 提交 `{ "previewId": "preview-0001" }`。
4. 向 `/api/network/confirm` 或 `/api/network/rollback` 提交 `{ "applyId": "apply-0001" }`。

`apply`、`confirm` 和 `rollback` 只是演示状态机；它们不会改变查询端点返回的清单，也不会生成可执行命令。

## 校验与安全边界

- 请求体必须是 UTF-8 JSON，最大 `128 KiB`。
- 草稿拒绝 `password`、`secret`、`token`、私钥、证书及原型污染键；PPPoE 只允许 `secretConfigured` 之类的布尔状态。
- WAN 线路组要求成员 `wan` 和 `1..100` 的整数 `weight`，并显式提供健康检查与会话保持策略。
- 出口绑定要求来源网络、来源接口、目标、NAT、失败行为、优先级和启用状态。
- IPv4 与 IPv6 状态独立；多个 IPv6-PD 前缀不会被描述为合并后的单一公网前缀。
- 未列出的写路径返回结构化错误；查询端点不接受 `POST`。

## 生产 API 方向

后续 rpcd/ubus API 应拆分为：

- `configuration`：接收期望状态、做 schema 校验、生成 UCI 事务并返回可回滚 revision。
- `status.ipv4` 与 `status.ipv6`：分别返回链路、地址、网关、健康检查和线路池状态。
- `flows`：只读返回 conntrack mark、所选 WAN 和 flow affinity 信息，不暴露载荷。
- `audit`：记录操作者、变更摘要、校验结果和回滚状态，不记录 PPPoE 明文密码。

Web 只调用受 ACL 约束的 API；`linehubd` 负责协调 OpenWrt 服务。当前 Mock JSON 用于界面联调，不视为已冻结的生产接口。

为兼容早期原型，当前服务仍接受对应的 `/api/v1/*` 别名；新代码应统一使用 `/api/network/*` 主契约。
