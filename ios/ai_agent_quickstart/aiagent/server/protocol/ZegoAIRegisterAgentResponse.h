//
//  ZegoAIRegisterAgentResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoAIServiceCommonResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIRegisterAgentResponse
 * @brief 注册智能体响应类
 *
 * 该类封装了注册AI智能体的响应数据，
 * 继承自ZegoAIServiceCommonResponse，提供了注册后返回的agent_id和agent_name。
 */
@interface ZegoAIRegisterAgentResponse : ZegoAIServiceCommonResponse

/// 注册的智能体ID
@property (nonatomic, copy) NSString *agentId;

/// 注册的智能体名称
@property (nonatomic, copy) NSString *agentName;

/**
 * 从服务响应创建实例
 * @param response 通用服务响应对象
 * @return 创建的ZegoAIRegisterAgentResponse对象
 */
+ (ZegoAIRegisterAgentResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response;

@end

NS_ASSUME_NONNULL_END 