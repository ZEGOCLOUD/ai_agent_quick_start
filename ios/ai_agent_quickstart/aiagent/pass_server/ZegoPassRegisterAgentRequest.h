//
//  ZegoPassRegisterAgentRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoPassAgentConfig.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoPassRegisterAgentRequest
 * @brief 注册智能体请求类
 *
 * 该类封装了注册AI智能体的请求参数，包括智能体名称和描述信息。
 * 在创建智能体实例之前，必须先注册智能体模板，此类提供了构建注册请求的功能。
 * 作为客户端向服务器发起注册智能体请求的数据载体，提供了参数设置和请求构建能力。
 */
@interface ZegoPassRegisterAgentRequest : NSObject

/// 智能体ID，用于唯一标识一个AI智能体
@property (nonatomic, copy) NSString *agentId;
/// 智能体配置，包含LLM、TTS、ASR等完整的智能体配置信息
@property (nonatomic, strong) ZegoPassAgentConfig *agentConfig;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 