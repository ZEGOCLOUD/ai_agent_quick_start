//
//  ZegoAIGetTokenRequest.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIGetTokenRequest.h"

@implementation ZegoAIGetTokenRequest

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"userId"] = self.userId;
    
    return dict;
}

@end 
