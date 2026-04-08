abstract class AppLogger {
  void info(String message);

  void warning(String message);

  void error(String message, {Object? error});
}
