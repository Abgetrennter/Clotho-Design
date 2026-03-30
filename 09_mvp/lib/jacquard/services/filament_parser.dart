import 'package:xml/xml.dart';

/// Filament 解析结果
class FilamentParseResult {
  final String? thought;
  final String content;
  final bool isComplete;
  final Map<String, dynamic> metadata;

  const FilamentParseResult({
    this.thought,
    required this.content,
    this.isComplete = false,
    this.metadata = const {},
  });

  @override
  String toString() => 'FilamentParseResult(thought: ${thought != null ? "yes" : "no"}, content: ${content.length} chars)';
}

/// FilamentParser - Filament 协议解析器
///
/// 解析 LLM 返回的 Filament v2.4 格式输出
/// 支持 Core 标签：<think>, <content>
/// 对应设计文档 4.5.1 节
class FilamentParser {
  // 标签名称
  static const String _thoughtTag = 'thought';
  static const String _contentTag = 'content';

  /// 解析完整的 Filament 响应
  FilamentParseResult parse(String input) {
    String? thought;
    String content = input;

    try {
      // 解析 XML
      final document = XmlDocument.parse(input);

      // 提取 thought 标签
      final thoughtElement = document.getElement(_thoughtTag);
      if (thoughtElement != null) {
        thought = thoughtElement.text.trim();
      }

      // 提取 content 标签
      final contentElement = document.getElement(_contentTag);
      if (contentElement != null) {
        content = contentElement.text.trim();
      } else {
        // 如果没有 content 标签，移除 thought 标签后的剩余内容作为 content
        content = _removeThoughtTag(input).trim();
      }
    } catch (e) {
      // XML 解析失败，尝试使用正则表达式提取
      return _parseWithRegex(input);
    }

    return FilamentParseResult(
      thought: thought,
      content: content,
      isComplete: true,
    );
  }

  /// 移除 thought 标签及其内容
  String _removeThoughtTag(String input) {
    // 尝试 XML 方式移除
    try {
      final document = XmlDocument.parse(input);
      final thoughtElement = document.getElement(_thoughtTag);
      if (thoughtElement != null) {
        // 移除 thought 元素
        thoughtElement.remove();
        return document.toXmlString();
      }
    } catch (_) {
      // XML 解析失败，使用正则
    }
    
    // 使用正则表达式移除 thought 标签
    final thoughtRegex = RegExp(r'<thought>[\s\S]*?</thought>', multiLine: true);
    return input.replaceAll(thoughtRegex, '').trim();
  }

  /// 使用正则表达式解析（备用方案）
  FilamentParseResult _parseWithRegex(String input) {
    String? thought;
    String content = input;

    // 提取 thought 标签内容
    final thoughtRegex = RegExp(r'<thought>([\s\S]*?)</thought>', multiLine: true);
    final thoughtMatch = thoughtRegex.firstMatch(input);
    if (thoughtMatch != null) {
      thought = thoughtMatch.group(1)?.trim();
    }

    // 提取 content 标签内容
    final contentRegex = RegExp(r'<content>([\s\S]*?)</content>', multiLine: true);
    final contentMatch = contentRegex.firstMatch(input);
    if (contentMatch != null) {
      content = contentMatch.group(1)?.trim() ?? input;
    }

    return FilamentParseResult(
      thought: thought,
      content: content,
      isComplete: true,
    );
  }

  /// 流式解析（增量解析）
  FilamentParseResult parseStream(String chunk, String accumulated) {
    final fullContent = accumulated + chunk;
    return parse(fullContent);
  }

  /// 检查是否包含 thought 标签
  bool hasThoughtTag(String input) {
    return input.contains('<$_thoughtTag>') || input.contains('<$_thoughtTag/>');
  }

  /// 检查是否包含 content 标签
  bool hasContentTag(String input) {
    return input.contains('<$_contentTag>');
  }

  /// 提取纯文本内容（移除所有标签）
  String extractPlainText(String input) {
    try {
      final document = XmlDocument.parse(input);
      return document.rootElement.text.trim();
    } catch (e) {
      // 如果 XML 解析失败，使用简单的标签移除
      return input
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }
  }
}
