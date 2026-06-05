#import <Foundation/Foundation.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import "ZegoAIAgentActionObjC.h"

static NSString * const kDemoTag = @"ZegoAIAgentActionDemo";

static void DemoLog(NSString *line) {
    NSLog(@"%@ %@", kDemoTag, line);
}

@interface DemoApp : NSObject <ZegoEventHandler>
@property (nonatomic, strong) ZegoAIAgentActionOCClient *client;
@property (nonatomic, assign) uint32_t appID;
@property (nonatomic, copy) NSString *appSign;
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *agentUserId;
@end

@implementation DemoApp

- (void)run {
    self.appID = 0; // 请替换为你的 AppID
    self.appSign = @""; // 请替换为你的 AppSign
    self.roomId = @"room_test";
    self.userId = @"client_A";
    self.agentUserId = @"agent_001";

    // 将 Kit 内部日志同步到控制台。
    [ZegoAIAgentActionLogger installSink:^(NSString *line) {
        DemoLog([NSString stringWithFormat:@"[kit] %@", line]);
    }];
#if DEBUG
    [ZegoAIAgentActionLogger setLevel:ZegoAIAgentActionLogger.levelDebug];
#else
    [ZegoAIAgentActionLogger setLevel:ZegoAIAgentActionLogger.levelWarn];
#endif

    if (self.appID == 0) {
        DemoLog(@"Warning: appID is 0, please fill in your AppID and AppSign");
    }

    // 初始化 SDK
    DemoLog([NSString stringWithFormat:@"createEngineWithProfile appID=%u", self.appID]);
    ZegoEngineProfile *profile = [ZegoEngineProfile new];
    profile.appID = self.appID;
    profile.appSign = self.appSign;
    profile.scenario = ZegoScenarioDefault;
    [ZegoExpressEngine createEngineWithProfile:profile eventHandler:self];

    __weak __typeof(self) weakSelf = self;
    self.client = [[ZegoAIAgentActionOCClient alloc] initWithRoomId:self.roomId
                                                       agentUserId:self.agentUserId
                                                            userId:self.userId
                                                            sender:self
                                                        onResponse:^(ZegoAIAgentActionOCResponse *response) {
        DemoLog([NSString stringWithFormat:@"[response] action=%@ seq=%@ code=%ld message=%@",
                 response.action ?: @"", response.seq ?: @"", (long)response.code, response.message ?: @""]);
    } onError:^(ZegoAIAgentActionOCError *error) {
        DemoLog([NSString stringWithFormat:@"[error] action=%@ seq=%@ code=%@ message=%@",
                 error.action ?: @"", error.seq ?: @"", error.code ?: @"unknown", error.message ?: @""]);
    }];

    // 登录房间
    DemoLog([NSString stringWithFormat:@"loginRoom roomId=%@", self.roomId]);
    ZegoUser *user = [ZegoUser userWithUserID:self.userId userName:self.userId];
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomId user:user];
    DemoLog([NSString stringWithFormat:@"logging in to %@...", self.roomId]);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

    SendAgentInstanceTTSParams *ttsParams = [SendAgentInstanceTTSParams message];
    ttsParams.text = @"你好";
    DemoLog(@"[action] TTS click");
    [self.client sendAgentInstanceTTSWithParams:ttsParams timeoutMs:nil completion:^(ZegoAIAgentActionOCResponse *response, ZegoAIAgentActionOCError *error) {
        if (error) {
            DemoLog([NSString stringWithFormat:@"[action] TTS error: %@", error.message ?: @""]);
        } else {
            DemoLog([NSString stringWithFormat:@"[action] TTS resolved seq=%@", response.seq ?: @""]);
        }
    }];
    (void)weakSelf;

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    [ZegoExpressEngine destroyEngine:nil];
}

// ZegoAIAgentActionOCSender
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params formatedJson:(NSString *)formatedJson completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion {
    DemoLog([NSString stringWithFormat:@"[sender] action=callExperimentalAPI seq=%@", params.seq ?: @""]);
    DemoLog([NSString stringWithFormat:@"[sender] formatedJson=%@", formatedJson ?: @""]);
    @try {
        NSString *result = [[ZegoExpressEngine sharedEngine] callExperimentalAPI:formatedJson];
        DemoLog([NSString stringWithFormat:@"[sender] callExperimentalAPI result=%@", result ?: @""]);
        completion([[ZegoAIAgentActionOCSendResult alloc] initWithErrorCode:ZegoAIAgentActionErrorCodes.success seq:params.seq]);
    } @catch (NSException *e) {
        DemoLog([NSString stringWithFormat:@"[sender] callExperimentalAPI error: %@", e.reason ?: e]);
        [self.client onError:[[ZegoAIAgentActionOCError alloc] initWithSeq:params.seq
                                                                    action:@"unknown"
                                                                      code:@(ZegoAIAgentActionErrorCodes.sendFailed)
                                                                   message:e.reason ?: @""]];
        completion([[ZegoAIAgentActionOCSendResult alloc] initWithErrorCode:ZegoAIAgentActionErrorCodes.sendFailed seq:params.seq]);
    }
}

// ZegoEventHandler
- (void)onRecvExperimentalAPI:(NSString *)content {
    DemoLog([NSString stringWithFormat:@"[express] recv experimental api length=%lu", (unsigned long)content.length]);
    DemoLog([NSString stringWithFormat:@"[express] %@", content ?: @""]);
    [self.client handleRoomChannelMessageWithContent:content];
}

- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    DemoLog([NSString stringWithFormat:@"[roomStateUpdate] roomID=%@ state=%ld errorCode=%d", roomID ?: @"", (long)state, errorCode]);
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        DemoApp *app = [DemoApp new];
        [app run];
    }
    return 0;
}
