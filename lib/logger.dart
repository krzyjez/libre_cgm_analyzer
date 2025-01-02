enum LogLevel { debug, info, warning, error }

class Logger {
  final String tag;
  static bool isProduction = false;

  Logger(this.tag);

  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  void info(String message) {
    _log(LogLevel.info, message);
  }

  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  void error(String message) {
    _log(LogLevel.error, message);
  }

  void _log(LogLevel level, String message) {
    if (isProduction) {
      // W produkcji możemy np. wysyłać logi do serwera lub zapisywać do pliku
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.toString().split('.').last.toUpperCase();
    print('$timestamp [$prefix] $tag: $message');
  }
}
