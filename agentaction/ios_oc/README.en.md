# iOS Objective-C Usage

This is the Objective-C version of the AI Agent Action suite. It is separate from `agentaction/ios_swift`.

## Directory Layout

- `ios_oc/agentaction`: copyable Objective-C suite.
- `ios_oc/demo`: runnable CocoaPods/Xcode demo shell.

> Chinese version: [README.md](./README.md)

## Copy Into Your Project

Copy `ios_oc/agentaction` into your iOS project workspace, then add it with CocoaPods:

```ruby
pod 'ZegoAIAgentActionObjC', :path => './agentaction'
```

The local demo uses `:path => '../agentaction'` because its `Podfile` lives in `ios_oc/demo`.

The standard action APIs in this package now construct and consume the generated protobuf classes in `Sources/ZegoAIAgentActionObjC/Generated`, and then bridge them to the current room-channel JSON transport format.

```objc
#import <ZegoAIAgentActionObjC/ZegoAIAgentActionObjC.h>
```

Implement the ZEGO Express sender adapter:

```objc
@interface Sender : NSObject <ZegoAIAgentActionOCSender>
@end

@implementation Sender
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion {
    // Replace with Express sendRoomChannelMessage.
    // params.msgType == 20
    // params.msgContent == {"Action","Seq","Params"}
    // params.userList == @[agentUserId]
    completion([[ZegoAIAgentActionOCSendResult alloc] initWithErrorCode:0 seq:params.seq]);
}
@end
```

Create the client:

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

Send an action:

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

Forward `msg_type=22` room channel messages:

```objc
[client handleRoomChannelMessageWithMsgType:22 msgContent:msgContent];
```

Run the demo pod install:

```bash
cd agentaction/ios_oc/demo
pod install
```

Validate the pod:

```bash
cd agentaction/ios_oc/agentaction
pod lib lint ZegoAIAgentActionObjC.podspec --allow-warnings
```

`Package.swift` is kept only for the lightweight local demo shell. The actual Objective-C protobuf integration path is CocoaPods/Xcode because the generated `.pbobjc` files depend on the Google Protobuf Objective-C runtime (`GPBProtocolBuffers.h` / `Protobuf` pod).
