package com.zego.agentaction;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Kit 内部使用的日志工具。
 *
 * <p>业务侧可以通过 {@link #installSink(LoggerSink)} 自定义输出方式（如
 * 仅在 Debug 模式输出、写入文件、接入业务日志框架等）；未安装 sink 时
 * 日志默认通过 {@code android.util.Log} 输出。</p>
 */
public class ZegoAIAgentActionLogger {

    /** DEBUG 级别。 */
    public static final int LEVEL_DEBUG = 0;
    /** INFO 级别。 */
    public static final int LEVEL_INFO = 1;
    /** WARN 级别。 */
    public static final int LEVEL_WARN = 2;
    /** ERROR 级别。 */
    public static final int LEVEL_ERROR = 3;

    /** 自定义日志输出回调。 */
    public interface LoggerSink {
        /** 由 Kit 调用以输出单行日志。 */
        void log(int level, String label, String message);
    }

    private static volatile int level = LEVEL_DEBUG;
    private static volatile LoggerSink sink;
    private static final SimpleDateFormat TIMESTAMP_FORMAT = createFormatter();

    private static SimpleDateFormat createFormatter() {
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US);
        format.setTimeZone(TimeZone.getTimeZone("UTC"));
        return format;
    }

    /**
     * 设置日志输出回调。
     *
     * @param handler 自定义回调；传 null 恢复为默认 {@code Log} 输出。
     */
    public static void installSink(LoggerSink handler) {
        sink = handler;
    }

    /**
     * 设置日志级别，低于该级别的日志将被丢弃。
     */
    public static void setLevel(int level) {
        ZegoAIAgentActionLogger.level = level;
    }

    /// 输出 DEBUG 级别日志（最低级别）。
    public static void debug(String message) {
        log(LEVEL_DEBUG, "DEBUG", message);
    }

    /// 输出 INFO 级别日志。
    public static void info(String message) {
        log(LEVEL_INFO, "INFO", message);
    }

    /// 输出 WARN 级别日志。
    public static void warn(String message) {
        log(LEVEL_WARN, "WARN", message);
    }

    /// 输出 ERROR 级别日志（最高级别）。
    public static void error(String message) {
        log(LEVEL_ERROR, "ERROR", message);
    }

    private static void log(int level, String label, String message) {
        if (level < ZegoAIAgentActionLogger.level) return;
        String line;
        synchronized (TIMESTAMP_FORMAT) {
            line = "ZegoAIAgentAction [" + label + "] " + TIMESTAMP_FORMAT.format(new Date()) + " " + message;
        }
        if (sink != null) {
            sink.log(level, label, line);
        } else {
            android.util.Log.println(toAndroidLogLevel(level), "ZegoAIAgentAction", line);
        }
    }

    private static int toAndroidLogLevel(int level) {
        switch (level) {
            case LEVEL_DEBUG:
                return android.util.Log.DEBUG;
            case LEVEL_INFO:
                return android.util.Log.INFO;
            case LEVEL_WARN:
                return android.util.Log.WARN;
            case LEVEL_ERROR:
            default:
                return android.util.Log.ERROR;
        }
    }
}
