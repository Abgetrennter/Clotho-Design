# Clotho UI Demo

Clotho 表现层 UI 演示项目，展示基于 Material 3 设计系统的 Flutter Web 界面。

## 项目结构

```
08_demo/
├── lib/
│   ├── main.dart                    # 主程序入口
│   ├── theme/
│   │   ├── app_theme.dart           # Material 3 主题配置
│   │   └── design_tokens.dart       # 设计令牌（间距、尺寸、动画等）
│   ├── models/
│   │   ├── message.dart             # 消息模型
│   │   └── state_node.dart          # 状态节点模型
│   ├── widgets/
│   │   ├── layout/
│   │   │   └── responsive_layout.dart  # 响应式三栏布局
│   │   ├── navigation/
│   │   │   └── clotho_navigation_rail.dart  # 导航栏
│   │   ├── stage/
│   │   │   ├── message_bubble.dart  # 消息气泡
│   │   │   └── input_area.dart      # 输入区域
│   │   └── inspector/
│   │       └── state_tree_viewer.dart  # 状态树查看器
│   └── screens/
│       └── home_screen.dart         # 主屏幕
├── web/
│   └── index.html                   # Web 入口
└── pubspec.yaml                     # 项目配置
```

## 功能特性

- **响应式三栏布局**：根据屏幕尺寸自动调整布局（移动端/平板端/桌面端）
- **Material 3 设计系统**：使用最新的 Material Design 规范
- **深色主题**：基于 ColorScheme.fromSeed 的动态主题
- **Stage 聊天界面**：消息气泡、输入区域、生成状态指示
- **Mnemosyne 状态树查看器**：可视化展示数据引擎的状态结构
- **导航系统**：NavigationRail（桌面/平板）和 Drawer（移动端）

## 运行项目

### 前置要求

- Flutter SDK 3.0 或更高版本
- Dart SDK 3.0 或更高版本

### 安装依赖

```bash
flutter pub get
```

### 运行 Web 版本

```bash
flutter run -d chrome
```

或者构建并部署：

```bash
flutter build web
```

构建产物位于 `build/web/` 目录，可以部署到任何静态网站托管服务。

### 运行桌面版本

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## 设计文档

本项目对应的设计规范文档位于 `../00_active_specs/presentation/` 目录：

- [`01-design-tokens.md`](../00_active_specs/presentation/01-design-tokens.md) - 设计令牌
- [`02-color-theme.md`](../00_active_specs/presentation/02-color-theme.md) - 颜色主题
- [`03-typography.md`](../00_active_specs/presentation/03-typography.md) - 排版系统
- [`04-responsive-layout.md`](../00_active_specs/presentation/04-responsive-layout.md) - 响应式布局
- [`05-message-bubble.md`](../00_active_specs/presentation/05-message-bubble.md) - 消息气泡
- [`06-input-area.md`](../00_active_specs/presentation/06-input-area.md) - 输入区域
- [`08-navigation.md`](../00_active_specs/presentation/08-navigation.md) - 导航系统
- [`14-state-tree-viewer.md`](../00_active_specs/presentation/14-state-tree-viewer.md) - 状态树查看器

## 预览

### HTML 静态预览

如果不想运行 Flutter 环境，可以使用 HTML 静态预览：

```bash
# 在浏览器中打开
start ../00_active_specs/presentation/ui-preview.html
```

### 在线预览

将 `build/web/` 目录部署到以下服务即可在线预览：

- GitHub Pages
- Vercel
- Netlify
- Firebase Hosting

## 技术栈

- **Flutter 3.0+** - 跨平台 UI 框架
- **Material 3** - Google 最新设计系统
- **Dart 3.0+** - 编程语言
- **flutter_riverpod** - 状态管理（已引入，待使用）

## 许可证

本项目遵循 Clotho 项目的许可证。
