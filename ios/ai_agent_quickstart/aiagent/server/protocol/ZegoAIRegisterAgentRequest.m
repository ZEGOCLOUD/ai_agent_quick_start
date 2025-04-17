//
//  ZegoAIRegisterAgentRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIRegisterAgentRequest.h"

@implementation ZegoAIRegisterAgentRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"agent_id"] = self.agentId;
    dict[@"agent_name"] = self.agentName;
    
    return dict;
}

@end 