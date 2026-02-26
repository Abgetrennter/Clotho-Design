# Code Mode AGENTS.md

## Flutter 代码规范

**位置**: `08_demo/`

### 命令

```bash
cd 08_demo && flutter pub get    # 安装依赖
cd 08_demo && flutter run -d chrome  # Web 运行
cd 08_demo && flutter test       # 运行测试
cd 08_demo && flutter analyze    # 代码分析
```

### 架构约束

- **UI 层严禁包含业务逻辑**: UI 组件不得直接修改数据模型，必须通过 Intent/Event 发送给逻辑层
- **状态管理**: 使用 Riverpod，状态变更必须提交给 Mnemosyne 统一处理
- **依赖注入**: GetIt（核心层） + Riverpod（UI 层）混合架构

### 关键接口

- [`interface-definitions.md`](../../00_active_specs/protocols/interface-definitions.md) - 公共接口定义
- [`dependency-injection.md`](../../00_active_specs/infrastructure/dependency-injection.md) - 依赖注入规范

### 术语

使用纺织隐喻体系，详见 [`metaphor-glossary.md`](../../00_active_specs/metaphor-glossary.md)。
