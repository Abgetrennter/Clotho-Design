# LLM API 配置指南

> **最后更新**: 2026-03-11
> **版本**: 1.1.0

## 修复记录

### v1.1.0 (2026-03-11)
- ✅ 修复：FilamentParser 现在可以正确处理没有 `<content>` 标签的响应
- ✅ 修复：JacquardOrchestrator 现在会保存 AI 响应消息到 Turn
- ✅ 优化：关闭流式传输，使用非流式调用（更稳定）

---

## CORS 错误解决方案

如果您在运行 Flutter Web 应用时遇到以下错误：

```
Access to XMLHttpRequest at 'http://127.0.0.1:1234/chat/completions' from origin 'http://localhost:52646' has been blocked by CORS policy
```

这是因为浏览器的同源策略（Same-Origin Policy）限制。以下是解决方案：

---

## 方案一：启用 LLM 服务器的 CORS（推荐）

### LM Studio 用户

1. 打开 **LM Studio** 应用
2. 点击左侧导航栏的 **Local Server**（服务器图标）
3. 点击右上角的 **⚙️ Settings**（设置）
4. 在设置面板中找到 **"CORS"** 或 **"Cross-Origin Resource Sharing"** 选项
5. **勾选** "Enable CORS (Cross-Origin Resource Sharing)"
6. 点击 **Restart Server** 重启本地服务器

**验证**：重启后，CORS 头会自动添加到所有响应中。

---

### Ollama 用户

1. 停止 Ollama 服务：
   ```bash
   # Windows (PowerShell)
   Stop-Process -Name "ollama" -Force
   
   # macOS/Linux
   sudo systemctl stop ollama
   ```

2. 设置环境变量并重启：
   ```bash
   # Windows (PowerShell)
   $env:OLLAMA_ORIGINS="*"
   ollama serve
   
   # macOS/Linux
   OLLAMA_ORIGINS="*" ollama serve
   ```

3. 或者永久设置（推荐）：
   ```bash
   # macOS (使用 launchctl)
   launchctl setenv OLLAMA_ORIGINS "*"
   
   # Linux (systemd)
   sudo systemctl edit ollama.service
   # 添加以下内容：
   # [Service]
   # Environment="OLLAMA_ORIGINS=*"
   ```

---

### 其他 LLM 服务

如果您使用的是其他 LLM 服务，请参考其文档启用 CORS。通常需要设置以下 HTTP 响应头：

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## 方案二：使用桌面平台运行（无 CORS 限制）

Flutter 桌面应用不受浏览器 CORS 策略限制。

### Windows

```bash
cd 09_mvp
flutter run -d windows
```

### macOS

```bash
cd 09_mvp
flutter run -d macos
```

### Linux

```bash
cd 09_mvp
flutter run -d linux
```

---

## 方案三：使用 Chrome 开发模式（仅开发环境）

⚠️ **警告**：此方法仅用于开发测试，不建议用于生产环境。

### Windows

```bash
# 关闭所有 Chrome 窗口
# 然后运行以下命令
chrome.exe --disable-web-security --user-data-dir="C:\temp\chrome-dev"
```

### macOS

```bash
# 关闭所有 Chrome 窗口
open -n -a /Applications/Google\ Chrome.app --args --disable-web-security --user-data-dir="/tmp/chrome-dev"
```

### Linux

```bash
google-chrome --disable-web-security --user-data-dir="/tmp/chrome-dev"
```

---

## 配置 LLM 服务

编辑 `lib/stage/providers/chat_provider.dart` 文件：

```dart
final llmConfigProvider = Provider<LLMServiceConfig>((ref) {
  return const LLMServiceConfig(
    baseUrl: 'http://127.0.0.1:1234',  // 修改为您的 LLM 服务器地址
    apiKey: 'YOUR_API_KEY',             // 如果需要 API Key
    model: 'qwen/qwen3.5-9b',           // 修改为您使用的模型名称
  );
});
```

---

## 常见问题排查

### 1. 仍然出现 CORS 错误

- 确认 LLM 服务器已重启
- 检查浏览器控制台，确认响应头中包含 `Access-Control-Allow-Origin`
- 尝试清除浏览器缓存

### 2. 连接被拒绝

- 确认 LLM 服务器正在运行
- 检查端口号是否正确（默认 LM Studio 使用 1234）
- 检查防火墙设置

### 3. 模型不响应

- 确认已加载模型
- 检查模型名称是否与服务器配置一致
- 查看 LLM 服务器日志

---

## 快速验证

运行以下命令测试 LLM 服务是否正常：

```bash
# 使用 curl 测试
curl -X POST http://127.0.0.1:1234/chat/completions \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"qwen/qwen3.5-9b\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}"
```

如果返回 JSON 响应，说明服务正常。

---

## 参考链接

- [LM Studio Local Server 文档](https://lmstudio.ai/docs/local-server)
- [Ollama API 文档](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Flutter Web 网络配置](https://docs.flutter.dev/platform-integration/web/platform-apis)
