//
//  ZegoPassCreateAgentInstanceResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassCreateAgentInstanceResponse.h"

@implementation ZegoPassCreateAgentInstanceResponse

+ (ZegoPassCreateAgentInstanceResponse *)fromServiceResponse:(ZegoPassServiceCommonResponse *)response {
    ZegoPassCreateAgentInstanceResponse *instanceResponse = [[ZegoPassCreateAgentInstanceResponse alloc] init];
    instanceResponse.code = response.code;
    instanceResponse.message = response.message;
    instanceResponse.requestId = response.requestId;
    
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        instanceResponse.agentInstanceId = response.data[@"AgentInstanceId"];
    }
    
    return instanceResponse;
}

@end 