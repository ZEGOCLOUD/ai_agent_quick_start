# iOS Objective-C 使用说明

这是 AI Agent Action 套件的 Objective-C 版本，独立于 `agentaction/ios_swift`。

## 目录结构

- `ios_oc/agentaction`：可拷贝的 Objective-C 套件。
- `ios_oc/demo`：可运行的 CocoaPods/Xcode Demo 外壳工程。

> 英文版本请见 [README.en.md](./README.en.md)。

## 拷贝到你的项目

将 `ios_oc/agentaction` 拷贝到你的 iOS 项目工作区，然后通过 CocoaPods 集成：

```ruby
pod 'ZegoAIAgentActionObjC', :path => './agentaction'
```

本地 Demo 使用的是 `:path => '../agentaction'`，因为它的 `Podfile` 位于 `ios_oc/demo` 下。

本包中的标准 Action API 现在会构造并消费 `Sources/ZegoAIAgentActionObjC/Generated` 下生成的 Protobuf 类，再桥接为当前房间通道的 JSON 传输格式。

```objc
#import <ZegoAIAgentActionObjC/ZegoAIAgentActionObjC.h>
```

实现 ZEGO Express 发送器适配：

```objc
@interface Sender : NSObject <ZegoAIAgentActionOCSender>
@end

@implementation Sender
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion {
    // 替换为 Express sendRoomChannelMessage
    // params.msgType == 20
    // params.msgContent == {"Action","Seq","Params"}
    // params.userList == @[agentUserId]
    completion([[ZegoAIAgentActionOCSendResult alloc] initWithErrorCode:0 seq:params.seq]);
}
@end
```

创建 Client：

```objc
ZegoAIAgentActionOCClient *client =
    [[ZegoAIAgentActionOCClient alloc] initWithRoomId:@"room_1"
                                          agentUserId:@"agent_1"
                                               userId:@"client_A"
                                               sender:sender
                                           onResponse:^(ZegoAIAgentActionOCResponse *response) {
    NSLog(@"response %@", response.seq);
}];
```

发送一条 Action：

```objc
SendAgentInstanceTTSParams *params = [SendAgentInstanceTTSParams message];
params.text = @"你好";
params.addHistory = YES;
params.priority = @"Medium";
params.samePriorityOption = @"ClearAndInterrupt";
[client sendAgentInstanceTTSWithParams:params
                             timeoutMs:nil
                            completion:^(ZegoAIAgentActionOCResponse *response,
                                         ZegoAIAgentActionOCError *error) {
    if (error) {
        NSLog(@"error %@", error.message);
        return;
    }
    NSLog(@"success %@", response.seq);
}];
```

转发 `msg_type=22` 房间通道消息：

```objc
[client handleRoomChannelMessageWithMsgType:22 msgContent:msgContent];
```

运行 Demo `pod install`：

```bash
cd agentaction/ios_oc/demo
pod install
```

校验 Pod：

```bash
cd agentaction/ios_oc/agentaction
pod lib lint ZegoAIAgentActionObjC.podspec --allow-warnings
```

`Package.swift` 仅用于轻量级的本地 Demo 外壳工程。由于生成的 `.pbobjc` 文件依赖 Google Protobuf Objective-C 运行时（`GPBProtocolBuffers.h` / `Protobuf` Pod），因此实际的 Objective-C Protobuf 集成路径是 CocoaPods/Xcode。
