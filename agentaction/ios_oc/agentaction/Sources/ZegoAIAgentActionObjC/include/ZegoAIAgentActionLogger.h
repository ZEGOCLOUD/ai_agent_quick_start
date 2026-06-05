#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Kit 内部使用的日志工具。
///
/// 业务侧可以通过 [ZegoAIAgentActionLogger installSink:] 自定义输出方式（如
/// 仅在 Debug 模式输出、写入文件、接入业务日志框架等）；未安装 sink 时
/// 日志默认通过 `NSLog` 输出。
@interface ZegoAIAgentActionLogger : NSObject

/// 日志级别。
@property (class, nonatomic, readonly) NSInteger levelDebug;
@property (class, nonatomic, readonly) NSInteger levelInfo;
@property (class, nonatomic, readonly) NSInteger levelWarn;
@property (class, nonatomic, readonly) NSInteger levelError;

/// 设置日志输出回调。
///
/// 传入 [handler] 接管日志输出；传入 `nil` 恢复为默认 `NSLog` 输出。
+ (void)installSink:(nullable void (^)(NSString *line))handler;

/// 设置日志级别，低于该级别的日志将被丢弃。
+ (void)setLevel:(NSInteger)level;

+ (void)debug:(NSString *)message;
+ (void)info:(NSString *)message;
+ (void)warn:(NSString *)message;
+ (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
