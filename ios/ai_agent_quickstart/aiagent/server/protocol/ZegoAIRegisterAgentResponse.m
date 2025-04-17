//
//  ZegoAIRegisterAgentResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIRegisterAgentResponse.h"

@implementation ZegoAIRegisterAgentResponse

+ (ZegoAIRegisterAgentResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response {
    ZegoAIRegisterAgentResponse *registerResponse = [[ZegoAIRegisterAgentResponse alloc] init];
    registerResponse.code = response.code;
    registerResponse.message = response.message;
    registerResponse.requestId = response.requestId;
    
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        registerResponse.agentId = response.data[@"agent_id"];
        registerResponse.agentName = response.data[@"agent_name"];
    }
    
    return registerResponse;
}

@end 