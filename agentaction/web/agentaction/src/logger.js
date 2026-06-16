/**
 * Kit 内部使用的日志工具。
 *
 * 业务侧可以通过 {@link ZegoAIAgentActionLogger.installSink} 自定义输出方式（如
 * 仅在 Debug 模式输出、写入文件、接入业务日志框架等）；未安装 sink 时
 * 日志默认通过 `console.log` 输出。
 */
(function (root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.ZegoAIAgentActionLogger = factory();
    }
})(typeof self !== 'undefined' ? self : this, function () {
    'use strict';

    const LEVEL_DEBUG = 0;
    const LEVEL_INFO = 1;
    const LEVEL_WARN = 2;
    const LEVEL_ERROR = 3;

    let level = LEVEL_DEBUG;
    let sink = null;

    function timestamp() {
        try {
            return new Date().toISOString();
        } catch (e) {
            return String(Date.now());
        }
    }

    function log(targetLevel, label, message) {
        if (targetLevel < level) return;
        const line = 'ZegoAIAgentAction [' + label + '] ' + timestamp() + ' ' + message;
        if (typeof sink === 'function') {
            try {
                sink(targetLevel, label, line);
                return;
            } catch (e) {
                // 业务 sink 抛错时降级到默认输出，避免影响 Kit 主流程。
            }
        }
        if (targetLevel >= LEVEL_ERROR) {
            console.error(line);
        } else if (targetLevel >= LEVEL_WARN) {
            console.warn(line);
        } else {
            console.log(line);
        }
    }

    return {
        LEVEL_DEBUG: LEVEL_DEBUG,
        LEVEL_INFO: LEVEL_INFO,
        LEVEL_WARN: LEVEL_WARN,
        LEVEL_ERROR: LEVEL_ERROR,

        /**
         * 设置日志输出回调；传 `null` 恢复为默认 `console.log` 输出。
         * @param {((level: number, label: string, line: string) => void)|null} handler
         */
        installSink: function (handler) {
            sink = typeof handler === 'function' ? handler : null;
        },

        /**
         * 设置日志级别，低于该级别的日志将被丢弃。
         * @param {number} newLevel 0=DEBUG / 1=INFO / 2=WARN / 3=ERROR
         */
        setLevel: function (newLevel) {
            level = newLevel;
        },

        /** 输出 DEBUG 级别日志（最低级别）。 */
        debug: function (message) {
            log(LEVEL_DEBUG, 'DEBUG', message);
        },
        /** 输出 INFO 级别日志。 */
        info: function (message) {
            log(LEVEL_INFO, 'INFO', message);
        },
        /** 输出 WARN 级别日志。 */
        warn: function (message) {
            log(LEVEL_WARN, 'WARN', message);
        },
        /** 输出 ERROR 级别日志（最高级别）。 */
        error: function (message) {
            log(LEVEL_ERROR, 'ERROR', message);
        },
    };
});
