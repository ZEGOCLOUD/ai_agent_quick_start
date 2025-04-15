//
//  ZegoPassServiceAPI.m
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import "ZegoPassServiceAPI.h"

#import <UIKit/UIKit.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import <ZegoExpressEngine/ZegoExpressEventHandler.h>

#import "ZegoPassAgentConfig.h"
#import "ZegoPassRegisterAgentRequest.h"
#import "ZegoPassCreateAgentInstanceRequest.h"
#import "ZegoPassCreateAgentInstanceResponse.h"
#import "ZegoPassDeleteAgentInstanceRequest.h"
#import "ZegoPassKey.h"
#import "ZegoPassServiceProtocol.h"

#import "ZegoAIAgentSubtitlesMessageDispatcher.h"

typedef void (^JoinRoomCallback)(int errorCode, NSDictionary *extendedData);

// 环境 URL
static NSString *const kBaseURL = @"https://aigc-chat-api.zegotech.cn";  // 实际URL需要替换

@interface ZegoPassServiceAPI () <ZegoEventHandler>

@property (nonatomic, copy) NSString *currentBaseURL;
@property (nonatomic, copy) NSString *agentId;
@property (nonatomic, copy) NSString *agentInstanceId;

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *streamToPlay;

@end

@implementation ZegoPassServiceAPI

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static ZegoPassServiceAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZegoPassServiceAPI alloc] init];
        instance.currentBaseURL = kBaseURL;
        
        instance.userId = [self generateRandomUserId];
        instance.roomId = [self generateRandomRoomId];
    });
    return instance;
}

#pragma mark - Public Methods

- (void)initWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    [self registerAgentWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        if (completion) {
            completion(success, errorMessage);
        }
    }];
}

- (void)startChatWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    // 确保agentId已经设置
    if (!self.agentId) {
        if (completion) {
            completion(NO, @"请先调用init方法初始化");
        }
        return;
    }
    
    [self initZegoExpressEngine];
    __weak typeof(self) weakSelf = self;
    [self loginRoom:^(int errorCode, NSDictionary *extendedData) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        if (errorCode!=0) {
            NSString* errorMsg =[NSString stringWithFormat:@"进入语音房间失败:%d", errorCode];
            completion(NO, errorMsg);
            return;
        }
        
        /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
        NSString *params_publish = @"{\"method\":\"liveroom.audio.set_publish_latency_mode\",\"params\":{\"mode\":1,\"channel\":0}}";
        [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params_publish];
        //进房后开始推流
        [strongSelf startPushlishStream];
        
        /// 记录智能体流信息
        strongSelf.streamToPlay = [strongSelf getAgentStreamID];
        
        // 创建Agent实例
        [strongSelf createAgentInstanceWithCompletion:^(ZegoPassCreateAgentInstanceResponse *response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            if (response.code == 0 && response.agentInstanceId) {
                if (completion) {
                    completion(YES, nil);
                }
            } else {
                if (completion) {
                    completion(NO, response.message ?: @"创建Agent实例失败");
                }
            }
        }];
    }];
}

- (void)stopChatWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    [self unInitZegoExpressEngine];
    
    // 删除Agent实例
    [self deleteAgentInstanceWithCompletion:^(ZegoPassServiceCommonResponse *response) {
        if (response.code == 0) {
            if (completion) {
                completion(YES, nil);
            }
        } else {
            if (completion) {
                completion(NO, response.message ?: @"停止聊天失败");
            }
        }
    }];
}

#pragma mark - Agent API Methods

- (void)registerAgentWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    NSString *url = [NSString stringWithFormat:@"%@/?Action=RegisterAgent", self.currentBaseURL];
    
    // 创建默认的Agent配置
    ZegoPassAgentConfig *config = [[ZegoPassAgentConfig alloc] init];
    config.name = @"小智";
    
    // 创建LLM配置
    ZegoPassLLM *llm = [[ZegoPassLLM alloc] init];
    llm.apiKey = kZegoPassLLMApiKey;
    llm.url = kZegoPassLLMUrl;
    llm.model = kZegoPassLLMModel;
    llm.systemPrompt = @"你是小智，成年女性，是**即构科技创造的陪伴助手**，上知天文下知地理，聪明睿智、热情友善。\n对话要求：1、按照人设要求与用户对话。\n2、不能超过100字。";
    config.llm = llm;
    
    // 创建TTS配置
    ZegoPassTTS *tts = [[ZegoPassTTS alloc] init];
    tts.vendor = kZegoPassTTSVendor;
    tts.params = [ZegoPassKey zegoPassTTSParams];
    config.tts = tts;
    
    // 创建请求
    ZegoPassRegisterAgentRequest *request = [[ZegoPassRegisterAgentRequest alloc] init];
    request.agentId = @"zg_agent_t_i";
    request.agentConfig = config;
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:[request toDictionary] method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoPassServiceCommonResponse *response) {
        if (response.code == 0) {
            // 注册成功，保存agentId
            self.agentId = request.agentId;
            if (completion) {
                completion(YES, nil);
            }
        } else if(410001008 == response.code) {
            // 智能体已经注册过了
            self.agentId = request.agentId;
            if (completion) {
                completion(YES, nil);
            }
        } else {
            if (completion) {
                completion(NO, response.message);
            }
        }
    }];
}

#pragma mark - Agent Instance API Methods

-(NSString*)getAgentStreamID {
    return [NSString stringWithFormat:@"%@_%@_agent", self.roomId, self.userId];
}

-(NSString*)getUserStreamID {
    return [NSString stringWithFormat:@"%@_%@_main", self.roomId, self.userId];
}

- (void)createAgentInstanceWithCompletion:(void (^)(ZegoPassCreateAgentInstanceResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/?Action=CreateAgentInstance", self.currentBaseURL];
    
    // 创建RTC信息
    ZegoPassRtcInfo *rtcInfo = [[ZegoPassRtcInfo alloc] init];
    rtcInfo.roomId = self.roomId;
    rtcInfo.agentStreamId = [self getAgentStreamID];
    rtcInfo.agentUserId = self.agentId;
    rtcInfo.userStreamId = [self getUserStreamID];
    rtcInfo.welcomeMessage = @"你好，我是你的智能助手，有什么可以帮助你的？";
    
    // 创建请求
    ZegoPassCreateAgentInstanceRequest *request = [[ZegoPassCreateAgentInstanceRequest alloc] init];
    request.agentId = self.agentId;
    request.userId = self.userId;
    request.rtcInfo = rtcInfo;
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:[request toDictionary] method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoPassServiceCommonResponse *response) {
        ZegoPassCreateAgentInstanceResponse *instanceResponse = [ZegoPassCreateAgentInstanceResponse fromServiceResponse:response];
        if(instanceResponse.code == 0){
            self.agentInstanceId = instanceResponse.agentInstanceId;
        }
        
        if (completion) {
            completion(instanceResponse);
        }
    }];
}

- (void)deleteAgentInstanceWithCompletion:(void (^)(ZegoPassServiceCommonResponse *response))completion {
    NSString *url = [NSString stringWithFormat:@"%@/?Action=DeleteAgentInstance", self.currentBaseURL];
    
    ZegoPassDeleteAgentInstanceRequest *request = [[ZegoPassDeleteAgentInstanceRequest alloc] init];
    request.agentInstanceId = self.agentInstanceId;
    
    NSMutableURLRequest *urlRequest = [self createRequestWithURL:url params:[request toDictionary] method:@"POST"];
    
    [self sendRequest:urlRequest completion:^(ZegoPassServiceCommonResponse *response) {
        if (completion) {
            completion(response);
        }
    }];
}


#pragma mark - RTC API Methods

-(void)initZegoExpressEngine{
    NSLog(@"开始初始化ZegoExpressEngine");
    
    ZegoEngineProfile* profile = [[ZegoEngineProfile alloc]init];
    profile.appID = kZegoPassAppId;
    profile.appSign = kZegoPassAppSign;
    profile.scenario = ZegoScenarioHighQualityChatroom; //设置该场景可以避免申请相机权限，接入方应按自己的业务场景设置具体值
    
    ZegoEngineConfig* engineConfig = [[ZegoEngineConfig alloc] init];
    engineConfig.advancedConfig = @{
        @"set_audio_dump_mode":@1,//取消录制文件大小限制
        @"notify_remote_device_unknown_status": @"true",
        @"notify_remote_device_init_status":@"true",
        @"enforce_audio_loopback_in_sync": @"true", /**该配置用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
        @"set_audio_volume_ducking_mode":@1,/**该配置是用来做音量闪避的**/
        @"enable_rnd_volume_adaptive":@"true",/**该配置是用来做播放音量自适用**/
    };
    
    [ZegoExpressEngine setEngineConfig:engineConfig];
    [ZegoExpressEngine createEngineWithProfile:profile eventHandler:self];
    NSLog(@"ZegoExpressEngine创建成功");
    
    [[ZegoExpressEngine sharedEngine] startSoundLevelMonitor];
    NSLog(@"已启动音量监控");
}

-(void)unInitZegoExpressEngine{
    NSLog(@"开始释放ZegoExpressEngine资源");
    
    if ([ZegoExpressEngine sharedEngine] == nil) {
        NSLog(@"ZegoExpressEngine实例不存在，无需释放");
        return;
    }
    
    NSLog(@"停止音量监控");
    [[ZegoExpressEngine sharedEngine] stopSoundLevelMonitor];
    
    NSLog(@"停止播放流：streamID=%@", self.streamToPlay);
    [[ZegoExpressEngine sharedEngine] stopPlayingStream:self.streamToPlay];
    
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
    [[ZegoExpressEngine sharedEngine] setAECMode:ZegoAECModeAIAggressive];
    
    NSLog(@"启用ANS（噪声抑制），模式：ZegoANSModeAggressive");
    [[ZegoExpressEngine sharedEngine] enableANS:TRUE];
    [[ZegoExpressEngine sharedEngine] setANSMode:ZegoANSModeAggressive];
}

-(void)startPushlishStream{
    NSLog(@"开始推流：streamID=%@", [self getUserStreamID]);
    [[ZegoExpressEngine sharedEngine] muteMicrophone:NO];
    [[ZegoExpressEngine sharedEngine] startPublishingStream:[self getUserStreamID]
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
    
    ZegoRoomConfig* roomConfig = [[ZegoRoomConfig alloc]init];
    roomConfig.isUserStatusNotify = YES;
    ZegoUser* user = [[ZegoUser alloc]init];
    user.userName = self.userId;
    user.userID = self.userId;
    
    NSLog(@"开始登录房间...");
    __weak typeof(self) weakSelf = self;
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomId
                                           user:user
                                         config:roomConfig
                                       callback:^(int errorCode, NSDictionary * _Nonnull extendedData) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"loginRoom 调用结果: code=%d, roomID=%@", errorCode, strongSelf.roomId);
        
        if (errorCode != 0) {
            NSLog(@"loginRoom 失败: code=%d, extendedData=%@", errorCode, extendedData);
            complete(errorCode, extendedData);
            return;
        }
        
        NSLog(@"loginRoom 成功: roomID=%@", strongSelf.roomId);
        complete(errorCode, extendedData);
    }];
}

-(void)startPlayStream:(NSString*)streamId{
    NSLog(@"开始拉流：streamID=%@", streamId);
    [[ZegoExpressEngine sharedEngine] setPlayStreamBufferIntervalRange:streamId min:0 max:4000];
    [[ZegoExpressEngine sharedEngine] startPlayingStream:streamId];
    
    /**下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学**/
    NSString *params = [NSString stringWithFormat:@"{\"method\":\"liveroom.audio.set_play_latency_mode\",\"params\":{\"mode\":1,\"stream_id\":\"%@\"}}", streamId];
    [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params];
    NSLog(@"拉流延迟模式设置完成：streamID=%@", streamId);
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
            NSLog(@"检测到新增流: streamID=%@, 用户=%@", item.streamID, item.user.userID);
            
            if ([item.streamID isEqualToString: self.streamToPlay]) {
                NSLog(@"匹配到目标流，准备播放: streamID=%@", self.streamToPlay);
                [self startPlayStream:self.streamToPlay];
                break;
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
//描述： 用户与Agent进行语音对话期间，服务端通过RTC房间自定义消息下发一些状态信息，
//      比如用户说话状态、机器人说话状态、ASR识别的文本、大模型回答的文本。客户端监听房间自定义消息，解析对应的状态事件来渲染UI
- (void)onRecvExperimentalAPI:(NSString *)content{
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] handleExpressExperimentalAPIContent:content];
}

#pragma mark - Http API Methods

- (NSMutableURLRequest *)createRequestWithURL:(NSString *)urlString
                                     params:(NSDictionary *)params
                                    method:(NSString *)method {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = method;
    
    // 设置通用请求头
    ZegoPassServiceCommonHeader *header = [[ZegoPassServiceCommonHeader alloc] init];
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
         completion:(void(^)(ZegoPassServiceCommonResponse *response))completion {
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
            ZegoPassServiceCommonResponse *httpResponse = [[ZegoPassServiceCommonResponse alloc] init];
            
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
            httpResponse.code = [dict[@"Code"] integerValue];
            httpResponse.message = dict[@"Message"];
            httpResponse.requestId = dict[@"RequestId"];
            httpResponse.data = dict[@"Data"];

            if (completion) {
                completion(httpResponse);
            }
        });
    }];
    
    [task resume];
}

#pragma mark - Utility Methods

+ (NSString *)generateRandomUserId {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < 10; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    return [NSString stringWithFormat:@"user_%@", randomString];
}

+ (NSString *)generateRandomRoomId {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < 10; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    return [NSString stringWithFormat:@"room_%@", randomString];
}

@end
