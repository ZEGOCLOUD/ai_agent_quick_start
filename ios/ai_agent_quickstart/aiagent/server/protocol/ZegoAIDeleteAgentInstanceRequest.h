//
//  ZegoAIDeleteAgentInstanceRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 删除Agent实例请求类
 * @details 用于向服务器发送删除智能体实例的请求
 */
@interface ZegoAIDeleteAgentInstanceRequest : NSObject

@property (nonatomic, copy) NSString *agentInstanceId;  // 要删除的Agent实例ID

/**
 * 将对象转换为字典
 * @return 包含请求参数的字典
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 