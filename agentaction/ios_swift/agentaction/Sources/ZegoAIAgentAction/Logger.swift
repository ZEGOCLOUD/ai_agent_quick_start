import Foundation

/// Kit 内部使用的日志工具。
///
/// 业务侧可以通过 [ZegoAIAgentActionLogger.installSink] 自定义输出方式（如
/// 仅在 Debug 模式输出、写入文件、接入业务日志框架等）；未安装 sink 时
/// 日志默认通过 `print` 输出到 stdout。
public enum ZegoAIAgentActionLogger {
    /// 日志级别。
    public static let levelDebug = 0
    public static let levelInfo = 1
    public static let levelWarn = 2
    public static let levelError = 3

    private static var level: Int = levelDebug
    private static var sink: ((String) -> Void)?

    /// 设置日志输出回调。
    ///
    /// 传入 [handler] 接管日志输出；传入 `nil` 恢复为默认 stdout 输出。
    public static func installSink(_ handler: ((String) -> Void)?) {
        sink = handler
    }

    /// 设置日志级别，低于该级别的日志将被丢弃。
    public static func setLevel(_ level: Int) {
        self.level = level
    }

    public static func debug(_ message: @autoclosure () -> String) {
        log(levelDebug, label: "DEBUG", message: message())
    }

    public static func info(_ message: @autoclosure () -> String) {
        log(levelInfo, label: "INFO", message: message())
    }

    public static func warn(_ message: @autoclosure () -> String) {
        log(levelWarn, label: "WARN", message: message())
    }

    public static func error(_ message: @autoclosure () -> String) {
        log(levelError, label: "ERROR", message: message())
    }

    private static func log(_ level: Int, label: String, message: String) {
        guard level >= self.level else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "ZegoAIAgentAction [\(label)] \(timestamp) \(message)"
        if let sink = sink {
            sink(line)
        } else {
            print(line)
        }
    }
}
