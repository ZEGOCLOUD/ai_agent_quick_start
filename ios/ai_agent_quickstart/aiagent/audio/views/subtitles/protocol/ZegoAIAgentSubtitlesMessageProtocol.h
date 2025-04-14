//
//  ZegoAgentMessageContent.h
//  ai_agent_uikit
//
//  Created by Zego 2024/4/11.
//  Copyright © 2024 ZEGO. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 消息命令类型枚举
 *
 * 定义了系统中的各种消息命令类型，用于区分不同类型的消息内容和处理方式。
 * 通过此枚举，系统可以正确解析和处理来自不同来源的消息数据。
 */
typedef NS_ENUM(NSInteger, ZegoAIAgentSubtitlesMessageCommand) {
    /** 用户说话状态 - 表示用户开始或结束说话 */
    ZegoAgentMessageCmdUserSpeakStatus = 1,
    /** 智能体说话状态 - 表示AI智能体开始或结束回复 */
    ZegoAgentMessageCmdAgentSpeakStatus = 2,
    /** 识别的ASR文本 - 语音识别结果 */
    ZegoAgentMessageCmdASRText = 3,
    /** LLM文本 - 大语言模型生成的回复文本 */
    ZegoAgentMessageCmdLLMText = 4,
    /** 统计相关数据 - 仅供内部使用，包含性能和时间统计 */
    ZegoAgentMessageCmdStatistics = 100
};

/**
 * @brief 说话状态枚举
 *
 * 定义了说话过程中的不同状态，用于标记说话的开始和结束。
 * 此状态对于管理音频流和界面提示至关重要。
 */
typedef NS_ENUM(NSInteger, ZegoAIAgentSubtitlesSpeakStatus) {
    /** 说话开始 - 表示用户或AI开始发言 */
    ZegoAgentSpeakStatusStart = 1,
    /** 说话结束 - 表示用户或AI结束发言 */
    ZegoAgentSpeakStatusEnd = 2
};

/**
 * @class ZegoAIAgentSubtitlesSpeakStatusData
 * @brief 说话状态数据模型
 *
 * 封装了用户或智能体说话状态的相关数据，用于传递和存储说话过程中的状态信息。
 * 此类提供了与字典之间的转换方法，便于数据的序列化和反序列化。
 */
@interface ZegoAIAgentSubtitlesSpeakStatusData : NSObject
/** 说话状态 - 表示当前是开始说话还是结束说话 */
@property (nonatomic, assign) ZegoAIAgentSubtitlesSpeakStatus speakStatus;

/**
 * 从字典创建说话状态数据对象
 * @param dict 包含说话状态数据的字典
 * @return 新创建的说话状态数据对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * 将说话状态数据转换为字典
 * @return 包含说话状态数据的字典
 */
- (NSDictionary *)toDictionary;
@end

/**
 * @class ZegoAIAgentSubtitlesASRTextData
 * @brief ASR语音识别文本数据模型
 *
 * 封装了语音识别结果的文本数据，包含识别文本内容、消息ID和结束标识。
 * 此类用于存储和传递语音识别过程中生成的文本信息。
 */
@interface ZegoAIAgentSubtitlesASRTextData : NSObject
/** 用户说话内容的ASR识别文本 */
@property (nonatomic, copy) NSString *text;
/** 消息唯一标识，用于跟踪特定的ASR文本消息 */
@property (nonatomic, copy) NSString *messageId;
/** 结束标识，true表示该轮ASR文本识别已完成 */
@property (nonatomic, assign) BOOL endFlag;

/**
 * 从字典创建ASR文本数据对象
 * @param dict 包含ASR文本数据的字典
 * @return 新创建的ASR文本数据对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * 将ASR文本数据转换为字典
 * @return 包含ASR文本数据的字典
 */
- (NSDictionary *)toDictionary;
@end

/**
 * @class ZegoAIAgentSubtitlesLLMTextData
 * @brief LLM大语言模型文本数据模型
 *
 * 封装了大语言模型生成的回复文本数据，包含文本内容、消息ID和结束标识。
 * 此类用于存储和传递AI回复过程中生成的文本信息。
 */
@interface ZegoAIAgentSubtitlesLLMTextData : NSObject
/** LLM生成的文本内容，包含本次接收的文本片段 */
@property (nonatomic, copy) NSString *text;
/** 消息唯一标识，用于跟踪特定的LLM文本消息 */
@property (nonatomic, copy) NSString *messageId;
/** 结束标识，true表示该轮LLM文本生成已完成 */
@property (nonatomic, assign) BOOL endFlag;

/**
 * 从字典创建LLM文本数据对象
 * @param dict 包含LLM文本数据的字典
 * @return 新创建的LLM文本数据对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * 将LLM文本数据转换为字典
 * @return 包含LLM文本数据的字典
 */
- (NSDictionary *)toDictionary;
@end

/**
 * @class ZegoAIAgentSubtitlesStatisticsData
 * @brief 性能统计数据模型
 *
 * 封装了会话过程中各个阶段的性能统计数据，包括ASR识别、LLM处理和TTS生成的时间统计。
 * 此类主要用于内部性能监控和优化，提供了完整的时间耗时分析。
 */
@interface ZegoAIAgentSubtitlesStatisticsData : NSObject
/** ASR识别耗时(ms)：从用户说话结束到ASR识别完成的时间 */
@property (nonatomic, assign) int asr;
/** 获取自定义Prompt耗时(ms) */
@property (nonatomic, assign) int customPrompt;
/** LLM首个token耗时(ms)：从LLM调用开始到生成首个token的时间 */
@property (nonatomic, assign) int llmFirstToken;
/** TTS首帧耗时(ms)：从LLM首个token到TTS生成首帧音频的时间 */
@property (nonatomic, assign) int ttsFirstAudio;
/** LLM首句耗时(ms)：从LLM首个token到生成首个完整句子的时间 */
@property (nonatomic, assign) int llmFirstSentence;
/** TTS首句耗时(ms)：从LLM首个token到TTS合成首个完整句子的时间 */
@property (nonatomic, assign) int ttsFirstSentence;

/**
 * 从字典创建统计数据对象
 * @param dict 包含统计数据的字典
 * @return 新创建的统计数据对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * 将统计数据转换为字典
 * @return 包含统计数据的字典
 */
- (NSDictionary *)toDictionary;
@end

/**
 * @class ZegoAIAgentSubtitlesMessageProtocol
 * @brief RTC房间事件消息协议类
 *
 * 用户与AI智能体进行对话期间，服务端通过RTC房间自定义消息下发状态信息，
 * 包括用户说话状态、智能体说话状态、ASR识别文本、LLM回复文本等。
 * 客户端监听房间自定义消息，解析对应的状态事件来进行UI刷新。
 * 
 * 此类为消息协议的核心实现，提供了消息的解析、存储和访问功能。
 */
@interface ZegoAIAgentSubtitlesMessageProtocol : NSObject

/** 时间戳(秒)，消息产生的时间 */
@property (nonatomic, assign) int64_t timestamp;

/** 包序列号，保证消息处理的有序性(不保证连续) */
@property (nonatomic, assign) int64_t seqId;

/** 对话轮次，每次用户主动说话轮次增加(不保证连续) */
@property (nonatomic, assign) int64_t round;

/** 消息命令类型，标识消息的具体类型 */
@property (nonatomic, assign) ZegoAIAgentSubtitlesMessageCommand cmdType;

/** 原始数据字典，包含完整的消息内容 */
@property (nonatomic, strong) NSDictionary *data;

/** 
 * 用户说话状态数据
 * 仅当cmdType = ZegoAgentMessageCmdUserSpeakStatus时有效
 */
@property (nonatomic, strong, readonly, nullable) ZegoAIAgentSubtitlesSpeakStatusData *userSpeakData;

/** 
 * 智能体说话状态数据
 * 仅当cmdType = ZegoAgentMessageCmdAgentSpeakStatus时有效
 */
@property (nonatomic, strong, readonly, nullable) ZegoAIAgentSubtitlesSpeakStatusData *agentSpeakData;

/** 
 * ASR文本数据
 * 仅当cmdType = ZegoAgentMessageCmdASRText时有效
 */
@property (nonatomic, strong, readonly, nullable) ZegoAIAgentSubtitlesASRTextData *asrTextData;

/** 
 * LLM文本数据
 * 仅当cmdType = ZegoAgentMessageCmdLLMText时有效
 */
@property (nonatomic, strong, readonly, nullable) ZegoAIAgentSubtitlesLLMTextData *llmTextData;

/** 
 * 统计数据
 * 仅当cmdType = ZegoAgentMessageCmdStatistics时有效
 */
@property (nonatomic, strong, readonly, nullable) ZegoAIAgentSubtitlesStatisticsData *statisticsData;

/**
 * 根据JSON数据初始化消息内容
 * @param jsonDict JSON字典数据
 * @return 消息内容实例
 *
 * 此方法解析JSON数据，创建相应的消息对象并填充属性
 */
- (instancetype)initWithDictionary:(NSDictionary *)jsonDict;

/**
 * 将消息内容转换为JSON字典
 * @return JSON字典数据
 *
 * 此方法将消息对象序列化为JSON格式，便于网络传输或存储
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 
