//
//  ZegoPassAgentConfig.h
//  ai_agent_uikit
//
//  Created by Zego 2024/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoPassLLM
 * @brief 大语言模型(LLM)配置类
 *
 * 该类定义了AI智能体使用的大语言模型的配置参数，包括服务URL、API密钥、
 * 模型名称、系统提示词以及生成参数如温度和top-p值等。
 * 这些参数决定了AI智能体的回复风格、能力和行为特征。
 */
@interface ZegoPassLLM : NSObject

/// LLM服务的API端点URL
@property (nonatomic, copy) NSString *url;
/// 访问LLM服务所需的API密钥
@property (nonatomic, copy) NSString *apiKey;
/// 使用的语言模型名称，如"gpt-4"、"claude-3"等
@property (nonatomic, copy) NSString *model;
/// 系统提示词，用于设定AI助手的角色和行为指南
@property (nonatomic, copy, nullable) NSString *systemPrompt;
/// 温度参数(0-1)，控制输出的随机性，值越高回复越多样化
@property (nonatomic, assign) float temperature;
/// Top-P参数(0-1)，控制词汇选择的概率阈值，影响输出多样性
@property (nonatomic, assign) float topP;
/// 其他LLM参数的字典
@property (nonatomic, strong, nullable) NSDictionary *params;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassLLM对象
 */
+ (ZegoPassLLM *)fromDictionary:(NSDictionary *)dict;

@end

/**
 * @class ZegoPassTTS
 * @brief 文本转语音(TTS)配置类
 *
 * 该类定义了文本转语音服务的配置参数，包括TTS供应商、
 * 声音参数、需要过滤的文本内容以及停顿时长等。
 * 这些设置影响AI语音的音色、语速和表达方式。
 */
@interface ZegoPassTTS : NSObject

/// TTS服务提供商，如"azure"、"elevenlabs"等
@property (nonatomic, copy) NSString *vendor;
/// TTS参数字典，包含音色、语速等设置
@property (nonatomic, strong) NSDictionary *params;
/// 需要从TTS中过滤的文本内容数组
@property (nonatomic, strong, nullable) NSArray *filterText;
/// 语句之间的停顿时长(毫秒)
@property (nonatomic, assign) NSInteger pauseDuration;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassTTS对象
 */
+ (ZegoPassTTS *)fromDictionary:(NSDictionary *)dict;

@end

/**
 * @class ZegoPassFilterText
 * @brief TTS文本过滤配置类
 *
 * 该类定义了需要从TTS语音中过滤掉的文本片段的开始和结束标记，
 * 用于在播放语音时排除某些不需要读出的内容。
 */
@interface ZegoPassFilterText : NSObject

/// 过滤文本的开始字符
@property (nonatomic, copy) NSString *beginCharacters;
/// 过滤文本的结束字符
@property (nonatomic, copy) NSString *endCharacters;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassFilterText对象
 */
+ (ZegoPassFilterText *)fromDictionary:(NSDictionary *)dict;

@end

/**
 * @class ZegoPassASR
 * @brief 语音识别(ASR)配置类
 *
 * 该类定义了语音识别服务的配置参数，包括热词和其他自定义参数，
 * 用于提高语音识别的准确性和针对特定领域优化识别效果。
 */
@interface ZegoPassASR : NSObject

/// 热词列表，增强对特定词汇的识别准确率
@property (nonatomic, copy, nullable) NSString *hotWord;
/// ASR附加参数字典
@property (nonatomic, strong, nullable) NSDictionary *params;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassASR对象
 */
+ (ZegoPassASR *)fromDictionary:(NSDictionary *)dict;

@end

/**
 * @class ZegoPassExtensionParam
 * @brief 扩展参数配置类
 *
 * 该类用于存储智能体的额外配置参数，采用键值对形式，
 * 可用于传递不属于标准配置的自定义参数。
 */
@interface ZegoPassExtensionParam : NSObject

/// 参数键名
@property (nonatomic, copy, nullable) NSString *key;
/// 参数值
@property (nonatomic, copy, nullable) NSString *value;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassExtensionParam对象
 */
+ (ZegoPassExtensionParam *)fromDictionary:(NSDictionary *)dict;

@end

/**
 * @class ZegoPassAgentConfig
 * @brief AI智能体主配置类
 *
 * 该类作为AI智能体的主配置容器，整合了LLM、TTS、ASR等所有子配置，
 * 用于创建完整的智能体实例。提供了序列化和反序列化方法，方便与API交互。
 */
@interface ZegoPassAgentConfig : NSObject

/// 智能体名称
@property (nonatomic, copy, nullable) NSString *name;
/// 大语言模型配置
@property (nonatomic, strong) ZegoPassLLM *llm;
/// 文本转语音配置
@property (nonatomic, strong) ZegoPassTTS *tts;
/// 语音识别配置
@property (nonatomic, strong, nullable) ZegoPassASR *asr;
/// 扩展参数数组
@property (nonatomic, strong, nullable) NSDictionary *extensionParams;

/**
 * 将对象转换为字典
 * @return 包含所有属性的NSDictionary
 */
- (NSDictionary *)toDictionary;

/**
 * 从字典创建对象
 * @param dict 包含配置信息的字典
 * @return 新创建的ZegoPassAgentConfig对象
 */
+ (ZegoPassAgentConfig *)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END 
