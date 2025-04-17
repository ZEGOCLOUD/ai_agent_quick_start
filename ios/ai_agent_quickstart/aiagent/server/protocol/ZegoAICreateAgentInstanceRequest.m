//
//  ZegoAICreateAgentInstanceRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAICreateAgentInstanceRequest.h"

@implementation ZegoAICreateAgentInstanceRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"agent_id"] = self.agentId;
    dict[@"user_id"] = self.userId;
    
    // RTC房间信息
    dict[@"room_id"] = self.roomId;
    dict[@"agent_stream_id"] = self.agentStreamId;
    dict[@"agent_user_id"] = self.agentUserId;
    dict[@"user_stream_id"] = self.userStreamId;
    
    return dict;
}

@end 
