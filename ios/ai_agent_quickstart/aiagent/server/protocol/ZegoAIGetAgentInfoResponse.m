//
//  ZegoAIGetAgentInfoResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIGetAgentInfoResponse.h"

@implementation ZegoAIGetAgentInfoResponse

+ (ZegoAIGetAgentInfoResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response {
    ZegoAIGetAgentInfoResponse *tokenResponse = [[ZegoAIGetAgentInfoResponse alloc] init];
    tokenResponse.code = response.code;
    tokenResponse.message = response.message;
    tokenResponse.requestId = response.requestId;
    
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        tokenResponse.agentId = response.data[@"agent_id"];
        tokenResponse.agentName = response.data[@"agent_name"];
        tokenResponse.robotId = response.data[@"robot_id"];
        tokenResponse.isNewRobotRegistration = [response.data[@"is_new_robot_registration"] boolValue];
    }
    
    return tokenResponse;
}

@end 
