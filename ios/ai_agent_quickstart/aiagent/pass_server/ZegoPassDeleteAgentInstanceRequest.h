//
//  ZegoPassDeleteAgentInstanceRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoPassDeleteAgentInstanceRequest
 * @brief 删除智能体实例请求类
 *
 * 该类封装了删除AI智能体实例的请求参数，
 * 用于在不再需要智能体服务时释放相关资源。
 * 作为客户端向PASS服务器发起删除智能体实例请求的数据载体。
 */
@interface ZegoPassDeleteAgentInstanceRequest : NSObject

/// 智能体实例ID，用于唯一标识要删除的智能体实例
@property (nonatomic, copy) NSString *agentInstanceId;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 