//
//  ZegoAIServiceCommonResponse.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIServiceCommonResponse.h"

@implementation ZegoAIServiceCommonResponse

- (BOOL)isSuccess {
    return self.code == 0;
}

- (void)applyToRequest:(NSMutableURLRequest *)request {
    // 通常这个方法在基类中是空实现，由子类重写
    // 因为响应对象本身一般不需要设置请求的头部信息
}

@end

@implementation ZegoAIServiceCommonHeader

- (void)applyToRequest:(NSMutableURLRequest *)request {
    // 设置 Content-Type 为 application/json
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // 可以在这里添加更多通用的头部设置，如认证信息等
    // [request setValue:@"Bearer xxx" forHTTPHeaderField:@"Authorization"];
}

@end 
