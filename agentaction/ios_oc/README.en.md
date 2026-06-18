# iOS Objective-C Usage

The iOS Objective-C AI Agent Action client suite wraps AI Agent instance control over ZEGO Express room channel messages.

## Directory Layout

- `agentaction/`: copyable Objective-C suite (Pod library + Swift Package shell).
- `demo/`: runnable CocoaPods/Xcode demo shell.

> Chinese version: [README.md](./README.md)

## Suite Source

```text
agentaction/
├── ZegoAIAgentActionObjC.podspec     # CocoaPods spec (depends on Protobuf ~> 4.31)
├── Package.swift                     # Lightweight local demo shell (Swift toolchain)
└── Sources/ZegoAIAgentActionObjC/
    ├── include/
    │   ├── ZegoAIAgentActionObjC.h   # Public header (Client, SendParams, Response, Error, Sender protocol)
    │   ├── ZegoAIAgentActionDefines.h
    │   └── ZegoAIAgentActionLogger.h
    ├── ZegoAIAgentActionObjC.m       # Core client
    ├── ZegoAIAgentActionDefines.m
    ├── ZegoAIAgentActionLogger.m
    └── Generated/
        ├── AiAgentAction.pbobjc.h    # protoc-generated protobuf classes
        └── AiAgentAction.pbobjc.m
```

Minimum deployment: iOS 15.0 / macOS 12.0.

## Integration Steps

### 1. Add via CocoaPods (recommended)

Copy `ios_oc/agentaction/` into your iOS project workspace, then in your `Podfile`:

```ruby
pod 'ZegoAIAgentActionObjC', :path => './agentaction'
```

Run `pod install`. The local demo uses `:path => '../agentaction'` because its `Podfile` lives in `ios_oc/demo`.

> The generated `.pbobjc` files depend on the Google Protobuf Objective-C runtime (`GPBProtocolBuffers.h` / `Protobuf` pod), so the actual Objective-C Protobuf integration path is CocoaPods/Xcode. `Package.swift` is kept only as a lightweight local demo shell.

### 2. Import the Header

```objc
#import <ZegoAIAgentActionObjC/ZegoAIAgentActionObjC.h>
```

### 3. Implement the Sender and Bridge to ZEGO Express

The suite talks to ZEGO Express through the `ZegoAIAgentActionOCSender` protocol. The protocol has a single method; internally the suite reuses the same Sender instance for all 5 Actions (TTS / LLM / Interrupt / StartListening / StopListening).

`formatedJson` looks like:

```json
{
  "method": "liveroom.room.send_room_channel_message",
  "params": {
    "room_id":     "room_1",
    "msg_content": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
    "user_list":   ["agent_1"],
    "seq":         1
  }
}
```

Example:

```objc
@interface ZegoAIAgentActionSender : NSObject <ZegoAIAgentActionOCSender>
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *agentUserId;
@end

@implementation ZegoAIAgentActionSender
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion {
    @try {
        NSString *result = [[ZegoExpressEngine sharedEngine] callExperimentalAPI:formatedJson ?: @""];
        if (completion) {
            completion([[ZegoAIAgentActionOCSendResult alloc]
                        initWithErrorCode:ZegoAIAgentActionErrorCodes.success
                                       seq:params.seq ?: @""]);
        }
    } @catch (NSException *exception) {
        if (completion) {
            completion([[ZegoAIAgentActionOCSendResult alloc]
                        initWithErrorCode:ZegoAIAgentActionErrorCodes.sendFailed
                                       seq:params.seq ?: @""]);
        }
    }
}
@end
```

### 3.1 Sender Protocol Method (Recommended)

The `ZegoAIAgentActionOCSender` protocol is declared as follows. Implementing this single method is enough to bridge all 5 Actions to ZEGO Express:

```objc
@protocol ZegoAIAgentActionOCSender <NSObject>
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion;
@end
```

Parameter meanings:

| Parameter | Description |
|---|---|
| `params` | Suite-built request meta (`roomId / msgType(=20) / userList(=[agentUserId]) / seq`) |
| `formatedJson` | Suite-built JSON envelope; pass it straight into `callExperimentalAPI:` on Express |
| `completion` | Required callback; report the send outcome (success/failure + `seq`) back to the suite for seq timeout and failure bookkeeping |

**Reuse pattern**: You only need to write one `id<ZegoAIAgentActionOCSender>` implementation and inject it into `ZegoAIAgentActionOCClient`. All 5 Actions go through the same Sender. Prefer a singleton or a long-lived object so the Sender is not recreated on every Action call.

```objc
// Singleton example: one Sender for the whole app
@interface ZegoAIAgentActionSender : NSObject <ZegoAIAgentActionOCSender>
+ (instancetype)shared;
@end

@implementation ZegoAIAgentActionSender
+ (instancetype)shared {
    static ZegoAIAgentActionSender *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [self new]; });
    return instance;
}
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion {
    // Same as 3. implementation ...
}
@end
```

### 4. Construct the Client

```objc
ZegoAIAgentActionSender *sender = [ZegoAIAgentActionSender new];
sender.roomId = @"room_1";
sender.agentUserId = @"agent_1";

ZegoAIAgentActionOCClient *client =
    [[ZegoAIAgentActionOCClient alloc] initWithRoomId:@"room_1"
                                          agentUserId:@"agent_1"
                                               userId:@"client_A"
                                          deviceId:nil                // auto-generated "oc_<uuid8>" if nil
                                          timeoutMs:5000              // default 5 s
                                               sender:sender
                                           onResponse:^(ZegoAIAgentActionOCResponse *response) {
        NSLog(@"recv action=%@ seq=%@ code=%ld message=%@",
              response.action, response.seq, (long)response.code, response.message);
    }
                                              onError:^(ZegoAIAgentActionOCError *error) {
        NSLog(@"err  action=%@ seq=%@ code=%@ message=%@",
              error.action, error.seq, error.code, error.message);
    }];
```

### 5. Send an Action

```objc
SendAgentInstanceTTSParams *params = [SendAgentInstanceTTSParams message];
params.text = @"hello";
params.addHistory = YES;
params.priority = @"Medium";
params.samePriorityOption = @"ClearAndInterrupt";

[client sendAgentInstanceTTSWithParams:params
                             timeoutMs:nil
                            completion:^(ZegoAIAgentActionOCResponse * _Nullable response,
                                         ZegoAIAgentActionOCError * _Nullable error) {
    if (error) {
        NSLog(@"tts err %@", error.message);
        return;
    }
    NSLog(@"tts ok seq=%@", response.seq);
}];
```

The other four methods follow the same shape:

```objc
// LLM
SendAgentInstanceLLMParams *llm = [SendAgentInstanceLLMParams message];
llm.text = @"hi";
[client sendAgentInstanceLLMWithParams:llm timeoutMs:nil
                            completion:^(ZegoAIAgentActionOCResponse *r, ZegoAIAgentActionOCError *e) { /* ... */ }];

// Interrupt
[client interruptAgentInstanceWithTimeoutMs:nil
                                 completion:^(ZegoAIAgentActionOCResponse *r, ZegoAIAgentActionOCError *e) { /* ... */ }];

// StartListening / StopListening
StartListeningParams *start = [StartListeningParams message];
[client startListeningWithParams:start timeoutMs:nil
                      completion:^(ZegoAIAgentActionOCResponse *r, ZegoAIAgentActionOCError *e) { /* ... */ }];

StopListeningParams *stop = [StopListeningParams message];
[client stopListeningWithParams:stop timeoutMs:nil
                     completion:^(ZegoAIAgentActionOCResponse *r, ZegoAIAgentActionOCError *e) { /* ... */ }];
```

> `params.text` is capped at 300 chars. Pass `nil` for `timeoutMs` to use the 5 s default.

### 6. Forward Room-Channel Callbacks

Forward every Express room-channel payload (from `onRecvExperimentalAPI`) to `client handleRoomChannelMessageWithContent:`. The suite decides whether the payload is an AI Agent Action message:

- AI Agent Action response: parses `Action/Seq/Code/Message/RequestId/Data` and triggers `onResponse` / `onError`; returns `YES`.
- AI Agent Action send receipt: marks the corresponding `seq` as failed only when `errorCode != 0`; returns `YES`.
- Any other message returns `NO`, so you can keep your own custom-message parsing untouched.

```objc
- (void)onRecvExperimentalAPI:(NSString *)content {
    ZegoAIAgentActionOCClient *actionClient = [[ZegoAIAgentKit sharedInstance] agentActionClient];
    if (actionClient && [actionClient handleRoomChannelMessageWithContent:content]) {
        NSLog(@"consumed by agentaction suite");
    }
    // Not consumed: fall through to subtitle / event parsing.
}
```

### 6.1 Hook Express's `onRecvExperimentalAPI`

`onRecvExperimentalAPI:` is the entry point exposed by the ZEGO Express SDK for all experimental-API callbacks. Anything pushed down the room channel lands here as a raw JSON string — including AI Agent Action responses.

Integration steps:

1. Adopt the `ZegoExpressEventHandler` protocol (only implement the events you care about);
2. Implement `- (void)onRecvExperimentalAPI:(NSString *)content` on that handler;
3. Forward the raw `content` to `[actionClient handleRoomChannelMessageWithContent:content]`; the suite decides whether the payload is an AI Agent Action message and fires `onResponse` / `onError`.

Example (pairs with section 6):

```objc
@interface AgentActionExpressHandler : NSObject <ZegoExpressEventHandler>
@property (nonatomic, strong) ZegoAIAgentActionOCClient *actionClient;
@end

@implementation AgentActionExpressHandler
- (void)onRecvExperimentalAPI:(NSString *)content {
    // Hand off to the suite. Consumed -> YES; otherwise fall through to your own parsing.
    if (self.actionClient) {
        [self.actionClient handleRoomChannelMessageWithContent:content];
    }
}
@end

// Inject the handler when creating the Express engine
ZegoEngineProfile *profile = [[ZegoEngineProfile alloc] init];
profile.appID = YOUR_APP_ID;
profile.scenario = ZegoScenarioDefault;
AgentActionExpressHandler *handler = [AgentActionExpressHandler new];
handler.actionClient = actionClient;
[ZegoExpressEngine createEngine:profile withEventHandler:handler];
```

> `onRecvExperimentalAPI:` is optional on the `ZegoExpressEventHandler` protocol; you only receive the event if you implement it. Room-channel responses arrive as raw JSON strings in `content`.

### 7. Cancel and Tear Down

```objc
// When leaving the room / closing the agent session
[client cancelAllWithMessage:@"logout"];
```

### 8. Pluggable Logging (Optional)

```objc
[ZegoAIAgentActionLogger setLevel:ZegoAIAgentActionLogger.levelDebug];
[ZegoAIAgentActionLogger installSink:^(NSString * _Nonnull line) {
    NSLog(@"[AgentAction] %@", line);
}];
```

## Error Codes

`ZegoAIAgentActionErrorCodes`:

| Constant | Value | When |
|---|---:|---|
| `success` | `0` | Any success path detected by the suite |
| `timeout` | `-1` | No AI Agent Action response within the default 5 s |
| `sendFailed` | `-2` | `Sender` threw or Express rejected the send |
| `canceled` | `-3` | `[client cancelAllWithMessage:]` invoked explicitly |

## Defaults

- `priority`: `Medium`
- `samePriorityOption`: `ClearAndInterrupt`
- TTS `addHistory`: `YES`
- LLM `addQuestionToHistory`: `NO`, `addAnswerToHistory`: `YES`
- Default timeout: `5000ms`

## Run the Demo

```bash
# 1) Install dependencies
cd agentaction/ios_oc/demo
pod install

# 2) Open HostApp.xcworkspace in Xcode and Run
```

## Validate the Pod

```bash
cd agentaction/ios_oc/agentaction
pod lib lint ZegoAIAgentActionObjC.podspec --allow-warnings
```

## References

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
