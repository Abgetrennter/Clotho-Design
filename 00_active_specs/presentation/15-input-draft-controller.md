# 输入草稿控制器 (Input Draft Controller)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/README.md`

---

## 1. 概述 (Overview)

InputDraftController 是 UI 子系统与用户输入之间的唯一写通道，负责管理输入草稿、验证和提交。本规范定义输入草稿控制器的结构和行为。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **单向流** | 输入只能通过控制器提交，不能直接发送 |
| **草稿管理** | 自动保存和恢复输入草稿 |
| **安全约束** | 状态栏严禁直接发送消息 |
| **Intent 转换** | 将用户操作转换为 Intent 发送给 Jacquard |

---

## 2. 控制器结构 (Controller Structure)

### 2.1 基础实现

```dart
class InputDraftController extends ChangeNotifier {
  final TextEditingController _textController = TextEditingController();
  String _draft = '';
  bool _isDirty = false;
  final List<DraftAction> _actions = [];

  TextEditingController get textController => _textController;
  String get draft => _draft;
  bool get isDirty => _isDirty;
  List<DraftAction> get actions => _actions;

  /// 初始化
  void initialize() {
    _loadDraft();
    _textController.text = _draft;
    _textController.addListener(_onTextChanged);
  }

  /// 文本变化监听
  void _onTextChanged() {
    final newDraft = _textController.text;

    if (newDraft != _draft) {
      _draft = newDraft;
      _isDirty = true;
      _saveDraft();
      notifyListeners();
    }
  }

  /// 设置草稿
  void setDraft(String text) {
    _draft = text;
    _textController.text = text;
    _isDirty = text.isNotEmpty;
    _saveDraft();
    notifyListeners();
  }

  /// 清空草稿
  void clear() {
    _draft = '';
    _textController.clear();
    _isDirty = false;
    _actions.clear();
    _clearDraft();
    notifyListeners();
  }

  /// 添加操作
  void addAction(DraftAction action) {
    _actions.add(action);
    notifyListeners();
  }

  /// 移除操作
  void removeAction(DraftAction action) {
    _actions.remove(action);
    notifyListeners();
  }

  /// 提交 Intent
  Future<void> submitIntent(Intent intent) async {
    // 发送 Intent 到 Jacquard
    await Jacquard.sendIntent(intent);

    // 清空草稿
    clear();
  }

  /// 保存草稿
  void _saveDraft() {
    // 保存到本地存储
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.setString('input_draft', _draft);
    });
  }

  /// 加载草稿
  void _loadDraft() {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      _draft = prefs.getString('input_draft') ?? '';
    });
  }

  /// 清空草稿
  void _clearDraft() {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.remove('input_draft');
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
```

---

## 3. DraftAction (草稿操作)

### 3.1 操作定义

```dart
enum DraftActionType {
  send,
  edit,
  delete,
  quote,
  mention,
}

class DraftAction {
  final String id;
  final DraftActionType type;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  DraftAction({
    required this.id,
    required this.type,
    required this.label,
    required this.icon,
    this.onPressed,
  });
}
```

### 3.2 内置操作

```dart
class DraftActions {
  static DraftAction send(VoidCallback onPressed) {
    return DraftAction(
      id: 'send',
      type: DraftActionType.send,
      label: '发送',
      icon: Icons.send,
      onPressed: onPressed,
    );
  }

  static DraftAction edit(VoidCallback onPressed) {
    return DraftAction(
      id: 'edit',
      type: DraftActionType.edit,
      label: '编辑',
      icon: Icons.edit,
      onPressed: onPressed,
    );
  }

  static DraftAction delete(VoidCallback onPressed) {
    return DraftAction(
      id: 'delete',
      type: DraftActionType.delete,
      label: '删除',
      icon: Icons.delete,
      onPressed: onPressed,
    );
  }

  static DraftAction quote(String text, VoidCallback onPressed) {
    return DraftAction(
      id: 'quote',
      type: DraftActionType.quote,
      label: '引用',
      icon: Icons.format_quote,
      onPressed: onPressed,
    );
  }

  static DraftAction mention(String name, VoidCallback onPressed) {
    return DraftAction(
      id: 'mention',
      type: DraftActionType.mention,
      label: '提及',
      icon: Icons.at_mention,
      onPressed: onPressed,
    );
  }
}
```

---

## 4. Intent 转换 (Intent Conversion)

### 4.1 Intent 定义

```dart
enum IntentType {
  sendMessage,
  editMessage,
  deleteMessage,
  regenerate,
  retry,
}

class Intent {
  final String id;
  final IntentType type;
  final Map<String, dynamic> data;

  Intent({
    required this.id,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
    };
  }
}
```

### 4.2 Intent 生成器

```dart
class IntentGenerator {
  static Intent sendMessage({
    required String content,
    String? characterId,
  }) {
    return Intent(
      id: generateId(),
      type: IntentType.sendMessage,
      data: {
        'content': content,
        'characterId': characterId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Intent editMessage({
    required String messageId,
    required String content,
  }) {
    return Intent(
      id: generateId(),
      type: IntentType.editMessage,
      data: {
        'messageId': messageId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Intent deleteMessage({
    required String messageId,
  }) {
    return Intent(
      id: generateId(),
      type: IntentType.deleteMessage,
      data: {
        'messageId': messageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Intent regenerate({
    required String messageId,
  }) {
    return Intent(
      id: generateId(),
      type: IntentType.regenerate,
      data: {
        'messageId': messageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static String generateId() {
    return 'intent_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
```

---

## 5. 状态栏集成 (Status Bar Integration)

### 5.1 状态栏按钮处理

```dart
class StatusBarButtonHandler {
  final InputDraftController _draftController;

  StatusBarButtonHandler(this._draftController);

  /// 处理状态栏按钮点击
  void handleStatusButtonClick(StatusBarButton button) {
    switch (button.type) {
      case StatusButtonType.action:
        // 生成 Draft 并填入输入框
        final draft = button.draftText ?? '';
        _draftController.setDraft(draft);
        break;

      case StatusButtonType.toggle:
        // 切换状态
        _toggleStatus(button);
        break;

      case StatusButtonType.info:
        // 显示信息
        _showInfo(button);
        break;
    }
  }

  void _toggleStatus(StatusBarButton button) {
    // 切换状态逻辑
  }

  void _showInfo(StatusBarButton button) {
    // 显示信息逻辑
  }
}
```

### 5.2 状态栏按钮定义

```dart
enum StatusButtonType {
  action,
  toggle,
  info,
}

class StatusBarButton {
  final String id;
  final StatusButtonType type;
  final String label;
  final IconData icon;
  final String? draftText;

  StatusBarButton({
    required this.id,
    required this.type,
    required this.label,
    required this.icon,
    this.draftText,
  });
}
```

---

## 6. 验证器 (Validator)

### 6.1 验证规则

```dart
class InputValidator {
  /// 验证输入
  static ValidationResult validate(String input) {
    final errors = <String>[];

    // 检查长度
    if (input.isEmpty) {
      errors.add('输入不能为空');
    } else if (input.length > 10000) {
      errors.add('输入过长，最多 10000 字符');
    }

    // 检查特殊字符
    if (input.contains('\u0000')) {
      errors.add('输入包含无效字符');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 验证 Token 数量
  static TokenValidationResult validateTokens(String input) {
    final tokens = _countTokens(input);
    final maxTokens = 4096;

    return TokenValidationResult(
      count: tokens,
      maxTokens: maxTokens,
      isValid: tokens <= maxTokens,
    );
  }

  static int _countTokens(String input) {
    // 简单的 token 计算逻辑
    // 实际实现应该使用更精确的算法
    return (input.length / 4).ceil();
  }
}
```

### 6.2 验证结果

```dart
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class TokenValidationResult {
  final int count;
  final int maxTokens;
  final bool isValid;

  TokenValidationResult({
    required this.count,
    required this.maxTokens,
    required this.isValid,
  });

  double get percentage => count / maxTokens;
}
```

---

## 7. 使用示例 (Usage Examples)

### 7.1 基本使用

```dart
class ChatInputArea extends StatefulWidget {
  @override
  _ChatInputAreaState createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  late final InputDraftController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InputDraftController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InputDraftController>.value(
      value: _controller,
      child: Column(
        children: [
          // Token 计数
          TokenCounter(),
          // 输入框
          TextField(
            controller: _controller.textController,
            maxLines: null,
            decoration: InputDecoration(
              hintText: '输入消息...',
            ),
          ),
          // 操作按钮
          ActionButtons(),
        ],
      ),
    );
  }
}
```

### 7.2 状态栏集成

```dart
class StatusBarButton extends StatelessWidget {
  final StatusBarButton button;
  final InputDraftController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(button.icon),
      onPressed: () {
        final handler = StatusBarButtonHandler(controller);
        handler.handleStatusButtonClick(button);
      },
      tooltip: button.label,
    );
  }
}
```

---

## 8. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| 直接发送 | `InputDraftController` | 直接调用 → Intent 转换 |
| 状态栏按钮 | `StatusBarButtonHandler` | 直接操作 → 草稿生成 |
| 输入验证 | `InputValidator` | 无 → 统一验证器 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`06-input-area.md`](./06-input-area.md) - 输入区域组件
- [`../jacquard/README.md`](../jacquard/README.md) - Jacquard 编排层
