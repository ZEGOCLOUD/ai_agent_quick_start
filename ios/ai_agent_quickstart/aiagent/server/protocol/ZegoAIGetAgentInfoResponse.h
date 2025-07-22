//
//  ZegoAIGetAgentInfoResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoAIServiceCommonResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIGetAgentInfoResponse
 * @brief 获取Agent Info响应类
 */
@interface ZegoAIGetAgentInfoResponse : ZegoAIServiceCommonResponse

/// agent id
@property (nonatomic, copy) NSString *agentId;

/// agent name
@property (nonatomic, copy) NSString *agentName;

/// ZIM会话ID
@property (nonatomic, copy) NSString *robotId;

@property (nonatomic, assign) BOOL isNewRobotRegistration;

/**
 * 从服务响应创建实例
 * @param response 通用服务响应对象
 * @return 创建的ZegoAIGetAgentInfoResponse对象
 */
+ (ZegoAIGetAgentInfoResponse *)fromServiceResponse:(ZegoAIServiceCommonResponse *)response;

@end

NS_ASSUME_NONNULL_END 
