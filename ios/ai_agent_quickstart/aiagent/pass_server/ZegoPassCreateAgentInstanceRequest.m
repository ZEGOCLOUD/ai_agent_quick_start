//
//  ZegoPassCreateAgentInstanceRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassCreateAgentInstanceRequest.h"

@implementation ZegoPassRtcInfo

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"RoomId"] = self.roomId;
    dict[@"AgentStreamId"] = self.agentStreamId;
    dict[@"AgentUserId"] = self.agentUserId;
    dict[@"UserStreamId"] = self.userStreamId;
    if (self.welcomeMessage) dict[@"WelcomeMessage"] = self.welcomeMessage;
    return dict;
}

@end

@implementation ZegoPassMessage

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Role"] = self.role;
    dict[@"Content"] = self.content;
    return dict;
}

@end

@implementation ZegoPassMessageHistory

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"SyncMode"] = @(self.syncMode);
    
    if (self.messages) {
        NSMutableArray *messagesArray = [NSMutableArray array];
        for (ZegoPassMessage *message in self.messages) {
            [messagesArray addObject:[message toDictionary]];
        }
        dict[@"Messages"] = messagesArray;
    }
    
    dict[@"WindowSize"] = @(self.windowSize);
    if (self.zimRobotId) dict[@"ZimRobotId"] = self.zimRobotId;
    return dict;
}

@end

@implementation ZegoPassCreateAgentInstanceRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"AgentId"] = self.agentId;
    dict[@"UserId"] = self.userId;
    dict[@"RtcInfo"] = [self.rtcInfo toDictionary];
    
    if (self.llm) dict[@"LLM"] = [self.llm toDictionary];
    if (self.tts) dict[@"TTS"] = [self.tts toDictionary];
    if (self.asr) dict[@"ASR"] = [self.asr toDictionary];
    if (self.messageHistory) dict[@"MessageHistory"] = [self.messageHistory toDictionary];
    
    return dict;
}

@end 