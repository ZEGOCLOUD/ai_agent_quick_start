//
//  ZegoAICreateAgentInstanceResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoAIServiceCommonResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAICreateAgentInstanceResponse
 * @brief 创建智能体实例响应类
 *
 * 该类封装了创建AI智能体实例的响应数据，
 * 继承自ZegoAIServiceCommonResponse，提供了服务器返回的智能体实例ID。
 */
@interface ZegoAICreateAgentInstanceResponse : ZegoAIServiceCommonResponse

/// 智能体实例ID，创建成功后返回的唯一标识符
@property (nonatomic, copy) NSString *agentInstanceId;

/**
 * 从服务响应创建实例
 * @param response 通用服务响应对象
 * @return 创建的ZegoAICreateAgentInstanceResponse对象
 */
+ (ZegoAICreateAgentInstanceResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response;

@end

NS_ASSUME_NONNULL_END 