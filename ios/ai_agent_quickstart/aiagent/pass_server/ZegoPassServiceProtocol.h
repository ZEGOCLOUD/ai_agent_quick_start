//
//  ZegoBIZProtocol.h
//  ai_agent_uikit
//
//  Created by yoer on 2024/2/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 公共请求头
/**
 * @brief 公共请求头
 */
@interface ZegoPassServiceCommonHeader : NSObject

/// AppId，ZEGO 分配的用户唯一凭证
@property (nonatomic, assign) UInt32 appId;

/// 签名，签名的生成请参考文档
@property (nonatomic, copy) NSString *signature;

/// 随机字符串
@property (nonatomic, copy) NSString *signatureNonce;

/// 签名版本号，默认值为 2.0
@property (nonatomic, copy) NSString *signatureVersion;

/// Unix 时间戳，单位为秒，最多允许 10 分钟的误差
@property (nonatomic, assign) int64_t timestamp;

/**
 * 生成签名
 * @param serverSecret 应用密钥
 * @return 生成的签名字符串
 */
- (NSString *)generateSignatureWithServerSecret:(NSString *)serverSecret;

/**
 * 设置签名相关参数
 * @param appId ZEGO 分配的应用 ID
 * @param serverSecret 应用密钥
 */
- (void)setupSignatureWithAppId:(UInt32)appId serverSecret:(NSString *)serverSecret;

/**
 * 将请求头应用到 NSMutableURLRequest
 * @param request 要应用请求头的请求对象
 */
- (void)applyToRequest:(NSMutableURLRequest *)request;

@end

#pragma mark - 公共响应
/**
 * @brief 公共响应结构
 */
@interface ZegoPassServiceCommonResponse : NSObject

/// 错误码，0表示请求成功，其他表示出错
@property (nonatomic, assign) NSInteger code;

/// 错误消息，Succeed表示请求成功
@property (nonatomic, copy) NSString *message;

/// 请求唯一id，联调时提供此id有助于快速排查问题
@property (nonatomic, copy) NSString *requestId;

/// 额外响应数据，按需返回
@property (nonatomic, strong, nullable) NSDictionary *data;

@end

NS_ASSUME_NONNULL_END 
