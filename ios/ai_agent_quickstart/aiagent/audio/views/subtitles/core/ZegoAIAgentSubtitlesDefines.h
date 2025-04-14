
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ZegoAIAgentSessionState) {
    SubtitlesSessionState_UNINIT = 0, //未初始化状态
    SubtitlesSessionState_AI_SPEAKING,//AI在讲话
    SubtitlesSessionState_AI_THINKING,//AI在想，LLM大模型推理
    SubtitlesSessionState_AI_LISTEN,  //AI在听
};

@interface ZegoAIAgentSubtitlesCommand : NSObject
@property (nonatomic, assign) int speak_status;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSString* message_id;
@property (nonatomic, assign) BOOL end_flag;
@end

@interface ZegoAIAgentAudioSubtitlesMessage : NSObject
@property (nonatomic, assign) long timestamp;
@property (nonatomic, assign) long seq_id;
@property (nonatomic, assign) long round;
@property (nonatomic, assign) int cmd;
@property (nonatomic, strong) ZegoAIAgentSubtitlesCommand* data;
@end
