//
//  ZegoAIAgentChatMessageDispatcher.m
//  ai_agent_uikit
//
//  Created on 2024/7/15.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentSubtitlesMessageDispatcher.h"
#import "ZegoAIAgentSubtitlesMessageProtocol.h"

@interface ZegoAIAgentSubtitlesMessageDispatcher ()

// 存储注册的事件处理对象
@property (nonatomic, strong) NSHashTable<id<ZegoAIAgentSubtitlesEventHandler>> *eventHandlers;
@property (nonatomic, assign) int64_t lastCMD1Seq; // 防止消息乱序
@property (nonatomic, assign) ZegoAIAgentSessionState chatSessionState;

@end

@implementation ZegoAIAgentSubtitlesMessageDispatcher

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static ZegoAIAgentSubtitlesMessageDispatcher *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.eventHandlers = [NSHashTable weakObjectsHashTable];
        self.lastCMD1Seq = 0;
        self.chatSessionState =     SubtitlesSessionState_UNINIT;
    }
    return self;
}

#pragma mark - Public Methods

- (void)registerEventHandler:(id<ZegoAIAgentSubtitlesEventHandler>)handler {
    if (handler) {
        @synchronized (self.eventHandlers) {
            [self.eventHandlers addObject:handler];
        }
    }
}

- (void)unregisterEventHandler:(id<ZegoAIAgentSubtitlesEventHandler>)handler {
    if (handler) {
        @synchronized (self.eventHandlers) {
            [self.eventHandlers removeObject:handler];
        }
    }
}

- (void)handleExpressExperimentalAPIContent:(NSString *)content {
    if (content == nil) {
         NSLog(@"parseExperimentalAPIContent content is nil");
        return;
    }
    
    NSDictionary* contentDict = [self dictFromJson:content];
    if (!contentDict) {
         NSLog(@"parseExperimentalAPIContent content解析失败: %@", content);
        return;
    }
    
    NSString *method = contentDict[@"method"];
    if (![method isEqualToString:@"liveroom.room.on_recive_room_channel_message"]) {
         NSLog(@"parseExperimentalAPIContent 非房间消息: %@", method);
        return;
    }
    
    NSDictionary *params = contentDict[@"params"];
    if (!params) {
         NSLog(@"parseExperimentalAPIContent params为空");
        return;
    }
    
    NSString *msgContent = params[@"msg_content"];
    NSString *sendIdName = params[@"send_idname"];
    NSString *sendNickname = params[@"send_nickname"];
    NSString *roomId = params[@"roomid"];
    
    if (!msgContent || !sendIdName || !roomId) {
         NSLog(@"parseExperimentalAPIContent 参数不完整: msgContent=%@, sendIdName=%@, roomId=%@",
                msgContent, sendIdName, roomId);
        return;
    }
    
    [self handleMessageContent:msgContent userID:sendIdName userName:sendNickname ?: @""];
}

- (void)handleMessageContent:(NSString *)command userID:(NSString *)userID userName:(NSString *)userName{
    if (command == nil) {
        NSLog(@"handleMessageContent command is nil");
        return;
    }
    
    NSDictionary* msgDict = [self dictFromJson:command];
    
    // 创建消息内容对象并保存到变量中
    ZegoAIAgentSubtitlesMessageProtocol *messageProtocol = [[ZegoAIAgentSubtitlesMessageProtocol alloc] initWithDictionary:msgDict];
    
    // 可以直接从messageContent获取数据
    ZegoAIAgentSubtitlesMessageCommand cmd = messageProtocol.cmdType;
    int64_t seqId = messageProtocol.seqId;
    int64_t round = messageProtocol.round;
    int64_t timeStamp = messageProtocol.timestamp;
    
    ZegoAIAgentAudioSubtitlesMessage* cmdMsg = [[ZegoAIAgentAudioSubtitlesMessage alloc] init];
    cmdMsg.cmd = (int)cmd;
    cmdMsg.seq_id = seqId;
    cmdMsg.round = round;
    cmdMsg.timestamp = timeStamp;
    
    if(cmd == ZegoAgentMessageCmdASRText){
        // 收到 asr 文本，更新聊天信息
        if(messageProtocol.asrTextData) {
            NSString* content = messageProtocol.asrTextData.text;
            NSString* message_id = messageProtocol.asrTextData.messageId;
            BOOL end_flag = messageProtocol.asrTextData.endFlag;
            
            NSLog(
                    @"recvasr userID=%@, userName=%@, cmd=%d, seqId=%llu, round=%llu, timeStamp=%llu, content=%@, message_id=%@, end_flag=%d",
                    userID,
                    userName,
                    (int)cmd, seqId, round, timeStamp,
                    content, message_id, end_flag);
            
            cmdMsg.data = [[ZegoAIAgentSubtitlesCommand alloc] init];
            cmdMsg.data.text = content;
            cmdMsg.data.message_id = message_id;
            cmdMsg.data.end_flag = end_flag;
            [self dispatchAsrChatMsg:cmdMsg];
        }
    } else if(cmd == ZegoAgentMessageCmdLLMText){
        // 收到 LLM 文本，更新聊天信息
        if(messageProtocol.llmTextData) {
            NSString* content = messageProtocol.llmTextData.text;
            NSString* message_id = messageProtocol.llmTextData.messageId;
            BOOL end_flag = messageProtocol.llmTextData.endFlag;
            
            NSLog(
                    @"recvllmtts userID=%@, userName=%@, cmd=%d, seqId=%llu, round=%llu, timeStamp=%llu, content=%@, message_id=%@, end_flag=%d",
                    userID, userName, (int)cmd,
                    seqId, round, timeStamp, content, message_id, end_flag);
            
            cmdMsg.data = [[ZegoAIAgentSubtitlesCommand alloc] init];
            cmdMsg.data.text = content;
            cmdMsg.data.message_id = message_id;
            cmdMsg.data.end_flag = end_flag;
            [self dispatchLLMChatMsg:cmdMsg];
        }
    } else if(cmd == ZegoAgentMessageCmdUserSpeakStatus){
        if(messageProtocol.userSpeakData) {
            int speakStatus = (int)messageProtocol.userSpeakData.speakStatus;
            
            if (seqId < self.lastCMD1Seq) {
                NSLog( @"recvcmdstate 收到cmd=1, _lastCMD1Seq=%lld, curSeqId=%lld, 丢弃该消息", self.lastCMD1Seq, seqId);
                return;
            }
            
            NSLog( @"recvcmdstate userID=%@, userName=%@, cmd=%d, seqId=%llu, timeStamp=%llu, speakStatus=%d",
                    userID, userName, (int)cmd, seqId, timeStamp, speakStatus);
            
            if(speakStatus == ZegoAgentSpeakStatusStart){
                NSLog(@"cmd=1 speakStatus=1 正在听");
                self.chatSessionState =     SubtitlesSessionState_AI_LISTEN;
                [self dispatchChatStateChange:    SubtitlesSessionState_AI_LISTEN];
                
            } else if(speakStatus == ZegoAgentSpeakStatusEnd){
                NSLog(@"cmd=1 speakStatus=2 正在想");
                self.chatSessionState =     SubtitlesSessionState_AI_THINKING;
                [self dispatchChatStateChange:    SubtitlesSessionState_AI_THINKING];
            }
            self.lastCMD1Seq = seqId;
        }
    } else if(cmd == ZegoAgentMessageCmdAgentSpeakStatus){
        if(messageProtocol.agentSpeakData) {
            int speakStatus = (int)messageProtocol.agentSpeakData.speakStatus;
            
            NSLog(@"recvcmdstate userID=%@, userName=%@, cmd=%d, seqId=%llu, timeStamp=%llu, speakStatus=%d",
                    userID,
                    userName,
                    (int)cmd, seqId, timeStamp, speakStatus);
            
            if(speakStatus == ZegoAgentSpeakStatusStart){
                NSLog(@"cmd=1 speakStatus=2 正在讲");
                self.chatSessionState =     SubtitlesSessionState_AI_SPEAKING;
                [self dispatchChatStateChange:    SubtitlesSessionState_AI_SPEAKING];
            } else if(speakStatus == ZegoAgentSpeakStatusEnd){
                self.chatSessionState =     SubtitlesSessionState_AI_LISTEN;
                [self dispatchChatStateChange:    SubtitlesSessionState_AI_LISTEN];
            }
        }
    }
}

- (ZegoAIAgentSessionState)getChatSessionState {
    return self.chatSessionState;
}

/** json转dict*/
- (NSDictionary *)dictFromJson:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSError *error;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return nil;
    }
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    if(error) {
        NSLog(@"dictFromJson: Error, json解析失败：%@", error);
        return nil;
    }
    
    return dic;
}

#pragma mark - Private Methods

- (void)dispatchChatStateChange:(ZegoAIAgentSessionState)state {
    @synchronized (self.eventHandlers) {
        for (id<ZegoAIAgentSubtitlesEventHandler> handler in self.eventHandlers) {
            if ([handler respondsToSelector:@selector(onRecvChatStateChange:)]) {
                [handler onRecvChatStateChange:state];
            }
        }
    }
}

- (void)dispatchAsrChatMsg:(ZegoAIAgentAudioSubtitlesMessage*)message {
    @synchronized (self.eventHandlers) {
        for (id<ZegoAIAgentSubtitlesEventHandler> handler in self.eventHandlers) {
            if ([handler respondsToSelector:@selector(onRecvAsrChatMsg:)]) {
                [handler onRecvAsrChatMsg:message];
            }
        }
    }
}

- (void)dispatchLLMChatMsg:(ZegoAIAgentAudioSubtitlesMessage*)message {
    @synchronized (self.eventHandlers) {
        for (id<ZegoAIAgentSubtitlesEventHandler> handler in self.eventHandlers) {
            if ([handler respondsToSelector:@selector(onRecvLLMChatMsg:)]) {
                [handler onRecvLLMChatMsg:message];
            }
        }
    }
}

@end 
