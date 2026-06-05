/// Kit 内部使用的日志工具，将日志统一带上 `ZegoAIAgentAction` 前缀输出到 stdout。
///
/// 业务侧可以通过 [ZegoAIAgentActionLogger.installSink] 自定义输出方式（如
/// 仅在 Debug 模式输出、写入文件等）。
class ZegoAIAgentActionLogger {
  /// 日志级别。
  static const int levelDebug = 0;
  static const int levelInfo = 1;
  static const int levelWarn = 2;
  static const int levelError = 3;

  static int _level = levelDebug;
  static void Function(String line)? _sink;

  /// 设置日志输出回调。
  ///
  /// 传入 [sink] 接管日志输出；传入 `null` 恢复为默认 stdout 输出。
  static void installSink(void Function(String line)? sink) {
    _sink = sink;
  }

  /// 设置日志级别，低于该级别的日志将被丢弃。
  static void setLevel(int level) {
    _level = level;
  }

  static void debug(String message) => _log(levelDebug, 'DEBUG', message);
  static void info(String message) => _log(levelInfo, 'INFO', message);
  static void warn(String message) => _log(levelWarn, 'WARN', message);
  static void error(String message) => _log(levelError, 'ERROR', message);

  static void _log(int level, String label, String message) {
    if (level < _level) return;
    final line =
        'ZegoAIAgentAction [$label] ${DateTime.now().toIso8601String()} $message';
    if (_sink != null) {
      _sink!(line);
    } else {
      // ignore: avoid_print
      print(line);
    }
  }
}
