#import "ZegoAIAgentActionLogger.h"

@implementation ZegoAIAgentActionLogger

+ (NSInteger)levelDebug { return 0; }
+ (NSInteger)levelInfo { return 1; }
+ (NSInteger)levelWarn { return 2; }
+ (NSInteger)levelError { return 3; }

static NSInteger _level = 0;
static void (^_sink)(NSString *line) = nil;

+ (void)installSink:(void (^)(NSString * _Nullable))handler {
    _sink = handler;
}

+ (void)setLevel:(NSInteger)level {
    _level = level;
}

+ (void)debug:(NSString *)message {
    [self log:self.levelDebug label:@"DEBUG" message:message];
}

+ (void)info:(NSString *)message {
    [self log:self.levelInfo label:@"INFO" message:message];
}

+ (void)warn:(NSString *)message {
    [self log:self.levelWarn label:@"WARN" message:message];
}

+ (void)error:(NSString *)message {
    [self log:self.levelError label:@"ERROR" message:message];
}

+ (void)log:(NSInteger)level label:(NSString *)label message:(NSString *)message {
    if (level < _level) return;
    NSString *timestamp = [[[NSISO8601DateFormatter alloc] init] stringFromDate:[NSDate date]];
    NSString *line = [NSString stringWithFormat:@"ZegoAIAgentAction [%@] %@ %@", label, timestamp, message];
    if (_sink) {
        _sink(line);
    } else {
        NSLog(@"%@", line);
    }
}

@end
