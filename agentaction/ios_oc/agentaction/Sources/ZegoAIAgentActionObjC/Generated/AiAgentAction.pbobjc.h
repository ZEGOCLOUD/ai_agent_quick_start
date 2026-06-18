// Lightweight local model replacement for generated protobuf classes.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPBMessage : NSObject
@property(nonatomic, readwrite, copy, nullable) NSData *data;
+ (instancetype)message;
@end

@interface AiAgentActionRoot : NSObject
@end

@interface AgentActionEnvelope : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *action;
@property(nonatomic, readwrite, copy, nullable) NSString *seq;
@property(nonatomic, readwrite, copy, nullable) NSData *params;
@end

@interface AgentActionResponse : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *action;
@property(nonatomic, readwrite, copy, nullable) NSString *seq;
@property(nonatomic, readwrite) int32_t code;
@property(nonatomic, readwrite, copy, nullable) NSString *message;
@property(nonatomic, readwrite, copy, nullable) NSString *requestId;
@property(nonatomic, readwrite, copy, nullable) NSData *data_p;
@end

@interface SendAgentInstanceTTSParams : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *text;
@property(nonatomic, readwrite) int32_t interruptMode;
@property(nonatomic, readwrite, copy, nullable) NSString *priority;
@property(nonatomic, readwrite, copy, nullable) NSString *samePriorityOption;
@property(nonatomic, readwrite) BOOL enqueueUserSpeech;
// addHistory 用自定义方法实现（手写 stub 加 has* 跟踪，支持 encodeParams 做默认值兜底）。
// 业务方仍可使用 `params.addHistory = YES` 语法（OC 中属性赋值 = setter 调用的语法糖）。
- (BOOL)addHistory;
- (void)setAddHistory:(BOOL)value;
- (BOOL)hasAddHistory;
@end

@interface SendAgentInstanceLLMParams : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *text;
@property(nonatomic, readwrite, copy, nullable) NSString *systemPrompt;
@property(nonatomic, readwrite) BOOL addQuestionToHistory;
@property(nonatomic, readwrite, copy, nullable) NSString *priority;
@property(nonatomic, readwrite, copy, nullable) NSString *samePriorityOption;
@property(nonatomic, readwrite) BOOL enqueueUserSpeech;
// addAnswerToHistory 用自定义方法实现（手写 stub 加 has* 跟踪，支持 encodeParams 做默认值兜底）。
- (BOOL)addAnswerToHistory;
- (void)setAddAnswerToHistory:(BOOL)value;
- (BOOL)hasAddAnswerToHistory;
@end

@interface InterruptAgentInstanceParams : GPBMessage
@end

@interface StartListeningParams : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *userId;
@property(nonatomic, readwrite) int64_t sequence;
@end

@interface StopListeningParams : GPBMessage
@property(nonatomic, readwrite, copy, nullable) NSString *userId;
@property(nonatomic, readwrite) int64_t sequence;
@end

NS_ASSUME_NONNULL_END
