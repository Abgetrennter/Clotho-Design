# SDUI RFW 协议与包规范 (SDUI RFW Protocol & Package Specification)

**版本**: 1.0.0
**日期**: 2026-02-12
**状态**: Active
**参考**: `00_active_specs/presentation/10-hybrid-sdui.md`

---

## 1. 概述 (Overview)

本规范定义了 Clotho 项目中用于动态 UI 渲染的 RFW (Remote Flutter Widgets) 协议扩展，以及 `.cpk` (Clotho Package) 资源包格式。该设计旨在平衡 **App Store 合规性** 与 **开发者灵活性**，通过分级权限模型满足不同场景的需求。

### 1.1 核心目标
*   **标准化交付**: 统一 UI 模板、逻辑与资源的交付格式。
*   **安全沙盒**: 确保动态加载的内容不会破坏宿主应用的安全。
*   **高性能**: 采用二进制格式优化传输与解析效率。

---

## 2. Clotho 包格式 (.cpk)

Clotho Package (`.cpk`) 是一个基于 ZIP 的归档格式，用于分发 RFW 库及其相关资源。

### 2.1 目录结构

```text
example_package.cpk
├── manifest.json       # 包元数据
├── main.rfw            # 编译后的二进制 RFW 库
├── assets/             # 静态资源目录
│   ├── images/
│   │   └── icon.png
│   └── fonts/
│       └── CustomFont.ttf
└── signature.sig       # (可选) 数字签名
```

### 2.2 Manifest 定义 (`manifest.json`)

```json
{
  "name": "com.clotho.templates.galgame",
  "version": "1.0.0",
  "min_api_level": 1,
  "max_api_level": 5,
  "author": "Clotho Team",
  "description": "Galgame style message bubbles and status panels.",
  "permissions": ["network_image", "local_storage"],
  "entry_points": {
    "message_bubble": "GalgameBubble",
    "status_panel": "GalgameStatus"
  },
  "compatibility": {
    "backward_compatible": true,
    "forward_compatible": false,
    "notes": "此包向后兼容 API Level 1-5，但不保证向前兼容"
  }
}
```

### 2.3 版本兼容性策略

Clotho RFW 包采用语义化版本管理 (Semantic Versioning) 和 API Level 双重机制：

#### 语义化版本 (SemVer)

| 版本格式 | 说明 | 兼容性保证 |
|---------|------|-----------|
| `MAJOR.MINOR.PATCH` | 主版本。不兼容的 API 变更 | 不兼容 |
| `MAJOR.MINOR.PATCH` | 次版本。向后兼容的功能新增 | 向后兼容 |
| `MAJOR.MINOR.PATCH` | 修订号。向后兼容的问题修复 | 向后兼容 |

#### API Level 机制

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| `min_api_level` | Integer | ✅ | 包所需的最低 API 级别 |
| `max_api_level` | Integer | ✅ | 包支持的最高 API 级别 |
| `compatibility.backward_compatible` | Boolean | ❌ | 是否向后兼容旧版本 |
| `compatibility.forward_compatible` | Boolean | ❌ | 是否向前兼容新版本 |
| `compatibility.notes` | String | ❌ | 兼容性说明 |

#### 版本兼容性规则

1. **加载检查**: 宿主应用加载包时，检查当前 API Level 是否在 `min_api_level` 和 `max_api_level` 范围内
2. **拒绝加载**: 如果 API Level 不匹配，拒绝加载并返回错误信息
3. **警告提示**: 如果包标记为不向后兼容，加载时显示警告
4. **推荐更新**: 对于旧版本包，提示用户更新到最新版本

```dart
class RFWPackageLoader {
  final int currentApiLevel = 5; // 当前宿主 API Level
  
  bool canLoadPackage(Manifest manifest) {
    // 检查 API Level 范围
    if (currentApiLevel < manifest.minApiLevel ||
        currentApiLevel > manifest.maxApiLevel) {
      return false;
    }
    
    // 检查兼容性标记
    if (!manifest.compatibility.backwardCompatible &&
        currentApiLevel > manifest.minApiLevel) {
      // 显示警告但不阻止加载
      showCompatibilityWarning(manifest);
    }
    
    return true;
  }
}
```

#### API Level 变更历史

| API Level | Clotho 版本 | 主要变更 |
|----------|-----------|---------|
| 1 | 1.0.0 | 初始版本，基础 RFW 支持 |
| 2 | 1.1.0 | 添加 SDUI 内容类型支持 |
| 3 | 1.2.0 | 添加事件处理器支持 |
| 4 | 1.3.0 | 添加主题同步支持 |
| 5 | 1.4.0 | 添加 Pattern 状态组件 (当前版本) |


### 2.3 RFW 二进制库 (`main.rfw`)

采用 Flutter 官方 `rfw` 包定义的二进制格式。
*   **Library**: 包含一组 Widget 定义。
*   **Symbol Table**: 字符串池，优化体积。
*   **OpCodes**: 定义 Widget 树结构的字节码。

---

## 3. 组件映射表 (Widget Map)

Host 端暴露给 RFW 环境的原生组件白名单。只有在此列表中的组件才能在 `.rfw` 中使用。

### 3.1 基础布局 (Layout Primitives)
| 组件名 | Dart 对应 | 说明 |
| :--- | :--- | :--- |
| `Container` | `Container` | 容器 |
| `Row` | `Row` | 水平布局 |
| `Column` | `Column` | 垂直布局 |
| `Stack` | `Stack` | 层叠布局 |
| `ListView` | `ListView` | 滚动列表 |
| `SizedBox` | `SizedBox` | 固定尺寸 |
| `Center` | `Center` | 居中 |

### 3.2 核心 UI (Core UI)
| 组件名 | Dart 对应 | 说明 |
| :--- | :--- | :--- |
| `Text` | `Text` | 文本 |
| `Image` | `Image` | 图片 (支持本地 asset 和网络) |
| `Icon` | `Icon` | 图标 |
| `Button` | `ElevatedButton`/`TextButton` | 按钮 |
| `Card` | `Card` | 卡片 |

### 3.3 Clotho 专用组件 (Clotho Specific)
| 组件名 | 说明 | 属性示例 |
| :--- | :--- | :--- |
| `MessageBubble` | 消息气泡外壳 | `isUser`, `timestamp` |
| `Avatar` | 智能头像组件 | `charId`, `expression` |
| `MarkdownText` | Markdown 渲染器 | `data`, `selectable` |
| `StatusBadge` | 状态徽章 | `label`, `color` |

---

## 4. 交互与事件 (Interactions & Events)

为了符合 App Store 规范，RFW 环境 **不包含** 可执行代码 (如 Dart/JS)。交互逻辑通过 **Action Binding** 实现。

### 4.1 事件处理器 (Event Handlers)

在 `.rfw` 文件中，通过 `event` 属性绑定预定义的 Action：

```dart
// RFW 定义示例
Button(
  onPressed: event "open_url" { url: "https://clotho.ai" },
  child: Text(text: "Visit Website"),
)
```

### 4.2 标准 Action 列表

| Action ID | 参数 (Args) | 说明 |
| :--- | :--- | :--- |
| `navigate` | `route`, `args` | 页面跳转 |
| `open_url` | `url` | 打开外部链接 |
| `copy_text` | `text` | 复制到剪贴板 |
| `send_message` | `text` | 发送消息到对话流 |
| `update_state` | `key`, `value` | 更新当前 Widget 树的局部状态 |
| `set_memory` | `key`, `value` | 写入临时记忆 (Session Storage) |

---

## 5. 动态加载机制 (Dynamic Loading)

### 5.1 加载流程

1.  **下载**: 客户端下载 `.cpk` 文件到临时目录。
2.  **验签 (可选)**: 验证 `signature.sig` 确保来源可信。
3.  **解压**: 解压到应用沙盒的 `packages/{package_name}/` 目录。
4.  **注册**:
    *   读取 `manifest.json`，校验版本兼容性。
    *   加载 `main.rfw` 到全局 `Runtime`。
    *   注册 Assets 路径映射。

### 5.2 缓存策略

*   **LRU Cache**: 限制本地存储的包数量/大小，自动清理长期未使用的包。
*   **Version Pinning**: 关键包 (Core UI) 永不清理，随应用更新。

---

## 6. 合规与安全分级 (Compliance & Security Tiers)

为了兼顾 App Store 审核与极客用户的需求，系统实现分级权限模型。

### Level 0: App Store Mode (默认/严格)
*   **适用场景**: App Store 上架版本。
*   **代码限制**: 禁止任何形式的脚本执行。仅支持声明式 UI。
*   **网络限制**: 仅允许加载白名单域名的图片。
*   **交互限制**: 仅支持 4.2 节定义的标准 Action。
*   **合规声明**: 完全符合 Guideline 2.5.2，无代码热更新。

### Level 1: Developer Mode (开发者模式)
*   **适用场景**: TestFlight 测试、企业内部分发。
*   **扩展能力**:
    *   允许加载未签名的本地 `.cpk` 包。
    *   开启详细的 RFW 调试日志。
    *   允许连接本地 IDE 进行实时预览。

### Level 2: God Mode (侧载/越狱)
*   **适用场景**: 个人编译安装、越狱设备。
*   **解锁能力**:
    *   **Scripting**: 允许通过 `ScriptEval` 组件执行内嵌的 Lua/JS 脚本 (需集成对应引擎)。
    *   **Native Access**: 允许 Action 访问文件系统、原生 Toast、系统设置等底层 API。
    *   **注意**: 开启此模式将导致应用无法通过 App Store 审核。

---

## 7. 异常处理 (Error Handling)

1.  **加载失败**: 记录日志，回退到默认主题或 WebView 兜底。
2.  **渲染错误**: 使用红色 `ErrorWidget` 占位，并显示错误栈摘要。
3.  **缺少组件**: 遇到未知 Widget 时，渲染为空 `SizedBox` 并上报遥测数据。
