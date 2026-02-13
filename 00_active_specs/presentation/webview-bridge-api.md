# WebView 桥接 API 规范 (WebView Bridge API Specification)

**版本**: 1.0.0
**日期**: 2026-02-12
**状态**: Active
**参考**: `00_active_specs/presentation/12-webview-fallback.md`

---

## 1. 概述 (Overview)

本规范定义了 Clotho 应用中 WebView 容器与 Dart 宿主环境之间的通信协议。该协议确保在无法使用 RFW 渲染时，能够通过 Web 技术提供具有一定交互能力的兜底 UI。

### 1.1 通信通道 (Communication Channel)
*   **JavaScript 对象**: `window.ClothoBridge`
*   **Android/iOS**: 基于 `JavascriptChannel`
*   **Web**: 基于 `window.postMessage`

---

## 2. 消息协议 (Message Protocol)

采用 **JSON-RPC 2.0** 风格的消息格式，支持双向调用。

### 2.1 请求格式 (Request)

```json
{
  "jsonrpc": "2.0",
  "method": "open_image",
  "params": {
    "url": "https://example.com/image.png"
  },
  "id": 1
}
```

### 2.2 响应格式 (Response)

**成功响应**:
```json
{
  "jsonrpc": "2.0",
  "result": "success",
  "id": 1
}
```

**错误响应**:
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found"
  },
  "id": 1
}
```

### 2.3 通知 (Notification)
不包含 `id` 字段的请求被视为单向通知，无需响应。
```json
{
  "jsonrpc": "2.0",
  "method": "on_resize",
  "params": { "height": 300 }
}
```

---

## 3. API 列表 (API Surface)

### 3.1 Host -> Web (Inbound)

宿主环境调用 Web 页面的方法。

| 方法名 | 参数 (Params) | 说明 |
| :--- | :--- | :--- |
| `updateState` | `{ "data": Object }` | 全量更新渲染数据 |
| `patchState` | `{ "diff": Object }` | 增量更新数据 |
| `setTheme` | `{ "mode": "dark"\|"light", "colors": Object }` | 同步应用主题配置 |
| `pause` | `{}` | 通知页面暂停（如切后台） |
| `resume` | `{}` | 通知页面恢复 |

### 3.2 Web -> Host (Outbound)

Web 页面调用宿主环境的能力。

#### 基础能力 (Base Capability - Level 0)
| 方法名 | 参数 (Params) | 说明 |
| :--- | :--- | :--- |
| `resize` | `{ "height": Number }` | 通知内容高度变化 |
| `navigate` | `{ "url": String }` | 打开外部链接或路由 |
| `toast` | `{ "msg": String, "type": "info"\|"error" }` | 显示原生 Toast |
| `copy` | `{ "text": String }` | 复制文本到剪贴板 |
| `log` | `{ "level": String, "msg": String }` | 转发日志到控制台 |
| `triggerAction` | `{ "actionId": String, "payload": Object }` | 触发业务逻辑 (见 RFW Action) |

#### 扩展能力 (Extended Capability - Level 2 Only)
| 方法名 | 参数 (Params) | 说明 |
| :--- | :--- | :--- |
| `fs.read` | `{ "path": String }` | 读取本地文件 |
| `fs.write` | `{ "path": String, "content": String }` | 写入本地文件 |
| `http.request` | `{ "url": String, "method": String }` | 发起无 CORS 限制的请求 |
| `system.exec` | `{ "cmd": String }` | 执行系统命令 (仅限桌面端) |

---

## 4. 初始化流程 (Initialization Flow)

1.  **加载**: WebView 加载 HTML 内容。
2.  **注入**: Host 注入 `ClothoBridge` JS 对象。
3.  **握手 (Handshake)**:
    *   Web 发送 `ready` 通知。
    *   Host 发送 `init` 消息，包含初始 `state` 和 `theme`。
4.  **交互**: 进入消息循环。

---

## 5. 安全分级 (Security Tiers)

WebView 桥接同样遵循项目的分级权限模型。

### Level 0: App Store Mode (默认)
*   **JavaScript 限制**: 禁用 `eval()`，启用严格 CSP。
*   **API 限制**: 仅开放“基础能力”组的 API。
*   **域名限制**: 仅允许加载本地内容或白名单 HTTPS 域名。

### Level 1: Developer Mode
*   **调试**: 开启 WebView 远程调试端口。
*   **日志**: 允许详细日志输出。

### Level 2: God Mode (侧载/越狱)
*   **API 解锁**: 开放“扩展能力”组 API (`fs`, `http`, `system`)。
*   **跨域**: 禁用 WebView 的同源策略 (CORS)。
*   **风险提示**: 开启此模式时，App 必须在 UI 上显著提示“不安全的内容环境”。

---

## 6. 错误处理 (Error Handling)

*   **超时**: RPC 调用默认 5 秒超时。
*   **格式错误**: 不符合 JSON-RPC 规范的消息将被丢弃并记录错误。
*   **权限拒绝**: 调用未授权级别的 API 将返回 `code: 403` 错误。
