//
//  ZegoAIAgentServiceAPI.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoAIAgentServiceAPI.h"

#import <UIKit/UIKit.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import <ZegoExpressEngine/ZegoExpressEventHandler.h>

#import "ZegoKey.h"

#import "ZegoAIAgentSubtitlesMessageDispatcher.h"
#import "ZegoAIGetTokenRequest.h"
#import "ZegoAIGetTokenResponse.h"

typedef void (^JoinRoomCallback)(int errorCode, NSDictionary *extendedData);

@interface ZegoAIAgentServiceAPI () <ZegoEventHandler>

@property (nonatomic, copy) NSString *currentBaseURL;

/// 后台返回的agent instance数据
@property (nonatomic, copy) NSString *agentId;
@property (nonatomic, copy) NSString *agentName;
@property (nonatomic, copy) NSString *agentStreamId;
@property (nonatomic, copy) NSString *agentInstanceId;
/// 播报数字人在RTC房间中的用户ID
@property (nonatomic, copy) NSString *agentUserId;

/// 本地随机生成的数据
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userStreamId;
@property (nonatomic, copy) NSString *roomId;

/// demo digital human
@property (nonatomic, copy) NSString *digitalHumanId;
@property (nonatomic, copy) NSString *digitalHumanConfigId;

/// 当前场景是否需要在登录房间后推本地音频流
@property (nonatomic, assign) BOOL shouldPublishLocalStream;

/// 音频事件处理器
@property (nonatomic, weak) id<ZegoAIAgentAudioEventHandler> audioEventHandler;

/// 数字人事件处理器
@property (nonatomic, weak) id<ZegoAIAgentDigitalHumanEventHandler> digitalHumanEventHandler;

@end

@implementation ZegoAIAgentServiceAPI

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static ZegoAIAgentServiceAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZegoAIAgentServiceAPI alloc] init];
        instance.currentBaseURL = kBaseURL;
        
        // 随机生成的本地用户相关信息
        instance.userId = [self generateRandomIdWithPrefix:@"user_"];
        instance.roomId = [self generateRandomIdWithPrefix:@"room_"];
        instance.userStreamId = [self generateRandomIdWithPrefix:@"stream_user_"];

        instance.digitalHumanId = kDigitalHumanId; // 数字人ID
        instance.digitalHumanConfigId = @"mobile"; // 数字人配置ID
    });
    
    return instance;
}

#pragma mark - Public Methods

- (NSString *)getAgentId {
    return self.agentId;
}

- (NSString *)getAgentInstanceId {
    return self.agentInstanceId;
}

- (NSString *)getAgentUserId {
    return self.agentUserId;
}

- (NSString *)getUserId {
    return self.userId;
}

- (NSString *)getRoomId {
    return self.roomId;
}

- (void)registerAudioEventHandler:(id<ZegoAIAgentAudioEventHandler>)handler {
    self.audioEventHandler = handler;
}

- (void)registerDigitalHumanEventHandler:(id<ZegoAIAgentDigitalHumanEventHandler>)handler {
    self.digitalHumanEventHandler = handler;
}

- (void)getTokenWithCompletion:(void (^)(ZegoAIGetTokenResponse *response))completion {
    NSString *baseUrl = [NSString stringWithFormat:@"%@/api/zego-token", self.currentBaseURL];
    
    // 将userId作为URL参数拼接
    NSString *url = [NSString stringWithFormat:@"%@?userId=%@", baseUrl, self.userId];
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:nil method:@"GET"];
    
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        ZegoAIGetTokenResponse *tokenResponse = [ZegoAIGetTokenResponse fromServiceResponse:response];
        
        if (completion) {
            completion(tokenResponse);
        }
    }];
}

- (void)startDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig))completion {
    __weak typeof(self) weakSelf = self;
    self.shouldPublishLocalStream = YES;

    // 先创建Agent实例，传入新的参数
    [self doStartDigitalHumanWithDigitalHumanId:self.digitalHumanId configId:self.digitalHumanConfigId completion:^(ZegoAIServiceCommonResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        if (response.code != 0) {
            if (completion) {
                completion(NO, response.code, response.message ?: @"创建数字人Agent实例失败", nil);
            }
            return;
        }

        // 从响应中获取后端返回的信息
        NSString *digitalHumanConfig = nil;
        if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
            // 更新从后端返回的agent信息
            if (response.data[@"agent_id"]) {
                strongSelf.agentId = response.data[@"agent_id"];
            }
            if (response.data[@"agent_name"]) {
                strongSelf.agentName = response.data[@"agent_name"];
            }
            if (response.data[@"agent_stream_id"]) {
                strongSelf.agentStreamId = response.data[@"agent_stream_id"];
            }
            if (response.data[@"agent_instance_id"]) {
                strongSelf.agentInstanceId = response.data[@"agent_instance_id"];
            }
            if (response.data[@"agent_user_id"]) {
                strongSelf.agentUserId = response.data[@"agent_user_id"];
            }
            if (response.data[@"digital_human_config"]) {
                digitalHumanConfig = [strongSelf extractDigitalHumanConfigStringFromObject:response.data[@"digital_human_config"]];
            }
        }

        // 创建Agent实例成功后，初始化RTC引擎
        [strongSelf initZegoExpressEngine];
        
        // 
        [strongSelf enableCustomVideoRender];
        
        // 登录房间
        [strongSelf loginRoom:^(int errorCode, NSDictionary *extendedData) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            if (errorCode != 0 && errorCode != 1002001) {
                NSString* errorMsg = [NSString stringWithFormat:@"进入数字人房间失败:%d", errorCode];
                completion(NO, errorCode, errorMsg, nil);
                return;
            }
            
            /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
            NSString *params_publish = @"{\"method\":\"liveroom.audio.set_publish_latency_mode\",\"params\":{\"mode\":1,\"channel\":0}}";
            [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params_publish];
            
            // 对话数字人场景需要在进房后推送本地语音流
            if (strongSelf.shouldPublishLocalStream) {
                [strongSelf startPushlishStream];
            }
            
            if (completion) {
                NSString *configToReturn = digitalHumanConfig ?: @"";
                completion(YES, 0, nil, configToReturn);
            }
        }];
    }];
}

- (void)startLiveDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig))completion {
    __weak typeof(self) weakSelf = self;
    self.shouldPublishLocalStream = NO;

    // 播报数字人只需要创建实例并进入RTC房间拉取智能体流
    [self doStartLiveDigitalHumanWithDigitalHumanId:self.digitalHumanId configId:self.digitalHumanConfigId completion:^(ZegoAIServiceCommonResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        if (response.code != 0) {
            if (completion) {
                completion(NO, response.code, response.message ?: @"创建播报数字人Agent实例失败", nil);
            }
            return;
        }

        NSString *digitalHumanConfig = @"";
        if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
            if (response.data[@"agent_id"]) {
                strongSelf.agentId = response.data[@"agent_id"];
            }
            if (response.data[@"agent_name"]) {
                strongSelf.agentName = response.data[@"agent_name"];
            }
            if (response.data[@"agent_stream_id"]) {
                strongSelf.agentStreamId = response.data[@"agent_stream_id"];
            }
            if (response.data[@"agent_instance_id"]) {
                strongSelf.agentInstanceId = response.data[@"agent_instance_id"];
            }
            if (response.data[@"agent_user_id"]) {
                strongSelf.agentUserId = response.data[@"agent_user_id"];
            }
            if (response.data[@"digital_human_config"]) {
                digitalHumanConfig = [strongSelf extractDigitalHumanConfigStringFromObject:response.data[@"digital_human_config"]];
            }
        }

        [strongSelf initZegoExpressEngine];
        [strongSelf enableCustomVideoRender];

        [strongSelf loginRoom:^(int errorCode, NSDictionary *extendedData) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }

            if (errorCode != 0 && errorCode != 1002001) {
                NSString *errorMsg = [NSString stringWithFormat:@"进入播报数字人房间失败:%d", errorCode];
                if (completion) {
                    completion(NO, errorCode, errorMsg, nil);
                }
                return;
            }

            if (completion) {
                completion(YES, 0, nil, digitalHumanConfig ?: @"");
            }
        }];
    }];
}

- (void)stopDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion {
    __weak typeof(self) weakSelf = self;
    
    // 先停止聊天
    [self doStopDigitalHumanWithCompletion:^(ZegoAIServiceCommonResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        // 无论停止聊天是否成功，都释放RTC资源
        [strongSelf unInitZegoExpressEngine];
        
        // 清空后台返回的agent instance数据
        strongSelf.agentId = nil;
        strongSelf.agentName = nil;
        strongSelf.agentStreamId = nil;
        strongSelf.agentInstanceId = nil;
        strongSelf.agentUserId = nil;
        strongSelf.shouldPublishLocalStream = NO;
        
        if (response.code == 0) {
            if (completion) {
                completion(YES, 0, nil);
            }
        } else {
            if (completion) {
                completion(NO, response.code, response.message ?: @"停止聊天失败");
            }
        }
    }];
}

- (void)stopLiveDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion {
    // 播报数字人停止逻辑与数字人对话共用同一个 stop 接口
    [self stopDigitalHumanWithCompletion:completion];
}

- (void)startAudioWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion {
    __weak typeof(self) weakSelf = self;
    self.shouldPublishLocalStream = YES;
    
    // 先创建Agent实例
    [self doStartAudioWithCompletion:^(ZegoAIServiceCommonResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        if (response.code != 0) {
            if (completion) {
                completion(NO, response.code, response.message ?: @"创建Agent实例失败");
            }
            return;
        }
        
        // 从响应中获取后端返回的信息
        if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
            // 更新从后端返回的agent信息
            if (response.data[@"agent_id"]) {
                strongSelf.agentId = response.data[@"agent_id"];
            }
            if (response.data[@"agent_name"]) {
                strongSelf.agentName = response.data[@"agent_name"];
            }
            if (response.data[@"agent_stream_id"]) {
                strongSelf.agentStreamId = response.data[@"agent_stream_id"];
            }
            if (response.data[@"agent_instance_id"]) {
                strongSelf.agentInstanceId = response.data[@"agent_instance_id"];
            }
            if (response.data[@"agent_user_id"]) {
                strongSelf.agentUserId = response.data[@"agent_user_id"];
            }
        }
        
        // 创建Agent实例成功后，初始化RTC引擎
        [strongSelf initZegoExpressEngine];
        
        // 登录房间
        [strongSelf loginRoom:^(int errorCode, NSDictionary *extendedData) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            if (errorCode != 0 && errorCode != 1002001) {
                NSString* errorMsg = [NSString stringWithFormat:@"进入语音房间失败:%d", errorCode];
                completion(NO, errorCode, errorMsg);
                return;
            }
            
            /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
            NSString *params_publish = @"{\"method\":\"liveroom.audio.set_publish_latency_mode\",\"params\":{\"mode\":1,\"channel\":0}}";
            [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params_publish];
            
            // 音频对话场景需要推送本地语音流
            if (strongSelf.shouldPublishLocalStream) {
                [strongSelf startPushlishStream];
            }
            
            if (completion) {
                completion(YES, 0, nil);
            }
        }];
    }];
}

- (void)stopAudioWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion {
    __weak typeof(self) weakSelf = self;
    
    // 先停止聊天
    [self doStopAudioWithCompletion:^(ZegoAIServiceCommonResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        // 无论停止聊天是否成功，都释放RTC资源
        [strongSelf unInitZegoExpressEngine];
        
        // 清空后台返回的agent instance数据
        strongSelf.agentId = nil;
        strongSelf.agentName = nil;
        strongSelf.agentStreamId = nil;
        strongSelf.agentInstanceId = nil;
        strongSelf.agentUserId = nil;
        strongSelf.shouldPublishLocalStream = NO;
        
        if (response.code == 0) {
            if (completion) {
                completion(YES, 0, nil);
            }
        } else {
            if (completion) {
                completion(NO, response.code, response.message ?: @"停止聊天失败");
            }
        }
    }];
}

- (void)sendAgentInstanceTTSWithText:(NSString *)text
                          completion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion {
    // 播报数字人主动播报依赖 agent_instance_id，因此这里先做本地校验
    if (text.length == 0) {
        if (completion) {
            completion(NO, 400, @"播报文本不能为空");
        }
        return;
    }

    if (self.agentInstanceId.length == 0) {
        if (completion) {
            completion(NO, 400, @"当前没有可用的播报数字人实例");
        }
        return;
    }

    NSString *url = [NSString stringWithFormat:@"%@/api/send-agent-instance-tts", self.currentBaseURL];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"agent_instance_id"] = self.agentInstanceId;
    params[@"text"] = text;

    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response.code == 0, response.code, response.message);
        }
    }];
}

#pragma mark - Agent Instance API Methods

- (void)doStartDigitalHumanWithDigitalHumanId:(NSString * _Nullable)digitalHumanId
                                     configId:(NSString * _Nullable)configId
                                   completion:(void (^)(ZegoAIServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/start-digital-human", self.currentBaseURL];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    // 添加本地用户的相关参数
    params[@"room_id"] = self.roomId;
    params[@"user_id"] = self.userId;
    params[@"user_stream_id"] = self.userStreamId;
    
    // 添加数字人的相关参数
    if (digitalHumanId && digitalHumanId.length > 0) {
        params[@"digital_human_id"] = digitalHumanId;
    }
    if (configId && configId.length > 0) {
        params[@"config_id"] = configId;
    }

    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];

    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}

- (void)doStartLiveDigitalHumanWithDigitalHumanId:(NSString * _Nullable)digitalHumanId
                                         configId:(NSString * _Nullable)configId
                                       completion:(void (^)(ZegoAIServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/start-live-digital-human", self.currentBaseURL];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"room_id"] = self.roomId;

    if (digitalHumanId && digitalHumanId.length > 0) {
        params[@"digital_human_id"] = digitalHumanId;
    }
    if (configId && configId.length > 0) {
        params[@"config_id"] = configId;
    }

    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}

- (void)doStopDigitalHumanWithCompletion:(void (^)(ZegoAIServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/stop", self.currentBaseURL];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    // 添加agent_instance_id参数
    if (self.agentInstanceId) {
        params[@"agent_instance_id"] = self.agentInstanceId;
    }
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}

- (void)doStartAudioWithCompletion:(void (^)(ZegoAIServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/start", self.currentBaseURL];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    // 添加随机生成的参数
    params[@"room_id"] = self.roomId;
    params[@"user_id"] = self.userId;
    params[@"user_stream_id"] = self.userStreamId;
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}

- (void)doStopAudioWithCompletion:(void (^)(ZegoAIServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/stop", self.currentBaseURL];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    // 添加agent_instance_id参数
    if (self.agentInstanceId) {
        params[@"agent_instance_id"] = self.agentInstanceId;
    }
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:params method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoAIServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}

#pragma mark - RTC API Methods

-(void)initZegoExpressEngine{
    NSLog(@"开始初始化ZegoExpressEngine");
    
    ZegoEngineProfile* profile = [[ZegoEngineProfile alloc]init];
    profile.appID = kZegoAppId;
    profile.scenario = ZegoScenarioHighQualityChatroom; //设置该场景可以避免申请相机权限，接入方应按自己的业务场景设置具体值
    
    ZegoEngineConfig* engineConfig = [[ZegoEngineConfig alloc] init];
    engineConfig.advancedConfig = @{
        @"set_audio_volume_ducking_mode":@1,/**该配置是用来做音量闪避的**/
        @"enable_rnd_volume_adaptive":@"true",/**该配置是用来做播放音量自适用**/
        //数字人
        @"sideinfo_callback_version":@(3),
        @"sideinfo_bound_to_video_decoder":@"true"
    };
    
    [ZegoExpressEngine setEngineConfig:engineConfig];
    [ZegoExpressEngine createEngineWithProfile:profile eventHandler:self];
    NSLog(@"ZegoExpressEngine创建成功");
}

-(void)unInitZegoExpressEngine{
    NSLog(@"开始释放ZegoExpressEngine资源");
    
    if ([ZegoExpressEngine sharedEngine] == nil) {
        NSLog(@"ZegoExpressEngine实例不存在，无需释放");
        return;
    }
    
    NSLog(@"停止播放流：streamID=%@", self.agentStreamId);
    [[ZegoExpressEngine sharedEngine] stopPlayingStream:self.agentStreamId];
    
    NSLog(@"停止推流");
    [[ZegoExpressEngine sharedEngine] stopPublishingStream];
    
    NSLog(@"开始登出房间");
    [[ZegoExpressEngine sharedEngine] logoutRoomWithCallback:^(int errorCode, NSDictionary * _Nonnull extendedData) {
        NSLog(@"登出房间结果: errorCode=%d", errorCode);
    }];
    
    NSLog(@"开始销毁引擎");
    [ZegoExpressEngine destroyEngine:^{
        NSLog(@"ZegoExpressEngine已成功销毁");
    }];
}

-(void)enable3A{
    NSLog(@"启用AGC（自动增益控制）");
    [[ZegoExpressEngine sharedEngine] enableAGC:TRUE];
    
    NSLog(@"启用AEC（回声消除），模式：ZegoAECModeAIAggressive");
    [[ZegoExpressEngine sharedEngine] enableAEC:TRUE];
    [[ZegoExpressEngine sharedEngine] setAECMode:ZegoAECModeAIBalanced];
    
    NSLog(@"启用ANS（噪声抑制），模式：ZegoANSModeAggressive");
    [[ZegoExpressEngine sharedEngine] enableANS:TRUE];
    [[ZegoExpressEngine sharedEngine] setANSMode:ZegoANSModeMedium];
}

-(void)startPushlishStream{
    NSLog(@"开始推流：streamID=%@", self.userStreamId);
    [[ZegoExpressEngine sharedEngine] muteMicrophone:NO];
    [[ZegoExpressEngine sharedEngine] startPublishingStream:self.userStreamId
                                                    channel:ZegoPublishChannelMain];
}

-(void)loginRoom:(JoinRoomCallback)complete{
    NSLog(@"准备登录房间: roomID=%@, userID=%@", self.roomId, self.userId);
    
    /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
    ZegoEngineConfig *engineConfig = [[ZegoEngineConfig alloc] init];
    engineConfig.advancedConfig = @{
        @"enforce_audio_loopback_in_sync": @"true"
    };
    [ZegoExpressEngine setEngineConfig:engineConfig];
    NSLog(@"已设置音频回环同步配置");
    
    //这个设置只影响AEC（回声消除），我们这里设置为ModeGeneral，是会走我们自研的回声消除，这比较可控，
    //如果其他选项，可能会走系统的回声消除，这在iphone手机上效果可能会更好，但如果在一些android机上效果可能不好
    [[ZegoExpressEngine sharedEngine] setAudioDeviceMode:ZegoAudioDeviceModeGeneral];
    NSLog(@"已设置音频设备模式: ZegoAudioDeviceModeGeneral");
    
    //请注意：开启AI降噪需要联系即构同学拿对应的ZegoExpressionEngine.xcframework，具备该能力的版本还未发布
    [self enable3A];
    NSLog(@"已启用3A功能（AEC、AGC、ANS）");
    
    __weak typeof(self) weakSelf = self;
    
    // 先获取token，然后再登录房间
    [self getTokenWithCompletion:^(ZegoAIGetTokenResponse *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        if (response.code != 0 || !response.token) {
            NSLog(@"获取token失败: code=%ld, message=%@", (long)response.code, response.message);
            complete(-1, @{@"error": @"获取token失败"});
            return;
        }
        
        NSString *token = response.token;
        NSLog(@"获取token成功: token=%@, userId=%@, expireTime=%f", token, response.userId, response.expireTime);
        
        ZegoRoomConfig* roomConfig = [[ZegoRoomConfig alloc] init];
        roomConfig.isUserStatusNotify = YES;
        roomConfig.token = token;
        
        ZegoUser* user = [[ZegoUser alloc] init];
        user.userName = strongSelf.userId;
        user.userID = strongSelf.userId;
        
        NSLog(@"开始登录房间...");
        [[ZegoExpressEngine sharedEngine] loginRoom:strongSelf.roomId
                                               user:user
                                             config:roomConfig
                                           callback:^(int errorCode, NSDictionary * _Nonnull extendedData) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSLog(@"loginRoom 调用结果: code=%d, roomID=%@", errorCode, strongSelf.roomId);
            
            if (errorCode != 0 && errorCode != 1002001) {
                // 由于写死了房间ID，1002001(登录多个房间报错)默认认为成功
                NSLog(@"loginRoom 失败: code=%d, extendedData=%@", errorCode, extendedData);
                complete(errorCode, extendedData);
                return;
            }
            
            NSLog(@"loginRoom 成功: roomID=%@", strongSelf.roomId);
            complete(errorCode, extendedData);
        }];
    }];
}

-(void)startPlayStream:(NSString*)streamId{
    NSLog(@"开始拉流：streamID=%@", streamId);
    [[ZegoExpressEngine sharedEngine] setPlayStreamBufferIntervalRange:streamId min:0 max:2000];
    [[ZegoExpressEngine sharedEngine] startPlayingStream:streamId];
    
    /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
    NSString *params = [NSString stringWithFormat:@"{\"method\":\"liveroom.audio.set_play_latency_mode\",\"params\":{\"mode\":1,\"stream_id\":\"%@\"}}", streamId];
    [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params];
    NSLog(@"拉流延迟模式设置完成：streamID=%@", streamId);
}

- (BOOL)enableCustomVideoRender {
    // 自定义渲染
    ZegoCustomVideoRenderConfig *renderConfig =
    [[ZegoCustomVideoRenderConfig alloc] init];
    // 选择 RawData 类型视频帧数据
    renderConfig.bufferType = ZegoVideoBufferTypeRawData;
    // 选择 RGB 色系数据格式
    renderConfig.frameFormatSeries = ZegoVideoFrameFormatSeriesRGB;
    // 指定在自定义视频渲染的同时引擎也渲染
    renderConfig.enableEngineRender = NO;
    
    ZegoExpressEngine *engine = [ZegoExpressEngine sharedEngine];
    if (!engine) {
        NSLog(@"ZegoExpressEngine未初始化，无法启用自定义视频渲染");
        return NO;
    }
    
    [engine enableCustomVideoRender:YES config:renderConfig];
    [engine setCustomVideoRenderHandler:self];
    
    NSLog(@"自定义视频渲染启用成功");
    return YES;
}

#pragma mark - delegate ZegoEventHandler
//监听房间流信息更新状态，调用智能体流播放
- (void)onRoomStreamUpdate:(ZegoUpdateType)updateType
                streamList:(NSArray<ZegoStream *> *)streamList
              extendedData:(nullable NSDictionary *)extendedData
                    roomID:(NSString *)roomID{
    NSLog(@"房间流更新: roomID=%@, 更新类型=%@, 流数量=%lu", roomID, updateType == ZegoUpdateTypeAdd ? @"新增" : @"移除", (unsigned long)streamList.count);
    
    if (updateType == ZegoUpdateTypeAdd) {
        for (int i=0; i<streamList.count; i++) {
            ZegoStream* item = [streamList objectAtIndex:i];
            NSLog(@"检测到新增流: streamID=%@, stream用户=%@, agentStreamId=%@", item.streamID, item.user.userID, self.agentStreamId);
            
            if ([item.streamID isEqualToString: self.agentStreamId]) {
                NSLog(@"匹配到目标流，准备播放: streamID=%@", self.agentStreamId);
                [self startPlayStream:self.agentStreamId];
                break;
            } else {
                NSLog(@"未匹配到目标流%@", item.streamID);
            }
        }
    } else if(updateType == ZegoUpdateTypeDelete) {
        for (int i=0; i<streamList.count; i++) {
            ZegoStream* item = [streamList objectAtIndex:i];
            NSLog(@"检测到移除流: streamID=%@, 正在停止播放", item.streamID);
            [[ZegoExpressEngine sharedEngine] stopPlayingStream:item.streamID];
        }
    }
}

//2. RTC房间事件消息协议
//实时音视频 服务端 API 推送自定义消息 - 开发者中心 - ZEGO即构科技
- (void)onRecvExperimentalAPI:(NSString *)content{
    // 抛出给音频事件处理器处理
    if (self.audioEventHandler && [self.audioEventHandler respondsToSelector:@selector(onRecvExperimentalAPI:)]) {
        [self.audioEventHandler onRecvExperimentalAPI:content];
    }
}

// 同步视频帧到数字人
- (void)onRemoteVideoFrameRawData:(unsigned char **)data
                       dataLength:(unsigned int *)dataLength
                            param:(ZegoVideoFrameParam *)param
                         streamID:(NSString *)streamID {
    // 抛出给数字人事件处理器处理
    if (self.digitalHumanEventHandler && [self.digitalHumanEventHandler respondsToSelector:@selector(onRemoteVideoFrameRawData:dataLength:param:streamID:)]) {
        [self.digitalHumanEventHandler onRemoteVideoFrameRawData:data dataLength:dataLength param:param streamID:streamID];
    }
}

- (void)onPlayerSyncRecvSEI:(NSData *)data streamID:(NSString *)streamID{
    // 抛出给数字人事件处理器处理
    if (self.digitalHumanEventHandler && [self.digitalHumanEventHandler respondsToSelector:@selector(onPlayerSyncRecvSEI:streamID:)]) {
        [self.digitalHumanEventHandler onPlayerSyncRecvSEI:data streamID:streamID];
    }
}

#pragma mark - Http API Methods

- (NSMutableURLRequest *)createRequestWithURL:(NSString *)urlString
                                     params:(NSDictionary *)params
                                    method:(NSString *)method {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = method;
    
    // 设置通用请求头
    ZegoAIServiceCommonHeader *header = [[ZegoAIServiceCommonHeader alloc] init];
    [header applyToRequest:request];
    
    // 如果是POST请求且有参数，设置请求体
    if ([method isEqualToString:@"POST"] && params) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (!error) {
            request.HTTPBody = jsonData;
        }
    }
    
    return request;
}

- (void)sendRequest:(NSMutableURLRequest *)request
         completion:(void(^)(ZegoAIServiceCommonResponse *response))completion {
    // 打印请求信息
    NSLog(@"\n=== HTTP Request ===\nURL: %@\nMethod: %@\nHeaders: %@\nBody: %@\n==================",
          request.URL,
          request.HTTPMethod,
          request.allHTTPHeaderFields,
          [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                           completionHandler:^(NSData * _Nullable data,
                                                            NSURLResponse * _Nullable response,
                                                            NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ZegoAIServiceCommonResponse *httpResponse = [[ZegoAIServiceCommonResponse alloc] init];
            
            // 打印响应信息
            NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *)response;
            NSString *responseBody = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
            NSLog(@"\n=== HTTP Response ===\nURL: %@\nStatus: %ld\nHeaders: %@\nBody: %@\n==================",
                  request.URL,
                  (long)httpUrlResponse.statusCode,
                  httpUrlResponse.allHeaderFields,
                  responseBody);
            
            if (error) {
                httpResponse.code = -1;
                httpResponse.message = @"网络请求失败";
                if (completion) {
                    completion(httpResponse);
                }
                return;
            }
            
            if (httpUrlResponse.statusCode != 200) {
                httpResponse.code = httpUrlResponse.statusCode;
                httpResponse.message = [NSString stringWithFormat:@"服务器错误: %ld", (long)httpUrlResponse.statusCode];
                if (completion) {
                    completion(httpResponse);
                }
                return;
            }
            
            NSError *jsonError;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                httpResponse.code = -2;
                httpResponse.message = @"解析响应数据失败";
                if (completion) {
                    completion(httpResponse);
                }
                return;
            }
            
            // 解析响应数据
            httpResponse.code = [dict[@"code"] integerValue];
            httpResponse.message = dict[@"message"];
            httpResponse.requestId = dict[@"requestId"];
            httpResponse.data = dict;

            if (completion) {
                completion(httpResponse);
            }
        });
    }];
    
    [task resume];
}

// 添加随机ID生成方法
+ (NSString *)generateRandomIdWithPrefix:(NSString *)prefix {
    NSString *randomString = [[NSUUID UUID] UUIDString];
    // 取UUID的前8位作为随机部分
    NSString *shortRandomString = [randomString substringToIndex:8];
    return [NSString stringWithFormat:@"%@%@", prefix, shortRandomString];
}

// 将服务端返回的数字人配置统一转换为字符串，兼容字符串和JSON对象两种返回格式
- (NSString *)extractDigitalHumanConfigStringFromObject:(id)configObject {
    if ([configObject isKindOfClass:[NSString class]]) {
        return (NSString *)configObject;
    }

    if ([NSJSONSerialization isValidJSONObject:configObject]) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:configObject options:0 error:&jsonError];
        if (jsonData != nil && jsonError == nil) {
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ?: @"";
        }
    }

    return @"";
}

@end
