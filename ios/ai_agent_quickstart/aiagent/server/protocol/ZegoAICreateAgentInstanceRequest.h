//
//  ZegoAICreateAgentInstanceRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 创建Agent实例请求类
 * @details 用于向服务器发送创建智能体实例的请求
 */
@interface ZegoAICreateAgentInstanceRequest : NSObject

@property (nonatomic, copy) NSString *agentId;        // 注册时使用的Agent ID
@property (nonatomic, copy) NSString *roomId;         // 房间ID
@property (nonatomic, copy) NSString *agentStreamId;  // Agent的流ID
@property (nonatomic, copy) NSString *agentUserId;    // Agent的用户ID
@property (nonatomic, copy) NSString *userStreamId;   // 用户的流ID
@property (nonatomic, copy) NSString *userId;         // 用户ID

/**
 * 将对象转换为字典
 * @return 包含请求参数的字典
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 