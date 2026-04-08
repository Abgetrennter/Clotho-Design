abstract class JacquardUiAdapter {
  Future<Map<String, Object?>> requestUiSchema(String path);

  Future<Map<String, Object?>> requestDataProjection(String path);

  Future<void> submitIntent({
    required String type,
    required Map<String, Object?> payload,
    String? sourceComponentId,
  });
}
