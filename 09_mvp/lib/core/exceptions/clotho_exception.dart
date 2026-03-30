/// Clotho 异常基类
///
/// 所有 Clotho 自定义异常都应继承此类
abstract class ClothoException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const ClothoException({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() => 'ClothoException($code): $message';
}

/// 领域层异常
class DomainException extends ClothoException {
  const DomainException({
    required super.message,
    super.code,
    super.cause,
  });
}

/// 数据层异常
class DataException extends ClothoException {
  const DataException({
    required super.message,
    super.code,
    super.cause,
  });
}

/// 实体未找到异常
class NotFoundException extends DataException {
  const NotFoundException({
    required super.message,
    super.code,
    super.cause,
  });
}

/// 编排层异常
class OrchestrationException extends ClothoException {
  const OrchestrationException({
    required super.message,
    super.code,
    super.cause,
  });
}
