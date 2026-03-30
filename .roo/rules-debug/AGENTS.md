# Debug Mode AGENTS.md

## 调试上下文

### 日志位置

- **应用日志**: 通过 `CoreLogger` 服务输出，集成到 `ClothoNexus` 事件总线
- **错误事件**: `SystemErrorEvent` 通过 Nexus 广播

### 错误码范围

| 范围 | 模块 |
|------|------|
| 1000-1999 | Infrastructure |
| 2000-2999 | Muse (AI) |
| 3000-3999 | Jacquard (Logic) |
| 4000-4999 | Mnemosyne (Data) |
| 5000-5999 | Presentation (UI) |

### 错误处理策略

详见 [`module-error-handling-strategies.md`](../../00_active_specs/infrastructure/module-error-handling-strategies.md)。

### 调试工具

- Flutter DevTools
- `flutter analyze` 代码分析
- `flutter test` 单元测试

### 参考文档

- [`naming-convention.md`](../../00_active_specs/naming-convention.md) - 技术命名规范（模块/类名参考）
