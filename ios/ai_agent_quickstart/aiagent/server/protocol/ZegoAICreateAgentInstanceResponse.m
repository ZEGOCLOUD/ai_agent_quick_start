//
//  ZegoAICreateAgentInstanceResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAICreateAgentInstanceResponse.h"

@implementation ZegoAICreateAgentInstanceResponse

+ (ZegoAICreateAgentInstanceResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response {
    ZegoAICreateAgentInstanceResponse *instanceResponse = [[ZegoAICreateAgentInstanceResponse alloc] init];
    instanceResponse.code = response.code;
    instanceResponse.message = response.message;
    instanceResponse.requestId = response.requestId;
    
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        instanceResponse.agentInstanceId = response.data[@"agent_instance_id"];
    }
    
    return instanceResponse;
}

@end 