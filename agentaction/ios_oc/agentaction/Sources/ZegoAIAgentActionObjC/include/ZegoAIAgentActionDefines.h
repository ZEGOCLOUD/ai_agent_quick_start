#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZegoAIAgentActionErrorCodes : NSObject
@property (class, nonatomic, readonly) NSInteger success;
@property (class, nonatomic, readonly) NSInteger timeout;
@property (class, nonatomic, readonly) NSInteger sendFailed;
@property (class, nonatomic, readonly) NSInteger canceled;
@end

@interface ZegoAIAgentActionNames : NSObject
@property (class, nonatomic, readonly) NSString *sendAgentInstanceTTS;
@property (class, nonatomic, readonly) NSString *sendAgentInstanceLLM;
@property (class, nonatomic, readonly) NSString *interruptAgentInstance;
@property (class, nonatomic, readonly) NSString *startListening;
@property (class, nonatomic, readonly) NSString *stopListening;
@end

@interface ZegoAIAgentActionMsgTypes : NSObject
@property (class, nonatomic, readonly) NSInteger request;
@property (class, nonatomic, readonly) NSInteger response;
@end

@interface ZegoAIAgentActionExpressMethods : NSObject
/// 发送房间通道消息的方法名
@property (class, nonatomic, readonly) NSString *sendRoomChannelMessage;
/// 收到房间通道消息的回调方法名
@property (class, nonatomic, readonly) NSString *onReciveRoomChannelMessage;
/// 发送房间通道消息结果的回调方法名
@property (class, nonatomic, readonly) NSString *onSendRoomChannelMessage;
@end

@interface ZegoAIAgentActionExpressKeys : NSObject
@property (class, nonatomic, readonly) NSString *method;
@property (class, nonatomic, readonly) NSString *params;
@property (class, nonatomic, readonly) NSString *roomId;
@property (class, nonatomic, readonly) NSString *msgType;
@property (class, nonatomic, readonly) NSString *msgContent;
@property (class, nonatomic, readonly) NSArray<NSString *> *userList;
@property (class, nonatomic, readonly) NSString *seq;
@property (class, nonatomic, readonly) NSString *errorCode;
@property (class, nonatomic, readonly) NSString *errorMessage;
@end

@interface ZegoAIAgentActionProtocolKeys : NSObject
@property (class, nonatomic, readonly) NSString *action;
@property (class, nonatomic, readonly) NSString *seq;
@property (class, nonatomic, readonly) NSString *params;
@property (class, nonatomic, readonly) NSString *code;
@property (class, nonatomic, readonly) NSString *message;
@property (class, nonatomic, readonly) NSString *requestId;
@property (class, nonatomic, readonly) NSString *data;

// Params 内部字段
@property (class, nonatomic, readonly) NSString *text;
@property (class, nonatomic, readonly) NSString *addHistory;
@property (class, nonatomic, readonly) NSString *priority;
@property (class, nonatomic, readonly) NSString *samePriorityOption;
@property (class, nonatomic, readonly) NSString *interruptMode;
@property (class, nonatomic, readonly) NSString *enqueueUserSpeech;
@property (class, nonatomic, readonly) NSString *systemPrompt;
@property (class, nonatomic, readonly) NSString *addQuestionToHistory;
@property (class, nonatomic, readonly) NSString *addAnswerToHistory;
@property (class, nonatomic, readonly) NSString *userId;
@end

NS_ASSUME_NONNULL_END
