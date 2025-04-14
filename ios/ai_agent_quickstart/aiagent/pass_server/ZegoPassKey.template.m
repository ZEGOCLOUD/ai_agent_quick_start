//
//  ZegoPassKey.m
//  ai_agent_express
//
//  This is a template file. Copy to ZegoPassKey.m and fill in your own keys.
//

#import "ZegoPassKey.h"

@implementation ZegoPassKey

// Auth Keys
unsigned int const kZegoPassAppId = 0; // 填入你的AppId
NSString * const kZegoPassAppSign = @"YOUR_APP_SIGN_HERE";
NSString * const kZegoPassAppSecret = @"YOUR_APP_SECRET_HERE";

// LLM Keys
NSString * const kZegoPassLLMApiKey = @"YOUR_LLM_API_KEY_HERE";
NSString * const kZegoPassLLMUrl = @"YOUR_LLM_API_URL_HERE";
NSString * const kZegoPassLLMModel = @"YOUR_LLM_MODEL_NAME_HERE";

// TTS Params
NSString * const kZegoPassTTSVendor = @"Bytedance";
+ (NSDictionary *)zegoPassTTSParams {
    static NSDictionary *params = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        params = @{
            @"app": @{
                @"appid": @"YOUR_TTS_APP_ID",
                @"token": @"YOUR_TTS_TOKEN",
                @"cluster": @"YOUR_TTS_CLUSTER"
            },
            @"speed_ratio": @1,
            @"volume_ratio": @1,
            @"pitch_ratio": @1,
            @"audio": @{
                @"rate": @24000,
                @"voice_type": @"YOUR_VOICE_TYPE"
            }
        };
    });
    return params;
}

@end 