//
//  ZegoAIGetTokenResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIGetTokenResponse.h"

@implementation ZegoAIGetTokenResponse

+ (ZegoAIGetTokenResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response {
    ZegoAIGetTokenResponse *tokenResponse = [[ZegoAIGetTokenResponse alloc] init];
    tokenResponse.code = response.code;
    tokenResponse.message = response.message;
    tokenResponse.requestId = response.requestId;
    
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        tokenResponse.token = response.data[@"token"];
        tokenResponse.userId = response.data[@"userId"];
        
        id expireTimeObj = response.data[@"expire_time"];
        if (expireTimeObj && [expireTimeObj isKindOfClass:[NSNumber class]]) {
            tokenResponse.expireTime = [expireTimeObj doubleValue];
        }
    }
    
    return tokenResponse;
}

@end 
