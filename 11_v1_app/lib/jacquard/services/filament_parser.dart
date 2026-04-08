class FilamentParseResult {
  const FilamentParseResult({
    required this.content,
    this.thought,
    this.stateUpdateJson,
  });

  final String content;
  final String? thought;
  final String? stateUpdateJson;
}

abstract class FilamentParser {
  FilamentParseResult parse(String rawOutput);
}
