//
//  ZegoPassDeleteAgentInstanceRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassDeleteAgentInstanceRequest.h"

@implementation ZegoPassDeleteAgentInstanceRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"AgentInstanceId"] = self.agentInstanceId;
    return dict;
}

@end 