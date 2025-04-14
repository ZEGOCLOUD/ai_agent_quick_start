//
//  ZegoPassRegisterAgentRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassRegisterAgentRequest.h"

@implementation ZegoPassRegisterAgentRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"AgentId"] = self.agentId;
    dict[@"AgentConfig"] = [self.agentConfig toDictionary];
    return dict;
}

@end 