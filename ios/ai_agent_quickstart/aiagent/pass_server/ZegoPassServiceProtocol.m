//
//  ZegoPassServiceProtocol.m
//  ai_agent_uikit
//
//  Created by yoer on 2024/2/17.
//

#import "ZegoPassServiceProtocol.h"

#import <CommonCrypto/CommonDigest.h>

#import "ZegoPassKey.h"

@implementation ZegoPassServiceCommonHeader

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置签名版本号
        _signatureVersion = @"2.0";
        
        // 使用当前时间戳作为 SignatureNonce
        _timestamp = (int64_t)[[NSDate date] timeIntervalSince1970];
        _signatureNonce = [NSString stringWithFormat:@"%lld", _timestamp];
        
        // 从 AppDataManager 获取 AppID
        _appId = (UInt32)kZegoPassAppId;
        
        // 生成签名
        self.signature = [self generateSignatureWithServerSecret:kZegoPassAppSecret];
    }
    return self;
}

- (NSString *)generateSignatureWithServerSecret:(NSString *)serverSecret {
    // Signature = md5(AppId + SignatureNonce + ServerSecret + Timestamp)
    NSString *signString = [NSString stringWithFormat:@"%u%@%@%lld", 
                            self.appId, 
                            self.signatureNonce, 
                            serverSecret, 
                            self.timestamp];
    
    // 计算 MD5
    const char *cStr = [signString UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    // 转换为小写十六进制字符串
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", result[i]];
    }
    
    return md5String;
}

- (void)applyToRequest:(NSMutableURLRequest *)request {
    // 设置通用请求头
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // 获取当前URL
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    
    // 创建查询参数数组
    NSMutableArray *queryItems = components.queryItems ? [components.queryItems mutableCopy] : [NSMutableArray array];
    
    // 添加签名相关的查询参数
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"AppId" value:@(self.appId).stringValue]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"Signature" value:self.signature]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"SignatureNonce" value:self.signatureNonce]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"SignatureVersion" value:self.signatureVersion]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"Timestamp" value:[NSString stringWithFormat:@"%lld", self.timestamp]]];
    
    // 更新URL的查询参数
    components.queryItems = queryItems;
    request.URL = components.URL;
}

@end

@implementation ZegoPassServiceCommonResponse
@end
