//
//  ZegoAgentMessageContent.m
//  ai_agent_uikit
//
//  Created by ZEGO on 2024-06-01.
//  Copyright © 2024 ZEGO. All rights reserved.
//

#import "ZegoAIAgentSubtitlesMessageProtocol.h"

#pragma mark - ZegoAgentSpeakStatusData

@implementation ZegoAIAgentSubtitlesSpeakStatusData

- (instancetype)init {
    self = [super init];
    if (self) {
        _speakStatus = 0;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    
    if (self) {
        if (dict[@"SpeakStatus"]) {
            _speakStatus = (ZegoAIAgentSubtitlesSpeakStatus)[dict[@"SpeakStatus"] intValue];
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{@"SpeakStatus": @(self.speakStatus)};
}

@end

#pragma mark - ZegoAgentASRTextData

@implementation ZegoAIAgentSubtitlesASRTextData

- (instancetype)init {
    self = [super init];
    if (self) {
        _text = @"";
        _messageId = @"";
        _endFlag = NO;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [self init];

    if (self) {
        if (dict[@"Text"]) {
            _text = dict[@"Text"];
        }
        if (dict[@"MessageId"]) {
            _messageId = dict[@"MessageId"];
        }
        if (dict[@"EndFlag"]) {
            _endFlag = [dict[@"EndFlag"] boolValue];
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"Text": self.text,
        @"MessageId": self.messageId,
        @"EndFlag": @(self.endFlag)
    };
}

@end

#pragma mark - ZegoAgentLLMTextData

@implementation ZegoAIAgentSubtitlesLLMTextData

- (instancetype)init {
    self = [super init];
    if (self) {
        _text = @"";
        _messageId = @"";
        _endFlag = NO;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    
    if (self) {
        if (dict[@"Text"]) {
            _text = dict[@"Text"];
        }
        if (dict[@"MessageId"]) {
            _messageId = dict[@"MessageId"];
        }
        if (dict[@"EndFlag"]) {
            _endFlag = [dict[@"EndFlag"] boolValue];
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"Text": self.text,
        @"MessageId": self.messageId,
        @"EndFlag": @(self.endFlag)
    };
}

@end

#pragma mark - ZegoAgentStatisticsData

@implementation ZegoAIAgentSubtitlesStatisticsData

- (instancetype)init {
    self = [super init];
    if (self) {
        _asr = 0;
        _customPrompt = 0;
        _llmFirstToken = 0;
        _ttsFirstAudio = 0;
        _llmFirstSentence = 0;
        _ttsFirstSentence = 0;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    if (self) {
        if (dict[@"ASR"]) {
            _asr = [dict[@"ASR"] intValue];
        }
        if (dict[@"CustomPrompt"]) {
            _customPrompt = [dict[@"CustomPrompt"] intValue];
        }
        if (dict[@"LlmFirstToken"]) {
            _llmFirstToken = [dict[@"LlmFirstToken"] intValue];
        }
        if (dict[@"TtsFirstAudio"]) {
            _ttsFirstAudio = [dict[@"TtsFirstAudio"] intValue];
        }
        if (dict[@"LlmFirstSentence"]) {
            _llmFirstSentence = [dict[@"LlmFirstSentence"] intValue];
        }
        if (dict[@"TtsFirstSentence"]) {
            _ttsFirstSentence = [dict[@"TtsFirstSentence"] intValue];
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"ASR": @(self.asr),
        @"CustomPrompt": @(self.customPrompt),
        @"LlmFirstToken": @(self.llmFirstToken),
        @"TtsFirstAudio": @(self.ttsFirstAudio),
        @"LlmFirstSentence": @(self.llmFirstSentence),
        @"TtsFirstSentence": @(self.ttsFirstSentence)
    };
}

@end

#pragma mark - ZegoAgentMessageContent

@implementation ZegoAIAgentSubtitlesMessageProtocol {
    ZegoAIAgentSubtitlesSpeakStatusData *_userSpeakData;
    ZegoAIAgentSubtitlesSpeakStatusData *_agentSpeakData;
    ZegoAIAgentSubtitlesASRTextData *_asrTextData;
    ZegoAIAgentSubtitlesLLMTextData *_llmTextData;
    ZegoAIAgentSubtitlesStatisticsData *_statisticsData;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timestamp = 0;
        _seqId = 0;
        _round = 0;
        _cmdType = 0;
        _data = @{};
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [self init];
    if (self) {
        if (jsonDict[@"Timestamp"]) {
            _timestamp = [jsonDict[@"Timestamp"] longLongValue];
        }
        
        if (jsonDict[@"SeqId"]) {
            _seqId = [jsonDict[@"SeqId"] longLongValue];
        }
        
        if (jsonDict[@"Round"]) {
            _round = [jsonDict[@"Round"] longLongValue];
        }
        
        if (jsonDict[@"Cmd"]) {
            _cmdType = (ZegoAIAgentSubtitlesMessageCommand)[jsonDict[@"Cmd"] intValue];
        }
        
        if (jsonDict[@"Data"] && [jsonDict[@"Data"] isKindOfClass:[NSDictionary class]]) {
            _data = jsonDict[@"Data"];
            // 根据命令类型解析特定数据
            [self parseDataForCmd];
        }
    }
    return self;
}

- (void)parseDataForCmd {
    switch (_cmdType) {
        case ZegoAgentMessageCmdUserSpeakStatus:
            _userSpeakData = [[ZegoAIAgentSubtitlesSpeakStatusData alloc] initWithDictionary:_data];
            break;
            
        case ZegoAgentMessageCmdAgentSpeakStatus:
            _agentSpeakData = [[ZegoAIAgentSubtitlesSpeakStatusData alloc] initWithDictionary:_data];
            break;
            
        case ZegoAgentMessageCmdASRText:
            _asrTextData = [[ZegoAIAgentSubtitlesASRTextData alloc] initWithDictionary:_data];
            break;
            
        case ZegoAgentMessageCmdLLMText:
            _llmTextData = [[ZegoAIAgentSubtitlesLLMTextData alloc] initWithDictionary:_data];
            break;
            
        case ZegoAgentMessageCmdStatistics:
            _statisticsData = [[ZegoAIAgentSubtitlesStatisticsData alloc] initWithDictionary:_data];
            break;
            
        default:
            break;
    }
}

- (void)setData:(NSDictionary *)data {
    _data = data;
    [self parseDataForCmd];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@"Timestamp"] = @(self.timestamp);
    dict[@"SeqId"] = @(self.seqId);
    dict[@"Round"] = @(self.round);
    dict[@"Cmd"] = @(self.cmdType);
    
    // 根据命令类型准备特定数据
    switch (_cmdType) {
        case ZegoAgentMessageCmdUserSpeakStatus:
            if (_userSpeakData) {
                dict[@"Data"] = [_userSpeakData toDictionary];
            } else {
                dict[@"Data"] = @{};
            }
            break;
            
        case ZegoAgentMessageCmdAgentSpeakStatus:
            if (_agentSpeakData) {
                dict[@"Data"] = [_agentSpeakData toDictionary];
            } else {
                dict[@"Data"] = @{};
            }
            break;
            
        case ZegoAgentMessageCmdASRText:
            if (_asrTextData) {
                dict[@"Data"] = [_asrTextData toDictionary];
            } else {
                dict[@"Data"] = @{};
            }
            break;
            
        case ZegoAgentMessageCmdLLMText:
            if (_llmTextData) {
                dict[@"Data"] = [_llmTextData toDictionary];
            } else {
                dict[@"Data"] = @{};
            }
            break;
            
        case ZegoAgentMessageCmdStatistics:
            if (_statisticsData) {
                dict[@"Data"] = [_statisticsData toDictionary];
            } else {
                dict[@"Data"] = @{};
            }
            break;
            
        default:
            dict[@"Data"] = self.data ?: @{};
            break;
    }
    
    return [dict copy];
}

@end 
