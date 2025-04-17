//
//  ZegoAIGetTokenResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoAIServiceCommonResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIGetTokenResponse
 * @brief 获取ZEGO Token响应类
 *
 * 该类封装了获取ZEGO Token的响应数据，
 * 继承自ZegoPassServiceCommonResponse，提供了服务器返回的token信息。
 */
@interface ZegoAIGetTokenResponse : ZegoAIServiceCommonResponse

/// ZEGO服务所需的token
@property (nonatomic, copy) NSString *token;

/// 请求的用户ID
@property (nonatomic, copy) NSString *userId;

/// token的过期时间戳
@property (nonatomic, assign) NSTimeInterval expireTime;

/**
 * 从服务响应创建实例
 * @param response 通用服务响应对象
 * @return 创建的ZegoAIGetTokenResponse对象
 */
+ (ZegoAIGetTokenResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response;

@end

NS_ASSUME_NONNULL_END 
