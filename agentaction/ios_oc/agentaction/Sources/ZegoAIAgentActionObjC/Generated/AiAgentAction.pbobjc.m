#import "AiAgentAction.pbobjc.h"

@implementation GPBMessage

+ (instancetype)message {
    return [[self alloc] init];
}

- (NSData *)data {
    return [NSData data];
}

- (void)setData:(NSData *)data {
}

@end

@implementation AiAgentActionRoot
@end

@implementation AgentActionEnvelope
@end

@implementation AgentActionResponse
@end

@implementation SendAgentInstanceTTSParams {
    // 手写 stub 加 has* 跟踪：业务方调 setAddHistory: 时把 _hasAddHistory 置为 YES，
    // encodeParams 用 hasAddHistory 区分"未设置"和"显式设值"，未设置时兜底为 API 文档默认 true。
    BOOL _addHistory;
    BOOL _hasAddHistory;
}
- (BOOL)addHistory { return _addHistory; }
- (void)setAddHistory:(BOOL)value {
    _addHistory = value;
    _hasAddHistory = YES;
}
- (BOOL)hasAddHistory { return _hasAddHistory; }
@end

@implementation SendAgentInstanceLLMParams {
    // 手写 stub 加 has* 跟踪：业务方调 setAddAnswerToHistory: 时把 _hasAddAnswerToHistory 置为 YES，
    // encodeParams 用 hasAddAnswerToHistory 区分"未设置"和"显式设值"，未设置时兜底为 API 文档默认 true。
    BOOL _addAnswerToHistory;
    BOOL _hasAddAnswerToHistory;
}
- (BOOL)addAnswerToHistory { return _addAnswerToHistory; }
- (void)setAddAnswerToHistory:(BOOL)value {
    _addAnswerToHistory = value;
    _hasAddAnswerToHistory = YES;
}
- (BOOL)hasAddAnswerToHistory { return _hasAddAnswerToHistory; }
@end

@implementation InterruptAgentInstanceParams
@end

@implementation StartListeningParams
@end

@implementation StopListeningParams
@end
