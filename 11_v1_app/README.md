# 11_v1_app

Clotho V1 的正式 Flutter 主干骨架。

## 当前状态

- 已完成标准 Flutter 工程初始化
- 已建立 `bootstrap -> app -> presentation` 最小启动链
- 已补齐 `jacquard/`、`mnemosyne/`、`muse/`、`persona/`、`diagnostics/` 目录占位
- 已提供 Session / Stage / Inspector / Settings 四个最小占位页面

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
