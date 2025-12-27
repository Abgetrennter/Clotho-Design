# Figma设计资源包

**版本**: 1.0  
**日期**: 2025-12-21  
**关联文档**: `doc/ui-optimization-proposal.md`

---

## 1. 设计令牌系统

### 1.1 颜色令牌

```json
{
  "color": {
    "primary": "#E18A24",
    "secondary": "#919191", 
    "background": "#171717",
    "surface": "#242425",
    "success": "#58B600",
    "warning": "#FF9800",
    "error": "#F44336",
    "text": {
      "primary": "#DCDCD2",
      "secondary": "#919191",
      "disabled": "#7D7D7D"
    }
  }
}
```

### 1.2 间距令牌

```json
{
  "spacing": {
    "xs": "4px",
    "sm": "8px", 
    "md": "15px",
    "lg": "23px",
    "xl": "30px",
    "2xl": "45px"
  }
}
```

### 1.3 字体令牌

```json
{
  "typography": {
    "fontFamily": {
      "body": "Noto Sans, sans-serif",
      "mono": "Noto Sans Mono, monospace"
    },
    "fontSize": {
      "xs": "12px",
      "sm": "13.5px",
      "base": "15px", 
      "lg": "18px",
      "xl": "22.5px",
      "2xl": "30px"
    },
    "lineHeight": {
      "tight": "1.2",
      "normal": "1.5",
      "relaxed": "1.6"
    }
  }
}
```

---

## 2. 原子化组件库

### 2.1 按钮组件变体

**主要按钮 (Primary Button)**
- 尺寸: Small(28px), Medium(36px), Large(44px)
- 状态: Default, Hover, Active, Disabled, Loading
- 颜色: Primary, Secondary, Success, Warning, Error

**图标按钮 (Icon Button)**
- 形状: 圆形, 方形
- 尺寸: 24px, 32px, 48px
- 背景: 透明, 半透明, 实心

### 2.2 输入组件变体

**文本输入框**
- 尺寸: Small(32px), Medium(40px), Large(48px)
- 状态: Default, Focus, Error, Disabled
- 类型: 单行, 多行, 搜索, 密码

**选择器**
- 下拉选择器
- 单选框组
- 复选框组
- 开关切换器

### 2.3 卡片组件变体

**基础卡片**
- 变体: Default, Elevated, Outlined, Filled
- 圆角: 4px, 8px, 12px
- 阴影: Level 1-4

**消息卡片**
- 用户消息样式
- AI消息样式
- 系统消息样式
- 状态指示器

---

## 3. 响应式布局组件

### 3.1 自适应骨架

**三栏布局 (Desktop)**
```
[280px] [Flex] [320-400px]
  左栏      中栏        右栏
```

**两栏布局 (Tablet)**
```
[60px] [Flex] [可折叠]
 导轨   内容区    右栏
```

**单栏布局 (Mobile)**
```
[56px] [Flex]
 顶栏    内容区
[60px] [Flex]
  底栏    输入区
```

### 3.2 断点设置

- Mobile: 0-600px
- Tablet: 601-1000px  
- Desktop: 1001-1200px
- Wide: 1201px+

---

## 4. 交互组件

### 4.1 Swipe手势组件

**消息Swipe控制**
- 左滑按钮: 32px圆形, 半透明背景
- 右滑按钮: 32px圆形, 半透明背景
- 计数器: 小号徽章显示当前位置
- 动画: 300ms滑入/滑出

### 4.2 状态指示器

**加载状态**
- 旋转动画: 0.8s无限循环
- 脉冲动画: 2s淡入淡出
- 点状加载: 1.4s波浪动画

**消息状态**
- 发送中: 半透明+旋转图标
- 错误: 红色边框+错误图标
- 编辑中: 黄色边框+编辑图标

### 4.3 手势反馈

**触摸反馈**
- 涟漪效果: Material标准
- 按压缩放: 0.98倍缩放
- 悬停高亮: 亮度增加10%

---

## 5. 主题系统组件

### 5.1 毛玻璃效果

**背景层**
- 模糊强度: 5px, 10px, 20px
- 透明度: 30%, 50%, 70%
- 背景色: 可自定义

**前景层**
- 内容模糊: 0px
- 对比度: 自动调整
- 可读性: 保证WCAG AA标准

### 5.2 主题切换

**预设主题**
- 深色主题 (默认)
- 浅色主题
- 高对比度主题
- 自定义主题

**动态切换**
- 切换动画: 200ms淡入淡出
- 状态保持: 本地存储
- 实时预览: 即时生效

---

## 6. Figma组件结构

### 6.1 命名规范

```
组件类型/变体/状态
例: Button/Primary/Hover
    Input/Text/Focused
    Card/Message/User
```

### 6.2 Auto Layout设置

**按钮组件**
```
Direction: Horizontal
Padding: 8px 16px
Gap: 8px
Alignment: Center
```

**卡片组件**
```
Direction: Vertical  
Padding: 15px
Gap: 8px
Alignment: Stretch
```

**布局组件**
```
Direction: Horizontal Wrap
Padding: 15px
Gap: 15px
Alignment: Start
```

### 6.3 变体管理

**按钮变体属性**
- Type: Primary | Secondary | Icon | Text
- Size: Small | Medium | Large  
- State: Default | Hover | Active | Disabled

**输入框变体属性**
- Type: Text | Search | Password | Select
- Size: Small | Medium | Large
- State: Default | Focus | Error | Disabled

---

## 7. 导出设置

### 7.1 组件导出

**SVG格式**
- 矢量图标
- 可缩放
- 主题色适配

**PNG格式**  
- 多倍率: 1x, 2x, 3x
- 背景色: 透明
- 尺寸: 标准化

### 7.2 代码生成

**Flutter代码**
- Widget类自动生成
- 设计令牌映射
- 响应式属性

**CSS代码**
- 设计令牌变量
- 响应式媒体查询
- 动画关键帧

---

## 8. 使用指南

### 8.1 组件使用

**1. 选择组件**
- 根据功能需求选择合适组件
- 考虑响应式要求
- 检查状态变体

**2. 配置属性**
- 使用设计令牌
- 设置正确状态
- 配置响应式行为

**3. 组合布局**
- 使用Auto Layout
- 设置间距和对齐
- 测试不同断点

### 8.2 主题应用

**1. 颜色使用**
- 优先使用语义化颜色
- 避免硬编码颜色值
- 考虑对比度要求

**2. 间距应用**
- 使用标准间距令牌
- 保持一致的节奏
- 适配不同屏幕密度

**3. 字体应用**
- 使用标准字体大小
- 保持一致的行高
- 考虑可访问性要求

---

## 9. 质量检查清单

### 9.1 组件质量

- [ ] 所有状态变体已创建
- [ ] 响应式行为正确
- [ ] 交互反馈完整
- [ ] 无障碍属性设置
- [ ] 命名规范一致

### 9.2 设计一致性

- [ ] 颜色使用符合令牌
- [ ] 间距使用符合规范
- [ ] 字体使用符合标准
- [ ] 动画时长符合规范
- [ ] 圆角半径一致

### 9.3 导出完整性

- [ ] 所有组件已导出
- [ ] 代码生成正确
- [ ] 资源文件完整
- [ ] 文档说明清晰
- [ ] 版本信息准确

---

**创建**: UI设计团队  
**审核**: 产品团队  
**版本**: 1.0  
**日期**: 2025-12-21