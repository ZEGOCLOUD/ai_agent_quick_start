//
//  ZegoPassAgentConfig.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassAgentConfig.h"

@implementation ZegoPassLLM

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Url"] = self.url;
    if (self.apiKey) dict[@"ApiKey"] = self.apiKey;
    dict[@"Model"] = self.model;
    if (self.systemPrompt) dict[@"SystemPrompt"] = self.systemPrompt;
    if (self.temperature > 0) dict[@"Temperature"] = @(self.temperature);
    if (self.topP > 0) dict[@"TopP"] = @(self.topP);
    if (self.params) dict[@"Params"] = self.params;
    return dict;
}

+ (ZegoPassLLM *)fromDictionary:(NSDictionary *)dict {
    ZegoPassLLM *llm = [[ZegoPassLLM alloc] init];
    llm.url = dict[@"Url"];
    llm.apiKey = dict[@"ApiKey"];
    llm.model = dict[@"Model"];
    llm.systemPrompt = dict[@"SystemPrompt"];
    llm.temperature = [dict[@"Temperature"] floatValue];
    llm.topP = [dict[@"TopP"] floatValue];
    llm.params = dict[@"Params"];
    return llm;
}

@end

@implementation ZegoPassFilterText

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"BeginCharacters"] = self.beginCharacters;
    dict[@"EndCharacters"] = self.endCharacters;
    return dict;
}

+ (ZegoPassFilterText *)fromDictionary:(NSDictionary *)dict {
    ZegoPassFilterText *filterText = [[ZegoPassFilterText alloc] init];
    filterText.beginCharacters = dict[@"BeginCharacters"];
    filterText.endCharacters = dict[@"EndCharacters"];
    return filterText;
}

@end

@implementation ZegoPassTTS

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Vendor"] = self.vendor;
    dict[@"Params"] = self.params;
    
    if (self.filterText) {
        NSMutableArray *filterTextArray = [NSMutableArray array];
        for (ZegoPassFilterText *filterText in self.filterText) {
            [filterTextArray addObject:[filterText toDictionary]];
        }
        dict[@"FilterText"] = filterTextArray;
    }
    
    if (self.pauseDuration > 0) {
        dict[@"PauseDuration"] = @(self.pauseDuration);
    }
    return dict;
}

+ (ZegoPassTTS *)fromDictionary:(NSDictionary *)dict {
    ZegoPassTTS *tts = [[ZegoPassTTS alloc] init];
    tts.vendor = dict[@"Vendor"];
    tts.params = dict[@"Params"];
    
    if (dict[@"FilterText"]) {
        NSMutableArray *filterTextArray = [NSMutableArray array];
        for (NSDictionary *filterTextDict in dict[@"FilterText"]) {
            [filterTextArray addObject:[ZegoPassFilterText fromDictionary:filterTextDict]];
        }
        tts.filterText = filterTextArray;
    }
    
    tts.pauseDuration = [dict[@"PauseDuration"] integerValue];
    return tts;
}

@end

@implementation ZegoPassASR

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.hotWord) dict[@"HotWord"] = self.hotWord;
    if (self.params) dict[@"Params"] = self.params;
    return dict;
}

+ (ZegoPassASR *)fromDictionary:(NSDictionary *)dict {
    ZegoPassASR *asr = [[ZegoPassASR alloc] init];
    asr.hotWord = dict[@"HotWord"];
    asr.params = dict[@"Params"];
    return asr;
}

@end

@implementation ZegoPassExtensionParam

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.key) dict[@"Key"] = self.key;
    if (self.value) dict[@"Value"] = self.value;
    return dict;
}

+ (ZegoPassExtensionParam *)fromDictionary:(NSDictionary *)dict {
    ZegoPassExtensionParam *param = [[ZegoPassExtensionParam alloc] init];
    param.key = dict[@"Key"];
    param.value = dict[@"Value"];
    return param;
}

@end

@implementation ZegoPassAgentConfig

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.name) dict[@"Name"] = self.name;
    dict[@"LLM"] = [self.llm toDictionary];
    dict[@"TTS"] = [self.tts toDictionary];
    
    if (self.asr) dict[@"ASR"] = [self.asr toDictionary];
    
    if (self.extensionParams) {
        NSMutableArray *extensionParamsArray = [NSMutableArray array];
        for (ZegoPassExtensionParam *param in self.extensionParams) {
            [extensionParamsArray addObject:[param toDictionary]];
        }
        dict[@"ExtensionParams"] = extensionParamsArray;
    }
    
    return dict;
}

+ (ZegoPassAgentConfig *)fromDictionary:(NSDictionary *)dict {
    ZegoPassAgentConfig *config = [[ZegoPassAgentConfig alloc] init];
    config.name = dict[@"Name"];
    config.llm = [ZegoPassLLM fromDictionary:dict[@"LLM"]];
    config.tts = [ZegoPassTTS fromDictionary:dict[@"TTS"]];
    
    if (dict[@"ASR"]) {
        config.asr = [ZegoPassASR fromDictionary:dict[@"ASR"]];
    }
    
    if (dict[@"ExtensionParams"]) {
        NSMutableArray *extensionParamsArray = [NSMutableArray array];
        for (NSDictionary *paramDict in dict[@"ExtensionParams"]) {
            [extensionParamsArray addObject:[ZegoPassExtensionParam fromDictionary:paramDict]];
        }
        config.extensionParams = extensionParamsArray;
    }
    
    return config;
}

@end 
