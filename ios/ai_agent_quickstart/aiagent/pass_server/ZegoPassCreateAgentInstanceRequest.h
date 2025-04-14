//
//  ZegoPassCreateAgentInstanceRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoPassAgentConfig.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief RTC相关信息类
 * @details 包含RTC房间信息、流ID和用户ID等
 */
@interface ZegoPassRtcInfo : NSObject

@property (nonatomic, copy) NSString *roomId;             // RTC房间ID
@property (nonatomic, copy) NSString *agentStreamId;      // Agent的流ID
@property (nonatomic, copy) NSString *agentUserId;        // Agent的用户ID
@property (nonatomic, copy) NSString *userStreamId;       // 用户的流ID
@property (nonatomic, copy, nullable) NSString *welcomeMessage;  // 欢迎消息，可选

- (NSDictionary *)toDictionary;

@end

/**
 * @brief 消息历史记录类
 * @details 用于同步历史消息到智能体
 */
@interface ZegoPassMessageHistory : NSObject

@property (nonatomic, assign) NSInteger syncMode;         // 同步模式
@property (nonatomic, strong, nullable) NSArray *messages; // 消息列表
@property (nonatomic, assign) NSInteger windowSize;       // 窗口大小，限制消息数量
@property (nonatomic, copy, nullable) NSString *zimRobotId; // ZIM机器人ID，可选

- (NSDictionary *)toDictionary;

@end

/**
 * @brief 单条消息类
 * @details 定义消息的角色和内容
 */
@interface ZegoPassMessage : NSObject

@property (nonatomic, copy) NSString *role;               // 消息角色，如user或agent
@property (nonatomic, copy) NSString *content;            // 消息内容

- (NSDictionary *)toDictionary;

@end

/**
 * @brief 创建Agent实例请求类
 * @details 用于向PASS服务器发送创建智能体实例的请求
 * 
 * 创建Agent实例的请求参数说明：
 * - agentId: 智能体ID，必须以@RBT#开头，建议内部拼接不做为对客户要求
 * - userId: 用户ID，登录RTC房间使用的真实用户ID
 * - rtcInfo: 关联RTC的相关信息，必选参数
 * - llm: 大模型参数，可选
 * - tts: TTS参数，可选
 * - asr: ASR参数，可选
 * - messageHistory: 历史消息，可选，最多100条
 */
@interface ZegoPassCreateAgentInstanceRequest : NSObject

@property (nonatomic, copy) NSString *agentId;            // Agent的唯一标识，必须以@RBT#开头
@property (nonatomic, copy) NSString *userId;             // 用户ID，登录RTC房间使用的真实用户ID
@property (nonatomic, strong) ZegoPassRtcInfo *rtcInfo;   // RTC相关信息，必选参数
@property (nonatomic, strong, nullable) ZegoPassLLM *llm; // 大模型参数，可选
@property (nonatomic, strong, nullable) ZegoPassTTS *tts; // TTS参数，可选
@property (nonatomic, strong, nullable) ZegoPassASR *asr; // ASR参数，可选
@property (nonatomic, strong, nullable) ZegoPassMessageHistory *messageHistory; // 历史消息，可选，最多100条

- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 