#import "include/ZegoAIAgentActionObjC.h"
#import "include/ZegoAIAgentActionDefines.h"
#import "Generated/AiAgentAction.pbobjc.h"

// `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的任务优先级默认值（与 aigc-agent 接口文档保持一致）
static NSString * const ZegoAIAgentActionDefaultPriority = @"Medium";
// `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的相同优先级打断策略默认值（与 aigc-agent 接口文档保持一致）
static NSString * const ZegoAIAgentActionDefaultSamePriorityOption = @"ClearAndInterrupt";

@implementation ZegoAIAgentActionOCSendParams
- (instancetype)initWithRoomId:(NSString *)roomId msgType:(NSInteger)msgType seq:(NSString *)seq msgContent:(NSString *)msgContent userList:(NSArray<NSString *> *)userList {
    self = [super init];
    if (self) {
        _roomId = [roomId copy];
        _msgType = msgType;
        _seq = [seq copy];
        _msgContent = [msgContent copy];
        _userList = [userList copy];
    }
    return self;
}
@end

@implementation ZegoAIAgentActionOCSendResult
- (instancetype)initWithErrorCode:(NSInteger)errorCode seq:(NSString *)seq {
    self = [super init];
    if (self) {
        _errorCode = errorCode;
        _seq = [seq copy];
    }
    return self;
}
@end

@implementation ZegoAIAgentActionOCResponse
- (instancetype)initWithContent:(NSDictionary *)content rawMessage:(NSString *)rawMessage {
    self = [super init];
    if (self) {
        _action = [content[@"Action"] ?: @"" copy];
        _seq = [content[@"Seq"] ?: @"" copy];
        _code = [content[@"Code"] integerValue];
        _message = [content[@"Message"] ?: @"" copy];
        _requestId = [content[@"RequestId"] ?: @"" copy];
        _data = content[@"Data"];
        _rawMessage = [rawMessage copy];
    }
    return self;
}
@end

@implementation ZegoAIAgentActionOCError
- (instancetype)initWithSeq:(NSString *)seq action:(NSString *)action code:(id)code message:(NSString *)message {
    self = [super init];
    if (self) {
        _seq = [seq copy];
        _action = [action copy];
        _code = code ?: @"unknown";
        _message = [message copy];
    }
    return self;
}
@end

@interface ZegoAIAgentActionOCPending : NSObject
@property (nonatomic, copy) NSString *action;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, copy) ZegoAIAgentActionOCCompletion completion;
@end

@implementation ZegoAIAgentActionOCPending
@end

@interface ZegoAIAgentActionOCClient ()
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *agentUserId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, assign) NSInteger timeoutMs;
@property (nonatomic, weak) id<ZegoAIAgentActionOCSender> sender;
@property (nonatomic, copy) ZegoAIAgentActionOCResponseHandler onResponse;
@property (nonatomic, copy) ZegoAIAgentActionOCErrorHandler onError;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZegoAIAgentActionOCPending *> *pending;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *expressPending;
@property (nonatomic, assign) NSInteger localSeq;
@property (nonatomic, assign) NSInteger expressSeq;
@end

@implementation ZegoAIAgentActionOCClient
- (instancetype)initWithRoomId:(NSString *)roomId agentUserId:(NSString *)agentUserId userId:(NSString *)userId sender:(id<ZegoAIAgentActionOCSender>)sender onResponse:(ZegoAIAgentActionOCResponseHandler)onResponse onError:(ZegoAIAgentActionOCErrorHandler)onError {
    return [self initWithRoomId:roomId agentUserId:agentUserId userId:userId deviceId:nil timeoutMs:5000 sender:sender onResponse:onResponse onError:onError];
}

- (instancetype)initWithRoomId:(NSString *)roomId agentUserId:(NSString *)agentUserId userId:(NSString *)userId deviceId:(NSString *)deviceId timeoutMs:(NSInteger)timeoutMs sender:(id<ZegoAIAgentActionOCSender>)sender onResponse:(ZegoAIAgentActionOCResponseHandler)onResponse onError:(ZegoAIAgentActionOCErrorHandler)onError {
    NSParameterAssert(roomId.length > 0);
    NSParameterAssert(agentUserId.length > 0);
    NSParameterAssert(userId.length > 0);
    NSParameterAssert(sender);
    self = [super init];
    if (self) {
        _roomId = [roomId copy];
        _agentUserId = [agentUserId copy];
        _userId = [userId copy];
        _deviceId = deviceId.length > 0 ? [deviceId copy] : [[NSString stringWithFormat: @"oc_%@", [NSUUID UUID].UUIDString] substringToIndex:11];
        _timeoutMs = timeoutMs > 0 ? timeoutMs : 5000;
        _sender = sender;
        _onResponse = [onResponse copy];
        _onError = [onError copy];
        _queue = dispatch_queue_create("com.zego.aiagent.action.oc", DISPATCH_QUEUE_SERIAL);
        _pending = [NSMutableDictionary dictionary];
        _expressPending = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)sendAgentInstanceTTSWithParams:(SendAgentInstanceTTSParams *)params timeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    NSParameterAssert(params);
    NSParameterAssert(params.text.length > 0);
    [self sendProtoAction:ZegoAIAgentActionNames.sendAgentInstanceTTS params:params timeoutMs:timeoutMs completion:completion];
}

- (void)sendAgentInstanceLLMWithParams:(SendAgentInstanceLLMParams *)params timeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    NSParameterAssert(params);
    NSParameterAssert(params.text.length > 0);
    [self sendProtoAction:ZegoAIAgentActionNames.sendAgentInstanceLLM params:params timeoutMs:timeoutMs completion:completion];
}

- (void)interruptAgentInstanceWithTimeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    InterruptAgentInstanceParams *interruptParams = [InterruptAgentInstanceParams message];
    [self sendProtoAction:ZegoAIAgentActionNames.interruptAgentInstance params:interruptParams timeoutMs:timeoutMs completion:completion];
}

- (void)startListeningWithParams:(StartListeningParams *)params timeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    NSParameterAssert(params);
    [self sendProtoAction:ZegoAIAgentActionNames.startListening params:params timeoutMs:timeoutMs completion:completion];
}

- (void)stopListeningWithParams:(StopListeningParams *)params timeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    NSParameterAssert(params);
    [self sendProtoAction:ZegoAIAgentActionNames.stopListening params:params timeoutMs:timeoutMs completion:completion];
}

- (BOOL)handleRoomChannelMessageWithContent:(NSString *)contentString {
    NSData *data = [contentString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDict = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![dataDict isKindOfClass:NSDictionary.class]) return NO;

    NSString *method = dataDict[ZegoAIAgentActionExpressKeys.method];
    if ([ZegoAIAgentActionExpressMethods.onReciveRoomChannelMessage isEqualToString:method]) {
        NSDictionary *expressParams = dataDict[ZegoAIAgentActionExpressKeys.params];
        if (![expressParams isKindOfClass:NSDictionary.class]) return NO;

        NSInteger msgType = [expressParams[ZegoAIAgentActionExpressKeys.msgType] integerValue];
        NSString *msgContent = expressParams[ZegoAIAgentActionExpressKeys.msgContent];
        if (msgType != ZegoAIAgentActionMsgTypes.response || ![msgContent isKindOfClass:NSString.class]) return NO;
        [ZegoAIAgentActionLogger debug:[NSString stringWithFormat:@"handleRoomChannelMessage recv: %@", contentString]];

        NSData *msgContentData = [msgContent dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *content = msgContentData ? [NSJSONSerialization JSONObjectWithData:msgContentData options:0 error:nil] : nil;
        if (![content isKindOfClass:NSDictionary.class] || ![content[ZegoAIAgentActionProtocolKeys.seq] isKindOfClass:NSString.class] || !content[ZegoAIAgentActionProtocolKeys.action] || !content[ZegoAIAgentActionProtocolKeys.code]) {
            [ZegoAIAgentActionLogger warn:[NSString stringWithFormat:@"on_recive_room_channel_message missing required fields: %@", content]];
            return NO;
        }
        NSString *seq = content[ZegoAIAgentActionProtocolKeys.seq];
        __block ZegoAIAgentActionOCPending *item = nil;
        dispatch_sync(self.queue, ^{
            item = self.pending[seq];
            [self.pending removeObjectForKey:seq];
            [self.expressPending enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSString *obj, BOOL *stop) {
                if ([obj isEqualToString:seq]) {
                    [self.expressPending removeObjectForKey:key];
                    *stop = YES;
                }
            }];
        });
        if (!item) {
            [ZegoAIAgentActionLogger warn:[NSString stringWithFormat:@"on_recive_room_channel_message orphan seq=%@", seq]];
            return NO;
        }
        dispatch_source_cancel(item.timer);
        ZegoAIAgentActionOCResponse *response = [[ZegoAIAgentActionOCResponse alloc] initWithContent:content rawMessage:msgContent];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ZegoAIAgentActionLogger info:[NSString stringWithFormat:@"recv action=%@ seq=%@ code=%ld message=%@", response.action ?: @"", response.seq ?: @"", (long)response.code, response.message ?: @""]];
            if (self.onResponse) self.onResponse(response);
            if (response.code == ZegoAIAgentActionErrorCodes.success) {
                item.completion(response, nil);
            } else {
                ZegoAIAgentActionOCError *error = [[ZegoAIAgentActionOCError alloc] initWithSeq:seq action:response.action code:@(response.code) message:response.message];
                if (self.onError) self.onError(error);
                item.completion(nil, error);
            }
        });
        return YES;
    } else if ([ZegoAIAgentActionExpressMethods.onSendRoomChannelMessage isEqualToString:method]) {
        NSDictionary *expressParams = dataDict[ZegoAIAgentActionExpressKeys.params];
        if (![expressParams isKindOfClass:NSDictionary.class]) return NO;
        [ZegoAIAgentActionLogger debug:[NSString stringWithFormat:@"handleRoomChannelMessage recv: %@", contentString]];

        NSInteger errorCode = [expressParams[ZegoAIAgentActionExpressKeys.errorCode] integerValue];
        NSNumber *expressSeq = expressParams[ZegoAIAgentActionExpressKeys.seq];

        if (errorCode != ZegoAIAgentActionErrorCodes.success && expressSeq) {
            __block NSString *seq = nil;
            __block ZegoAIAgentActionOCPending *item = nil;
            dispatch_sync(self.queue, ^{
                seq = self.expressPending[expressSeq];
                [self.expressPending removeObjectForKey:expressSeq];
                if (seq) {
                    item = self.pending[seq];
                    [self.pending removeObjectForKey:seq];
                }
            });
            if (item) {
                dispatch_source_cancel(item.timer);
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *errorMessage = [expressParams[ZegoAIAgentActionExpressKeys.errorMessage] isKindOfClass:NSString.class] ? expressParams[ZegoAIAgentActionExpressKeys.errorMessage] : @"";
                    [ZegoAIAgentActionLogger warn:[NSString stringWithFormat:@"on_send_room_channel_message error seq=%@ errorCode=%ld message=%@", seq ?: @"", (long)errorCode, errorMessage ?: @""]];
                    ZegoAIAgentActionOCError *error = [[ZegoAIAgentActionOCError alloc] initWithSeq:seq action:item.action code:@(errorCode) message:errorMessage];
                    if (self.onError) self.onError(error);
                    item.completion(nil, error);
                });
            }
        }
        return YES;
    }
    return NO;
}

- (void)cancelAllWithMessage:(NSString *)message {
    __block NSDictionary<NSString *, ZegoAIAgentActionOCPending *> *items = nil;
    dispatch_sync(self.queue, ^{
        items = [self.pending copy];
        [self.pending removeAllObjects];
    });
    [ZegoAIAgentActionLogger warn:[NSString stringWithFormat:@"cancelAll size=%lu message=%@", (unsigned long)items.count, message ?: @""]];
    [items enumerateKeysAndObjectsUsingBlock:^(NSString *seq, ZegoAIAgentActionOCPending *item, BOOL *stop) {
        dispatch_source_cancel(item.timer);
        item.completion(nil, [[ZegoAIAgentActionOCError alloc] initWithSeq:seq action:item.action code:@(ZegoAIAgentActionErrorCodes.canceled) message:message ?: @"agent action canceled"]);
    }];
}

- (void)sendProtoAction:(NSString *)action params:(GPBMessage *)params timeoutMs:(NSNumber *)timeoutMs completion:(ZegoAIAgentActionOCCompletion)completion {
    if (!completion) return;
    NSString *seq = [self nextSeq];
    AgentActionEnvelope *envelopeProto = [AgentActionEnvelope message];
    envelopeProto.action = action ?: @"";
    envelopeProto.seq = seq;
    envelopeProto.params = params.data ?: [NSData data];
    NSDictionary *envelope = [self encodeEnvelope:envelopeProto params:params];
    NSData *data = [NSJSONSerialization dataWithJSONObject:envelope options:0 error:nil];
    NSString *msgContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";

    __block NSInteger currentExpressSeq = 0;
    dispatch_sync(self.queue, ^{
        self.expressSeq += 1;
        currentExpressSeq = self.expressSeq;
        self.expressPending[@(currentExpressSeq)] = seq;
    });

    NSDictionary *expressParams = @{
        ZegoAIAgentActionExpressKeys.roomId: self.roomId,
        ZegoAIAgentActionExpressKeys.msgType: @(ZegoAIAgentActionMsgTypes.request),
        ZegoAIAgentActionExpressKeys.msgContent: msgContent,
        ZegoAIAgentActionExpressKeys.userList: @[self.agentUserId],
        ZegoAIAgentActionExpressKeys.seq: @(currentExpressSeq)
    };
    NSDictionary *expressPayload = @{
        ZegoAIAgentActionExpressKeys.method: ZegoAIAgentActionExpressMethods.sendRoomChannelMessage,
        ZegoAIAgentActionExpressKeys.params: expressParams
    };
    NSData *expressData = [NSJSONSerialization dataWithJSONObject:expressPayload options:0 error:nil];
    NSString *expressJson = [[NSString alloc] initWithData:expressData encoding:NSUTF8StringEncoding] ?: @"{}";
    [ZegoAIAgentActionLogger info:[NSString stringWithFormat:@"send action=%@ seq=%@ expressSeq=%ld msgContent=%@", action ?: @"", seq, (long)currentExpressSeq, msgContent ?: @""]];

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    NSInteger effectiveTimeoutMs = timeoutMs ? timeoutMs.integerValue : self.timeoutMs;
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(effectiveTimeoutMs * NSEC_PER_MSEC)), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(timer, ^{
        ZegoAIAgentActionOCPending *item = self.pending[seq];
        [self.pending removeObjectForKey:seq];
        if (item) {
            [ZegoAIAgentActionLogger warn:[NSString stringWithFormat:@"timeout action=%@ seq=%@", action ?: @"", seq]];
            item.completion(nil, [[ZegoAIAgentActionOCError alloc] initWithSeq:seq action:action code:@(ZegoAIAgentActionErrorCodes.timeout) message:@"agent action timeout"]);
        }
    });
    ZegoAIAgentActionOCPending *item = [ZegoAIAgentActionOCPending new];
    item.action = action;
    item.timer = timer;
    item.completion = completion;
    dispatch_sync(self.queue, ^{
        self.pending[seq] = item;
    });
    dispatch_resume(timer);
    ZegoAIAgentActionOCSendParams *sendParams = [[ZegoAIAgentActionOCSendParams alloc] initWithRoomId:self.roomId msgType:ZegoAIAgentActionMsgTypes.request seq:seq msgContent:msgContent userList:@[self.agentUserId]];
    [self.sender sendAgentAction:sendParams formatedJson:expressJson completion:^(ZegoAIAgentActionOCSendResult *result) {
        [ZegoAIAgentActionLogger debug:[NSString stringWithFormat:@"sender result action=%@ seq=%@ errorCode=%ld", action ?: @"", seq, (long)result.errorCode]];
        if (result.errorCode == ZegoAIAgentActionErrorCodes.success) return;
        __block ZegoAIAgentActionOCPending *pending = nil;
        dispatch_sync(self.queue, ^{
            pending = self.pending[seq];
            [self.pending removeObjectForKey:seq];
        });
        if (pending) {
            dispatch_source_cancel(pending.timer);
            pending.completion(nil, [[ZegoAIAgentActionOCError alloc] initWithSeq:seq action:action code:@(ZegoAIAgentActionErrorCodes.sendFailed) message:@"send failed"]);
        }
    }];
}

- (NSString *)nextSeq {
    __block NSString *seq = nil;
    dispatch_sync(self.queue, ^{
        self.localSeq += 1;
        seq = [NSString stringWithFormat:@"%@:%@:%ld", self.userId, self.deviceId, (long)self.localSeq];
    });
    return seq;
}

- (NSDictionary *)encodeEnvelope:(AgentActionEnvelope *)envelope params:(GPBMessage *)params {
    return @{
        ZegoAIAgentActionProtocolKeys.action: envelope.action ?: @"",
        ZegoAIAgentActionProtocolKeys.seq: envelope.seq ?: @"",
        ZegoAIAgentActionProtocolKeys.params: [self encodeParams:params]
    };
}

- (NSDictionary *)encodeParams:(GPBMessage *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([params isKindOfClass:SendAgentInstanceTTSParams.class]) {
        SendAgentInstanceTTSParams *p = (SendAgentInstanceTTSParams *)params;
        dict[ZegoAIAgentActionProtocolKeys.text] = p.text ?: @"";
        dict[ZegoAIAgentActionProtocolKeys.addHistory] = @(p.addHistory);
        // priority / samePriorityOption 为枚举字符串，客户端不显式赋值时 protobuf 默认空串会触发服务端 410000003 "Priority is invalid"，此处兜底为文档默认值
        dict[ZegoAIAgentActionProtocolKeys.priority] = p.priority.length > 0 ? p.priority : ZegoAIAgentActionDefaultPriority;
        dict[ZegoAIAgentActionProtocolKeys.samePriorityOption] = p.samePriorityOption.length > 0 ? p.samePriorityOption : ZegoAIAgentActionDefaultSamePriorityOption;
        if (p.interruptMode != 0) dict[ZegoAIAgentActionProtocolKeys.interruptMode] = @(p.interruptMode);
        if (p.enqueueUserSpeech) dict[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = @YES;
        return dict;
    }
    if ([params isKindOfClass:SendAgentInstanceLLMParams.class]) {
        SendAgentInstanceLLMParams *p = (SendAgentInstanceLLMParams *)params;
        dict[ZegoAIAgentActionProtocolKeys.text] = p.text ?: @"";
        dict[ZegoAIAgentActionProtocolKeys.systemPrompt] = p.systemPrompt ?: @"";
        dict[ZegoAIAgentActionProtocolKeys.addQuestionToHistory] = @(p.addQuestionToHistory);
        dict[ZegoAIAgentActionProtocolKeys.addAnswerToHistory] = @(p.addAnswerToHistory);
        // 同 TTS：枚举字段空串兜底为文档默认值，避免服务端校验失败
        dict[ZegoAIAgentActionProtocolKeys.priority] = p.priority.length > 0 ? p.priority : ZegoAIAgentActionDefaultPriority;
        dict[ZegoAIAgentActionProtocolKeys.samePriorityOption] = p.samePriorityOption.length > 0 ? p.samePriorityOption : ZegoAIAgentActionDefaultSamePriorityOption;
        if (p.enqueueUserSpeech) dict[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = @YES;
        return dict;
    }
    if ([params isKindOfClass:StartListeningParams.class]) {
        StartListeningParams *p = (StartListeningParams *)params;
        if (p.userId.length > 0) dict[ZegoAIAgentActionProtocolKeys.userId] = p.userId;
        return dict;
    }
    if ([params isKindOfClass:StopListeningParams.class]) {
        StopListeningParams *p = (StopListeningParams *)params;
        if (p.userId.length > 0) dict[ZegoAIAgentActionProtocolKeys.userId] = p.userId;
        return dict;
    }
    if ([params isKindOfClass:InterruptAgentInstanceParams.class]) {
        return dict;
    }
    return dict;
}

- (AgentActionResponse *)decodeResponse:(NSDictionary *)json {
    AgentActionResponse *response = [AgentActionResponse message];
    response.action = json[ZegoAIAgentActionProtocolKeys.action] ?: @"";
    response.seq = json[ZegoAIAgentActionProtocolKeys.seq] ?: @"";
    response.code = [json[ZegoAIAgentActionProtocolKeys.code] intValue];
    response.message = json[ZegoAIAgentActionProtocolKeys.message] ?: @"";
    response.requestId = json[ZegoAIAgentActionProtocolKeys.requestId] ?: @"";
    return response;
}
@end
