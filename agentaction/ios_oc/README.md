# iOS Objective-C 使用说明

本目录提供 iOS Objective-C 端的 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Objective-C 套件（Pod 库 + Swift Package 双形态）。
- `demo/`：可运行的 CocoaPods/Xcode Demo 外壳工程。

> 英文版本请见 [README.en.md](./README.en.md)。

## 套件源码

```text
agentaction/
├── ZegoAIAgentActionObjC.podspec     # CocoaPods 描述（依赖 Protobuf ~> 4.31）
├── Package.swift                     # 轻量本地 Demo 外壳（仅用于 Swift 工具链）
└── Sources/ZegoAIAgentActionObjC/
    ├── include/
    │   ├── ZegoAIAgentActionObjC.h   # 公共头（Client、SendParams、Response、Error、Sender 协议）
    │   ├── ZegoAIAgentActionDefines.h
    │   └── ZegoAIAgentActionLogger.h
    ├── ZegoAIAgentActionObjC.m       # 套件核心 Client
    ├── ZegoAIAgentActionDefines.m
    ├── ZegoAIAgentActionLogger.m
    └── Generated/
        ├── AiAgentAction.pbobjc.h    # protoc 生成的 Protobuf 协议类
        └── AiAgentAction.pbobjc.m
```

最低部署目标 iOS 15.0 / macOS 12.0。

## 集成步骤

### 1. 通过 CocoaPods 集成（推荐）

将 `ios_oc/agentaction/` 拷贝到你的 iOS 项目工作区，在 `Podfile` 中加：

```ruby
pod 'ZegoAIAgentActionObjC', :path => './agentaction'
```

然后 `pod install`。本地 Demo 使用 `:path => '../agentaction'`，因为它的 `Podfile` 位于 `ios_oc/demo` 下。

> 由于生成的 `.pbobjc` 文件依赖 Google Protobuf Objective-C 运行时（`GPBProtocolBuffers.h` / `Protobuf` Pod），实际的 Objective-C Protobuf 集成路径是 CocoaPods/Xcode。`Package.swift` 仅保留作轻量本地 Demo 外壳。

### 2. 引入头文件

```objc
#import <ZegoAIAgentActionObjC/ZegoAIAgentActionObjC.h>
```

### 3. 实现 Sender，桥接到 ZEGO Express

套件通过 `ZegoAIAgentActionOCSender` 协议与 ZEGO Express 通信。该协议只有一个方法，套件在内部用同一个 Sender 实例处理 5 个 Action（TTS / LLM / Interrupt / StartListening / StopListening）的所有发送请求。

`formatedJson` 形如：

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

示例代码：

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

### 3.1 Sender 协议方法（推荐）

`ZegoAIAgentActionOCSender` 协议声明如下，只需实现这一个方法即可把 5 个 Action 全部桥接到 ZEGO Express：

```objc
@protocol ZegoAIAgentActionOCSender <NSObject>
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion;
@end
```

参数含义：

| 参数 | 说明 |
|---|---|
| `params` | 套件组装好的请求元数据（`roomId / msgType(=20) / userList(=[agentUserId]) / seq`） |
| `formatedJson` | 套件组装好的 JSON 信封，可直接 `callExperimentalAPI:` 透传给 Express |
| `completion` | 必须回调，把发送结果（成功/失败 + seq）回传给套件，用于 seq 超时与失败管理 |

**复用模式**：你只需要写一个 `id<ZegoAIAgentActionOCSender>` 实现类，把它注入到 `ZegoAIAgentActionOCClient` 后，5 个 Action 全部走同一个 Sender。建议把 Sender 实现做成单例或绑在长生命周期的对象上，避免在每次 Action 调用时重新创建。

```objc
// 单例示例：整个 App 共享一个 Sender
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
    // 同 3. 实现 ...
}
@end
```

### 4. 构造 Client

```objc
ZegoAIAgentActionSender *sender = [ZegoAIAgentActionSender new];
sender.roomId = @"room_1";
sender.agentUserId = @"agent_1";

ZegoAIAgentActionOCClient *client =
    [[ZegoAIAgentActionOCClient alloc] initWithRoomId:@"room_1"
                                          agentUserId:@"agent_1"
                                               userId:@"client_A"
                                      agentInstanceId:nil                // 非数字人场景传 nil
                                       isDigitalHuman:NO                  // 非数字人通话
                                             deviceId:nil                 // 缺省时自动生成 "oc_<uuid8>"
                                            timeoutMs:5000               // 默认 5s
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

### 5. 发送 Action

```objc
SendAgentInstanceTTSParams *params = [SendAgentInstanceTTSParams message];
params.text = @"你好";
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

其他四个方法完全对称：

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

> `params.text` 长度限制 300 字符；`timeoutMs` 传 `nil` 走默认值 5 秒。

### 6. 转发房间通道回调

Express 的房间通道消息（来自 `onRecvExperimentalAPI`）丢给 `client handleRoomChannelMessageWithContent:`。套件会判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回 `YES`。
- AI Agent Action 发送回执：仅在 `errorCode != 0` 时把对应 `seq` 标为失败；返回 `YES`。
- 其他消息返回 `NO`，可继续走业务自定义消息解析。

```objc
- (void)onRecvExperimentalAPI:(NSString *)content {
    ZegoAIAgentActionOCClient *actionClient = [[ZegoAIAgentKit sharedInstance] agentActionClient];
    if (actionClient && [actionClient handleRoomChannelMessageWithContent:content]) {
        NSLog(@"已被 agentaction 套件消费");
    }
    // 未消费时继续走业务字幕 / 事件解析
}
```

### 6.1 接入 Express 接收回调

`onRecvExperimentalAPI:` 是 ZEGO Express SDK 暴露的实验性 API 回调入口，凡是走房间通道下发的消息都会以原始 JSON 字符串形式送到这个回调。AI Agent Action 的响应也走这里。

接入步骤：

1. 实现 `ZegoExpressEventHandler` 协议（只覆盖关心的事件即可）；
2. 在事件处理器里实现 `- (void)onRecvExperimentalAPI:(NSString *)content`；
3. 把收到的 `content` 原文丢给 `[actionClient handleRoomChannelMessageWithContent:content]`，由套件判断是否属于 AI Agent Action 消息并触发 `onResponse` / `onError`。

示例代码（与 6. 节配合）：

```objc
@interface AgentActionExpressHandler : NSObject <ZegoExpressEventHandler>
@property (nonatomic, strong) ZegoAIAgentActionOCClient *actionClient;
@end

@implementation AgentActionExpressHandler
- (void)onRecvExperimentalAPI:(NSString *)content {
    // 委托给套件：消费了返回 YES，未消费可继续走业务自定义消息解析
    if (self.actionClient) {
        [self.actionClient handleRoomChannelMessageWithContent:content];
    }
}
@end

// 创建 Express 时把 handler 注入
ZegoEngineProfile *profile = [[ZegoEngineProfile alloc] init];
profile.appID = YOUR_APP_ID;
profile.scenario = ZegoScenarioDefault;
AgentActionExpressHandler *handler = [AgentActionExpressHandler new];
handler.actionClient = actionClient;
[ZegoExpressEngine createEngine:profile withEventHandler:handler];
```

> `onRecvExperimentalAPI:` 在 `ZegoExpressEventHandler` 协议中是可选实现，只有覆写了才会收到事件；房间通道响应会以原始 JSON 字符串形式作为 `content` 传入。

### 7. 取消与清理

```objc
// 离开房间 / 退出 Agent 会话时主动取消在途请求
[client cancelAllWithMessage:@"logout"];
```

### 8. 日志接管（可选）

```objc
[ZegoAIAgentActionLogger setLevel:ZegoAIAgentActionLogger.levelDebug];
[ZegoAIAgentActionLogger installSink:^(NSString * _Nonnull line) {
    NSLog(@"[AgentAction] %@", line);
}];
```

## 错误码

`ZegoAIAgentActionErrorCodes`：

| 常量 | 值 | 触发条件 |
|---|---:|---|
| `success` | `0` | 套件内部判定的所有成功路径 |
| `timeout` | `-1` | 默认 5 秒内未收到 AI Agent Action 响应 |
| `sendFailed` | `-2` | `Sender` 抛异常或 Express 发送失败 |
| `canceled` | `-3` | 主动调用 `[client cancelAllWithMessage:]` |

## 默认值

- `priority`：`Medium`
- `samePriorityOption`：`ClearAndInterrupt`
- TTS `addHistory`：`YES`
- LLM `addQuestionToHistory`：`NO`，`addAnswerToHistory`：`YES`
- 默认超时：`5000ms`

## 运行 Demo

```bash
# 1) 安装依赖
cd agentaction/ios_oc/demo
pod install

# 2) 打开 HostApp.xcworkspace 即可 Run
```

## 校验 Pod

```bash
cd agentaction/ios_oc/agentaction
pod lib lint ZegoAIAgentActionObjC.podspec --allow-warnings
```

## 参考文档

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
