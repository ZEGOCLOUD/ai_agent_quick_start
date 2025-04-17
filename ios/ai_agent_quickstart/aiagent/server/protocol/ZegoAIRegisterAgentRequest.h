//
//  ZegoAIRegisterAgentRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 注册Agent请求类
 * @details 用于向服务器发送注册智能体的请求
 */
@interface ZegoAIRegisterAgentRequest : NSObject

@property (nonatomic, copy) NSString *agentId;    // Agent ID，唯一标识
@property (nonatomic, copy) NSString *agentName;  // Agent 名称

/**
 * 将对象转换为字典
 * @return 包含请求参数的字典
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 