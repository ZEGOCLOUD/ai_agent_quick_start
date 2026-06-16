#import <Foundation/Foundation.h>
#import "AiAgentAction.pbobjc.h"
#import "ZegoAIAgentActionDefines.h"
#import "ZegoAIAgentActionLogger.h"

NS_ASSUME_NONNULL_BEGIN

/// 套件透传给业务方的发送参数，业务方在 `ZegoAIAgentActionOCSender` 回调中拿到。
///
/// 该结构与 `ZegoAIAgentActionOCClient` 内部的 Express 协议一致：
///   - 调用 `ZegoExpressEngine.callExperimentalAPI` 时，业务方只需要把
///     `formatedJson` 透传给 Express SDK 即可；
///   - `msgContent` 字段在 `ZegoAIAgentActionOCClient` 内部已构造完成，可用于业务
///     侧在日志中记录请求体内容。
@interface ZegoAIAgentActionOCSendParams : NSObject
/// 业务侧请求的目标 RTC 房间 ID，对应 Express 协议 `room_id`。
@property (nonatomic, copy, readonly) NSString *roomId;
/// Express 消息类型，本期仅使用 `20`（请求）。
@property (nonatomic, assign, readonly) NSInteger msgType;
/// 业务链路追踪标识（与 `msgContent.Seq` 一致），业务侧可用于日志关联。
@property (nonatomic, copy, readonly) NSString *seq;
/// 业务请求 `msg_content` 字符串，已被 `ZegoAIAgentActionOCClient` 序列化为 JSON。
@property (nonatomic, copy, readonly) NSString *msgContent;
/// 接收方用户列表，本期通常为单个智能体 userId。
@property (nonatomic, copy, readonly) NSArray<NSString *> *userList;
- (instancetype)initWithRoomId:(NSString *)roomId
                       msgType:(NSInteger)msgType
                           seq:(NSString *)seq
                    msgContent:(NSString *)msgContent
                      userList:(NSArray<NSString *> *)userList NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/// `ZegoAIAgentActionOCSender` 的返回结果。
///
/// 业务侧调用 `ZegoExpressEngine.callExperimentalAPI` 时只需把
/// `formatedJson` 透传给 Express SDK；SDK 成功调用后 `errorCode` 应为
/// `ZegoAIAgentActionErrorCodes.success`；否则 Kit 会将此次请求标记为
/// "express 发送失败" 并触发 onError 回调。
@interface ZegoAIAgentActionOCSendResult : NSObject
/// 0 表示成功；其它值由 Express SDK 内部定义。
@property (nonatomic, assign, readonly) NSInteger errorCode;
/// 业务链路追踪标识。
@property (nonatomic, copy, readonly) NSString *seq;
- (instancetype)initWithErrorCode:(NSInteger)errorCode seq:(NSString *)seq NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/// 智能体实例控制响应，由 `ZegoAIAgentActionOCClient` 在收到 `msg_type=22` 响应时构造。
@interface ZegoAIAgentActionOCResponse : NSObject
/// 原始 Action，例如 `SendAgentInstanceTTS`。
@property (nonatomic, copy, readonly) NSString *action;
/// 业务链路追踪标识（与上行请求 `msgContent.Seq` 一致）。
@property (nonatomic, copy, readonly) NSString *seq;
/// 处理结果码，0 表示成功；其它值由 PaaS 端定义。
@property (nonatomic, assign, readonly) NSInteger code;
/// 处理结果说明，失败时包含错误信息。
@property (nonatomic, copy, readonly) NSString *message;
/// PaaS 调用的智能体控制接口返回的 RequestId。
@property (nonatomic, copy, readonly) NSString *requestId;
/// PaaS 返回的业务数据，可为空。
@property (nonatomic, strong, nullable, readonly) id data;
/// 原始 `msg_content` JSON 字符串，便于业务侧二次解析。
@property (nonatomic, copy, readonly) NSString *rawMessage;
@end

/// 智能体实例控制错误。
///
/// 可能在以下场景触发：
///   - PaaS 端业务处理失败（`code` 不为 0）；
///   - Express 发送失败（`code` 为 `ZegoAIAgentActionErrorCodes.sendFailed`）；
///   - 请求超时（`code` 为 `ZegoAIAgentActionErrorCodes.timeout`）；
///   - 主动取消（`code` 为 `ZegoAIAgentActionErrorCodes.canceled`）。
@interface ZegoAIAgentActionOCError : NSObject
/// 业务链路追踪标识。
@property (nonatomic, copy, readonly) NSString *seq;
/// 原始 Action。
@property (nonatomic, copy, readonly) NSString *action;
/// 错误码。
///
/// PaaS 端业务错误时为业务返回的 `Code`；本地套件错误时为
/// `ZegoAIAgentActionErrorCodes` 中的预定义值。
@property (nonatomic, strong, readonly) id code;
/// 错误描述。
@property (nonatomic, copy, readonly) NSString *message;
/// 错误原因（保留字段，本期未使用）。
@property (nonatomic, strong, nullable, readonly) id cause;
@end

/// 业务侧实现的发送回调协议。
///
/// 业务侧在该回调中应：
///   1. 将 `formatedJson` 直接透传给 `ZegoExpressEngine.callExperimentalAPI`；
///   2. SDK 回调成功时通过 `ZegoAIAgentActionOCSendResult.errorCode` 标记为
///      `ZegoAIAgentActionErrorCodes.success`；
///   3. SDK 回调失败时使用 SDK 原始错误码并保持 `ZegoAIAgentActionOCSendResult.seq`
///      不变，Kit 会将此次请求标记为失败并触发 `ZegoAIAgentActionOCErrorHandler`。
@protocol ZegoAIAgentActionOCSender <NSObject>
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion;
@end

/// 业务侧请求的异步完成回调（成功走 response，失败走 error）。
typedef void (^ZegoAIAgentActionOCCompletion)(ZegoAIAgentActionOCResponse * _Nullable response,
                                              ZegoAIAgentActionOCError * _Nullable error);
/// 业务侧实现的全局响应回调（可选）；每次收到 PaaS 端业务响应时（无论成功或失败）都会触发。
typedef void (^ZegoAIAgentActionOCResponseHandler)(ZegoAIAgentActionOCResponse *response);
typedef void (^ZegoAIAgentActionOCErrorHandler)(ZegoAIAgentActionOCError *error);

/// 智能体实例控制客户端。
///
/// 负责将业务侧发起的 TTS / LLM / 打断 / 聆听等请求透明地上送到 PaaS，
/// 并在收到 PaaS 响应后回传给业务侧。
///
/// 使用流程：
///   1. 业务侧构造一个 `ZegoAIAgentActionOCSender` 回调（通常实现为直接调用
///      `ZegoExpressEngine.callExperimentalAPI`），传入初始化器；
///   2. 在 `ZegoExpressEngine.onRecvExperimentalAPI` 回调中，将实验性 API
///      回调内容（`content` 字符串）原样传给 `handleRoomChannelMessageWithContent:`；
///   3. 调用 `sendAgentInstanceTTSWithParams:` / `sendAgentInstanceLLMWithParams:` / 等方法发起请求；
///   4. 通过 `ZegoAIAgentActionOCCompletion` 回调等待结果，或在 `onResponse` / `onError` 中接收异步通知。
@interface ZegoAIAgentActionOCClient : NSObject

/// 业务侧请求的目标 RTC 房间 ID。
@property (nonatomic, copy, readonly) NSString *roomId;
/// 目标智能体实例的 userId，上行消息将定向发送给该用户。
///
/// 1V1 等场景下与后端 aiagent 进程加入 RTC 的 userID 一致（即 `rtcInfo.agentUserId`）；
/// 数字人通话场景下，构造器会按 `isDigitalHuman && agentInstanceId` 标志重算为
/// `ai_agent_<agentInstanceId>`，规则对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId
/// 拼接出一个内部 userID 用于接收信令。
@property (nonatomic, copy, readonly) NSString *agentUserId;
/// 当前客户端的 userId，用于生成本地业务链路追踪标识。
@property (nonatomic, copy, readonly) NSString *userId;
/// 智能体实例 ID；数字人通话场景下由调用方传入并参与 `agentUserId` 重算，其它场景可为 nil。
@property (nonatomic, copy, nullable, readonly) NSString *agentInstanceId;
/// 是否为数字人通话；为 true 且 `agentInstanceId` 非空时，构造器内部会把
/// `agentUserId` 重算为 `ai_agent_<agentInstanceId>`。
@property (nonatomic, assign, readonly) BOOL isDigitalHuman;
/// 设备 ID，本地自增 seq 时会拼接，确保多端命名空间隔离。
@property (nonatomic, copy, readonly) NSString *deviceId;
/// 请求默认超时时间（毫秒），可通过各方法的 `timeoutMs` 参数覆盖。
@property (nonatomic, assign, readonly) NSInteger timeoutMs;
@property (nonatomic, weak, readonly) id<ZegoAIAgentActionOCSender> sender;
@property (nonatomic, copy, nullable, readonly) ZegoAIAgentActionOCResponseHandler onResponse;
@property (nonatomic, copy, nullable, readonly) ZegoAIAgentActionOCErrorHandler onError;

/**
 * 初始化实例信令客户端
 *
 * @param roomId         业务房间 ID（与 ZEGO 音视频房间 ID 一致）
 * @param agentUserId    1V1 等场景下后端 aiagent 进程加入 RTC 的 userID（即 `rtcInfo.agentUserId`，形如 `@RBT#<agentId>`）；
 *                       数字人场景下本参数被忽略，套件按 `isDigitalHuman && agentInstanceId.length > 0` 自动用
 *                       `ai_agent_<agentInstanceId>`（对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId
 *                       拼接出一个内部 userID 用于接收信令）
 * @param userId         当前终端用户 ID
 * @param agentInstanceId 智能体实例 ID（数字人场景必传且非空，其它场景传 nil）
 * @param isDigitalHuman 是否为数字人通话（决定是否走 `ai_agent_<instanceId>` 拼接规则）
 * @param deviceId       设备 ID（用于构造请求 seq）；传 nil 时由套件自动生成
 * @param timeoutMs      默认超时（ms）；传 0 时使用 5000
 * @param sender         底层信令发送器（实现 ZegoAIAgentActionOCSender 协议）
 * @param onResponse     全局响应回调（可选）
 * @param onError        全局错误回调（可选）
 */
- (instancetype)initWithRoomId:(NSString *)roomId
                   agentUserId:(NSString *)agentUserId
                        userId:(NSString *)userId
               agentInstanceId:(nullable NSString *)agentInstanceId
                isDigitalHuman:(BOOL)isDigitalHuman
                      deviceId:(nullable NSString *)deviceId
                     timeoutMs:(NSInteger)timeoutMs
                        sender:(id<ZegoAIAgentActionOCSender>)sender
                    onResponse:(nullable ZegoAIAgentActionOCResponseHandler)onResponse
                       onError:(nullable ZegoAIAgentActionOCErrorHandler)onError NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 主动调用智能体 TTS。
///
/// 对应 5 类控制能力中的"主动调用 TTS"，业务侧传入 TTS 参数即可发起。
/// @param params TTS 请求参数
/// @param timeoutMs 本次请求的超时（ms）；传 nil 时使用构造器 `timeoutMs` 默认值
/// @param completion 请求完成回调（成功走 response，失败走 error）
- (void)sendAgentInstanceTTSWithParams:(SendAgentInstanceTTSParams *)params
                             timeoutMs:(nullable NSNumber *)timeoutMs
                            completion:(ZegoAIAgentActionOCCompletion)completion;

/// 主动调用智能体 LLM。
///
/// 对应 5 类控制能力中的"主动调用 LLM"，业务侧传入 LLM 参数即可发起。
/// @param params LLM 请求参数
/// @param timeoutMs 本次请求的超时（ms）；传 nil 时使用构造器 `timeoutMs` 默认值
/// @param completion 请求完成回调（成功走 response，失败走 error）
- (void)sendAgentInstanceLLMWithParams:(SendAgentInstanceLLMParams *)params
                             timeoutMs:(nullable NSNumber *)timeoutMs
                            completion:(ZegoAIAgentActionOCCompletion)completion;

/// 打断智能体实例。
///
/// 对应 5 类控制能力中的"打断智能体实例"。
/// @param timeoutMs 本次请求的超时（ms）；传 nil 时使用构造器 `timeoutMs` 默认值
/// @param completion 请求完成回调
- (void)interruptAgentInstanceWithTimeoutMs:(nullable NSNumber *)timeoutMs
                                 completion:(ZegoAIAgentActionOCCompletion)completion;

/// 智能体开始聆听指定用户。
///
/// 对应 5 类控制能力中的"开始聆听"。
/// @param params 开始聆听参数
/// @param timeoutMs 本次请求的超时（ms）；传 nil 时使用构造器 `timeoutMs` 默认值
/// @param completion 请求完成回调
- (void)startListeningWithParams:(StartListeningParams *)params
                       timeoutMs:(nullable NSNumber *)timeoutMs
                      completion:(ZegoAIAgentActionOCCompletion)completion;

/// 智能体结束聆听指定用户。
///
/// 对应 5 类控制能力中的"结束聆听"。
/// @param params 结束聆听参数
/// @param timeoutMs 本次请求的超时（ms）；传 nil 时使用构造器 `timeoutMs` 默认值
/// @param completion 请求完成回调
- (void)stopListeningWithParams:(StopListeningParams *)params
                      timeoutMs:(nullable NSNumber *)timeoutMs
                     completion:(ZegoAIAgentActionOCCompletion)completion;

/// 接收 Express 实验性 API 回调内容。
///
/// 业务侧应在 `ZegoExpressEngine.onRecvExperimentalAPI` 回调中调用此方法，
/// 把回调中的 `content` 字符串原样传入；Kit 会自动识别
/// `liveroom.room.on_recive_room_channel_message` 与
/// `liveroom.room.on_send_room_channel_message` 两种回调，匹配到对应的请求。
/// @param content Express 回调内容（JSON 字符串）
/// @return 表示是否匹配到一个 pending 请求（YES = 已处理）
- (BOOL)handleRoomChannelMessageWithContent:(NSString *)content;

/// 取消所有未完成的请求。
///
/// 通常在用户主动退出对话 / 切换实例时调用；被取消的请求会以
/// `ZegoAIAgentActionErrorCodes.canceled` 触发 `onError` 与 `completion`。
/// @param message 取消原因描述（写入错误 message 字段）
- (void)cancelAllWithMessage:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
