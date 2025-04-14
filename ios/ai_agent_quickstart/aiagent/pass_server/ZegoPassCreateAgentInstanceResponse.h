//
//  ZegoPassCreateAgentInstanceResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoPassServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoPassCreateAgentInstanceResponse
 * @brief 创建智能体实例响应类
 *
 * 该类封装了创建AI智能体实例的响应数据，
 * 继承自ZegoPassServiceCommonResponse，提供了服务器返回的智能体实例ID。
 * 用于客户端解析和处理创建智能体实例请求的响应结果。
 */
@interface ZegoPassCreateAgentInstanceResponse : ZegoPassServiceCommonResponse

/// 智能体实例ID，创建成功后返回的唯一标识符，用于后续与该智能体实例的交互
@property (nonatomic, copy) NSString *agentInstanceId;

/**
 * 从服务响应创建实例
 * @param response 通用服务响应对象
 * @return 创建的ZegoPassCreateAgentInstanceResponse对象
 */
+ (ZegoPassCreateAgentInstanceResponse *)fromServiceResponse:(ZegoPassServiceCommonResponse *)response;

@end

NS_ASSUME_NONNULL_END 
