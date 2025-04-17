//
//  ZegoAIDeleteAgentInstanceRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIDeleteAgentInstanceRequest.h"

@implementation ZegoAIDeleteAgentInstanceRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"agent_instance_id"] = self.agentInstanceId;
    
    return dict;
}

@end 