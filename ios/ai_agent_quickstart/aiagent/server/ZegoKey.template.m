//
//  ZegoKey.m
//  ai_agent_express
//
//  This is a template file. Copy to ZegoKey.m and fill in your own keys.
//

#import "ZegoKey.h"

@implementation ZegoKey

// ZEGO 控制台->项目管理->项目信息->基本信息->AppID
// ZEGOCLOUD console->Projects Management->Project Configuration->Basic Information->AppID
unsigned int const kZegoAppId = ; // 填入您的AppId


// 部署测试业务后台后可获取。https://github.com/ZEGOCLOUD/ai_agent_quick_start_server
// It will be available after deploying the test business backend.https://github.com/ZEGOCLOUD/ai_agent_quick_start_server
NSString * const kBaseURL = @""; // 填入您的业务后台地址

// 您的数字人ID
NSString * const kDigitalHumanId = @"c4b56d5c-db98-4d91-86d4-5a97b507da97"; //  替换您的数字人ID
// 您的数字人静态图片地址
NSString * const kDigitalHumanImageURL = @"https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg"; // 替换您的数字人静态图片地址

@end
