# 11_v1_app

Clotho V1 的正式 Flutter 主干骨架。

当前运行目标：Windows / desktop。
`web` 平台已移除，不再支持 Chrome 目标。

## 当前状态

- 已完成标准 Flutter 工程初始化
- 已建立 `bootstrap -> app -> presentation` 最小启动链
- 已补齐 `jacquard/`、`mnemosyne/`、`muse/`、`persona/`、`diagnostics/` 目录占位
- 已提供 Session / Stage / Inspector / Settings 四个最小占位页面
- 已补齐 Mnemosyne 的 V1 最小 SQLite schema 与 Session repository 骨架
- 已补齐 Turn 单事务提交骨架，可一次提交 turns / messages / state_oplogs / active_states
- 已补齐 Jacquard 最小发送消息用例，可串联 Muse 输出、Filament 解析与 Mnemosyne 提交
- Chat 页面已接到本地 demo runtime，可实际发送消息并看到状态更新
- `DemoMuseRawGateway` 支持最简单的 OpenAI-compatible HTTP 调用；未配置 API key 时自动回退到本地 demo 响应

## DemoMuseRawGateway 配置

可通过编译期环境变量启用最简单的远程模型调用：

- `CLOTHO_MUSE_API_KEY`
- `CLOTHO_MUSE_MODEL`
- `CLOTHO_MUSE_BASE_URL`
- `CLOTHO_MUSE_PROVIDER_ID`
- `CLOTHO_MUSE_TEMPERATURE`

当前实现使用 OpenAI-compatible `POST /chat/completions`。
未提供 `API_KEY` 或 `MODEL` 时，仍走本地 fallback 响应，便于继续开发 UI 与持久化主链。

## 目录原则

- `presentation/` 只承载界面与交互壳，不直接访问持久化层
- `jacquard/` 保留 UI 代理、编排服务、Filament 处理入口
- `mnemosyne/` 保留领域对象、仓库、持久化实现入口
- `muse/` 只保留原始模型访问边界
- `persona/` 负责 Persona 发现、加载与绑定

## 下一步建议

1. 在 `mnemosyne/persistence/` 落 V1 最小 SQLite DDL 与 repository 实现
2. 在 `jacquard/services/` 落 Filament V1 解析与主对话编排链
3. 用适配器把 `presentation/chat/` 从占位页接到真实用例
