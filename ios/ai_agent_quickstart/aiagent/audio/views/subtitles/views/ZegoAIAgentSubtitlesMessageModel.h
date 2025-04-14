//
//  ZegoAIAgentSubtitlesMessageModel.h
//
//  Created by Zego 2024/4/11.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIAgentSubtitlesMessageModel
 * @brief 字幕消息数据模型
 *
 * 该类定义了用于显示在字幕界面上的消息模型，包含消息内容、发送者信息、时间戳等属性。
 * 作为UI展示层和数据层之间的桥梁，此模型将原始消息数据转换为适合UI展示的格式。
 */
@interface ZegoAIAgentSubtitlesMessageModel : NSObject

/// 消息序列号，用于保证消息处理的有序性
@property (nonatomic, assign) int64_t seqId;
/// 对话轮次，每次用户主动说话轮次增加
@property (nonatomic, assign) int64_t round;
/// 是否为用户发送的消息
@property (nonatomic, assign) BOOL isMine;
/// 消息内容文本
@property (nonatomic, strong) NSString *content;
/// 消息发送时间戳(毫秒)
@property (nonatomic, assign) int64_t messageTimeStamp;
/// 消息处理耗时(毫秒)
@property (nonatomic, assign) int64_t costMs;
/// 消息在UI中的边界框，用于布局计算
@property (nonatomic, assign) CGRect boundingBox;
/// 消息唯一标识符
@property (nonatomic, strong) NSString* message_id;
/// 是否为该轮对话的最后一条消息
@property (nonatomic, assign) BOOL end_flag;

/**
 * 消息的简要描述
 * @return 包含消息基本信息的字符串
 *
 * 此方法返回消息的调试描述，主要用于日志和调试
 */
- (NSString*) description;

@end

NS_ASSUME_NONNULL_END
