#import "ZegoAIAgentActionDefines.h"

@implementation ZegoAIAgentActionErrorCodes
+ (NSInteger)success { return 0; }
+ (NSInteger)timeout { return -1; }
+ (NSInteger)sendFailed { return -2; }
+ (NSInteger)canceled { return -3; }
@end

@implementation ZegoAIAgentActionNames
+ (NSString *)sendAgentInstanceTTS { return @"SendAgentInstanceTTS"; }
+ (NSString *)sendAgentInstanceLLM { return @"SendAgentInstanceLLM"; }
+ (NSString *)interruptAgentInstance { return @"InterruptAgentInstance"; }
+ (NSString *)startListening { return @"StartListening"; }
+ (NSString *)stopListening { return @"StopListening"; }
@end

@implementation ZegoAIAgentActionMsgTypes
+ (NSInteger)request { return 20; }
+ (NSInteger)response { return 22; }
@end

@implementation ZegoAIAgentActionExpressMethods
+ (NSString *)sendRoomChannelMessage { return @"liveroom.room.send_room_channel_message"; }
+ (NSString *)onReciveRoomChannelMessage { return @"liveroom.room.on_recive_room_channel_message"; }
+ (NSString *)onSendRoomChannelMessage { return @"liveroom.room.on_send_room_channel_message"; }
@end

@implementation ZegoAIAgentActionExpressKeys
+ (NSString *)method { return @"method"; }
+ (NSString *)params { return @"params"; }
+ (NSString *)roomId { return @"room_id"; }
+ (NSString *)msgType { return @"msg_type"; }
+ (NSString *)msgContent { return @"msg_content"; }
+ (NSString *)userList { return @"user_list"; }
+ (NSString *)seq { return @"seq"; }
+ (NSString *)errorCode { return @"error_code"; }
+ (NSString *)errorMessage { return @"error_message"; }
@end

@implementation ZegoAIAgentActionProtocolKeys
+ (NSString *)action { return @"Action"; }
+ (NSString *)seq { return @"Seq"; }
+ (NSString *)params { return @"Params"; }
+ (NSString *)code { return @"Code"; }
+ (NSString *)message { return @"Message"; }
+ (NSString *)requestId { return @"RequestId"; }
+ (NSString *)data { return @"Data"; }
+ (NSString *)text { return @"Text"; }
+ (NSString *)addHistory { return @"AddHistory"; }
+ (NSString *)priority { return @"Priority"; }
+ (NSString *)samePriorityOption { return @"SamePriorityOption"; }
+ (NSString *)interruptMode { return @"InterruptMode"; }
+ (NSString *)enqueueUserSpeech { return @"EnqueueUserSpeech"; }
+ (NSString *)systemPrompt { return @"SystemPrompt"; }
+ (NSString *)addQuestionToHistory { return @"AddQuestionToHistory"; }
+ (NSString *)addAnswerToHistory { return @"AddAnswerToHistory"; }
+ (NSString *)userId { return @"UserId"; }
@end
