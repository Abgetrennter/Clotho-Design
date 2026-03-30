import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/exceptions/clotho_exception.dart';
import '../models/prompt_bundle.dart';

/// LLM 响应块（用于流式输出）
class LLMResponseChunk {
  final String content;
  final bool isComplete;

  const LLMResponseChunk({
    required this.content,
    this.isComplete = false,
  });
}

/// LLM 服务配置
class LLMServiceConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final Duration timeout;
  final double temperature;
  final int maxTokens;

  const LLMServiceConfig({
    required this.baseUrl,
    required this.apiKey,
    this.model = 'gpt-4',
    this.timeout = const Duration(seconds: 60),
    this.temperature = 0.7,
    this.maxTokens = 2048,
  });
}

/// LLMService - LLM API 调用服务
///
/// 支持流式和非流式调用
/// 对应设计文档 4.5.1 节
class LLMService {
  final LLMServiceConfig _config;
  final Dio _dio;
  bool _isGenerating = false;
  final _cancelCompleter = Completer<void>();

  LLMService({required LLMServiceConfig config})
      : _config = config,
        _dio = Dio(BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: config.timeout,
          receiveTimeout: config.timeout,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
        ));

  /// 流式调用 LLM
  Stream<LLMResponseChunk> streamCompletion(PromptBundle bundle) async* {
    if (_isGenerating) {
      throw OrchestrationException(
        message: 'Generation already in progress',
        code: 'GENERATION_IN_PROGRESS',
      );
    }

    _isGenerating = true;

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _config.model,
          'messages': [
            for (final block in bundle.systemBlocks)
              {'role': 'system', 'content': block.content},
            for (final block in bundle.historyBlocks)
              {'role': _mapBlockType(block.type), 'content': block.content},
            if (bundle.userBlock != null)
              {'role': 'user', 'content': bundle.userBlock!.content},
          ],
          'stream': true,
          'temperature': _config.temperature,
          'max_tokens': _config.maxTokens,
        },
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data as List<int>;
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      final buffer = StringBuffer();

      for (final line in lines) {
        if (_cancelCompleter.isCompleted) {
          break;
        }

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            yield const LLMResponseChunk(content: '', isComplete: true);
            break;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>;
            if (choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>;
              final content = delta['content'] as String?;
              if (content != null) {
                buffer.write(content);
                yield LLMResponseChunk(content: content);
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    } on DioException catch (e) {
      throw OrchestrationException(
        message: 'LLM API error: ${e.message}',
        code: 'LLM_API_ERROR',
        cause: e,
      );
    } finally {
      _isGenerating = false;
    }
  }

  /// 非流式调用 LLM
  Future<String> completion(PromptBundle bundle) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _config.model,
          'messages': [
            for (final block in bundle.systemBlocks)
              {'role': 'system', 'content': block.content},
            for (final block in bundle.historyBlocks)
              {'role': _mapBlockType(block.type), 'content': block.content},
            if (bundle.userBlock != null)
              {'role': 'user', 'content': bundle.userBlock!.content},
          ],
          'temperature': _config.temperature,
          'max_tokens': _config.maxTokens,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw OrchestrationException(
          message: 'LLM returned empty response',
          code: 'LLM_EMPTY_RESPONSE',
        );
      }

      return choices[0]['message']['content'] as String;
    } on DioException catch (e) {
      throw OrchestrationException(
        message: 'LLM API error: ${e.message}',
        code: 'LLM_API_ERROR',
        cause: e,
      );
    }
  }

  /// 取消正在进行的生成
  Future<void> cancel() async {
    if (!_cancelCompleter.isCompleted) {
      _cancelCompleter.complete();
    }
    _isGenerating = false;
  }

  /// 映射 PromptBlockType 到 OpenAI 角色
  String _mapBlockType(dynamic type) {
    switch (type.toString()) {
      case 'PromptBlockType.assistant':
        return 'assistant';
      case 'PromptBlockType.user':
        return 'user';
      default:
        return 'user';
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}
