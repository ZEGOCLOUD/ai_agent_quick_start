import Foundation
import SwiftProtobuf

/// 套件透传给业务方的发送参数，业务侧在 `ZegoAIAgentActionClient.Sender` 回调中拿到。
///
/// 该结构与 `ZegoAIAgentActionClient` 内部的 Express 协议一致：
///   - 调用 `ZegoExpressEngine.callExperimentalAPI` 时，业务方只需要把
///     `formatedJson` 透传给 Express SDK 即可；
///   - `msgContent` 字段在 `ZegoAIAgentActionClient` 内部已构造完成，可用于业务
///     侧在日志中记录请求体内容。
public struct ZegoAIAgentActionSendParams {
    /// 业务侧请求的目标 RTC 房间 ID，对应 Express 协议 `room_id`。
    public let roomId: String

    /// Express 消息类型，本期仅使用 `20`（请求）。
    public let msgType: Int

    /// 业务链路追踪标识（与 `msgContent.Seq` 一致），业务侧可用于日志关联。
    public let seq: String

    /// 业务请求 `msg_content` 字符串，已被 `ZegoAIAgentActionClient` 序列化为 JSON。
    public let msgContent: String

    /// 接收方用户列表，本期通常为单个智能体 userId。
    public let userList: [String]
}

/// `ZegoAIAgentActionClient.Sender` 的返回结果。
///
/// 业务侧调用 `ZegoExpressEngine.callExperimentalAPI` 时只需把
/// `formatedJson` 透传给 Express SDK；SDK 成功调用后 `errorCode` 应为
/// `ZegoAIAgentActionErrorCodes.success`；否则 Kit 会将此次请求标记为
/// "express 发送失败" 并触发 onError 回调。
public struct ZegoAIAgentActionSendResult {
    /// 0 表示成功；其它值由 Express SDK 内部定义。
    public let errorCode: Int

    /// 业务链路追踪标识。
    public let seq: String

    public init(errorCode: Int, seq: String) {
        self.errorCode = errorCode
        self.seq = seq
    }
}

/// 智能体实例控制响应，由 `ZegoAIAgentActionClient` 在收到 `msg_type=22` 响应时构造。
public struct ZegoAIAgentActionResponse {
    /// 原始 Action，例如 `SendAgentInstanceTTS`。
    public let action: String

    /// 业务链路追踪标识（与上行请求 `msgContent.Seq` 一致）。
    public let seq: String

    /// 处理结果码，0 表示成功；其它值由 PaaS 端定义。
    public let code: Int

    /// 处理结果说明，失败时包含错误信息。
    public let message: String

    /// PaaS 调用的智能体控制接口返回的 RequestId。
    public let requestId: String

    /// PaaS 返回的业务数据，可为空。
    public let data: Any?

    /// 原始 `msg_content` JSON 字符串，便于业务侧二次解析。
    public let rawMessage: String
}

/// 智能体实例控制错误。
///
/// 可能在以下场景触发：
///   - PaaS 端业务处理失败（`code` 不为 0）；
///   - Express 发送失败（`code` 为 `ZegoAIAgentActionErrorCodes.sendFailed`）；
///   - 请求超时（`code` 为 `ZegoAIAgentActionErrorCodes.timeout`）；
///   - 主动取消（`code` 为 `ZegoAIAgentActionErrorCodes.canceled`）。
public struct ZegoAIAgentActionError: Error {
    /// 业务链路追踪标识。
    public let seq: String

    /// 原始 Action。
    public let action: String

    /// 错误码。
    ///
    /// PaaS 端业务错误时为业务返回的 `Code`；本地套件错误时为
    /// `ZegoAIAgentActionErrorCodes` 中的预定义值。
    public let code: Any

    /// 错误描述。
    public let message: String
}

/// 智能体实例控制客户端。
///
/// 负责将业务侧发起的 TTS / LLM / 打断 / 聆听等请求透明地上送到 PaaS，
/// 并在收到 PaaS 响应后回传给业务侧。
///
/// 使用流程：
///   1. 业务侧构造一个 `Sender` 闭包（通常实现为直接调用
///      `ZegoExpressEngine.callExperimentalAPI`），传入初始化器；
///   2. 在 `ZegoExpressEngine.onRecvExperimentalAPI` 回调中，将实验性 API
///      回调内容（`content` 字符串）原样传给 `handleRoomChannelMessage(content:)`；
///   3. 调用 `sendAgentInstanceTTS` / `sendAgentInstanceLLM` / 等方法发起请求；
///   4. 通过 `Completion` 回调等待结果，或在 `onResponse` / `onError` 中接收异步通知。
public final class ZegoAIAgentActionClient {
    /// 业务侧实现的发送回调类型。
    ///
    /// 业务侧在该闭包中应：
    ///   1. 将 `formatedJson` 直接透传给 `ZegoExpressEngine.callExperimentalAPI`；
    ///   2. SDK 回调成功时通过 `ZegoAIAgentActionSendResult.errorCode` 标记为
    ///      `ZegoAIAgentActionErrorCodes.success`；
    ///   3. SDK 回调失败时使用 SDK 原始错误码并保持
    ///      `ZegoAIAgentActionSendResult.seq` 不变，Kit 会将此次请求标记为
    ///      失败并触发 `onError` 回调。
    public typealias Sender = (ZegoAIAgentActionSendParams, String, @escaping (ZegoAIAgentActionSendResult) -> Void) -> Void

    /// 业务侧实现的响应回调类型。
    ///
    /// 每次收到 PaaS 端业务响应时（无论成功或失败）都会触发；如果仅关心
    /// 成功响应，可以忽略非零 `ZegoAIAgentActionResponse.code` 的回调。
    public typealias ResponseHandler = (ZegoAIAgentActionResponse) -> Void

    /// 业务侧实现的错误回调类型。
    ///
    /// 触发时机：
    ///   - PaaS 端业务处理失败（`ZegoAIAgentActionError.code` 为 PaaS 返回码）；
    ///   - Express 发送失败 / 超时 / 主动取消（`ZegoAIAgentActionError.code` 为
    ///     `ZegoAIAgentActionErrorCodes` 中的预定义值）。
    public typealias ErrorHandler = (ZegoAIAgentActionError) -> Void

    /// 业务侧请求的异步完成回调类型（成功走 `.success`，失败走 `.failure`）。
    public typealias Completion = (Result<ZegoAIAgentActionResponse, ZegoAIAgentActionError>) -> Void

    private struct Pending {
        let action: String
        let timer: DispatchSourceTimer
        let completion: Completion
    }

    /// 业务侧请求的目标 RTC 房间 ID。
    public let roomId: String

    /// 目标智能体实例的 userId，上行消息将定向发送给该用户。
    ///
    /// 1V1 等场景下与后端 aiagent 进程加入 RTC 的 userID 一致（即 `rtcInfo.agentUserId`）；
    /// 数字人通话场景下，构造器会按 `isDigitalHuman && agentInstanceId` 标志重算为
    /// `ai_agent_<agentInstanceId>`，规则对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId
    /// 拼接出一个内部 userID 用于接收信令。
    public let agentUserId: String

    /// 当前客户端的 userId，用于生成本地业务链路追踪标识。
    public let userId: String

    /// 智能体实例 ID；数字人通话场景下由调用方传入并参与 `agentUserId` 重算，其它场景可为 nil。
    public let agentInstanceId: String?

    /// 是否为数字人通话；为 true 且 `agentInstanceId` 非空时，构造器内部会把
    /// `agentUserId` 重算为 `ai_agent_<agentInstanceId>`。
    public let isDigitalHuman: Bool

    /// 设备 ID，本地自增 seq 时会拼接，确保多端命名空间隔离。
    public let deviceId: String

    /// 请求默认超时时间（毫秒），可通过各方法的 `timeoutMs` 参数覆盖。
    public let timeoutMs: Int

    /// 业务侧实现的发送回调。
    public let sender: Sender

    /// 业务侧实现的响应回调（可选）。
    public let onError: ErrorHandler?

    /// 业务侧实现的错误回调（可选）。
    public let onResponse: ResponseHandler?

    private let queue = DispatchQueue(label: "com.zego.aiagent.action")
    private var localSeq: Int64 = 0
    private var expressSeq: Int32 = 0
    private var pending: [String: Pending] = [:]
    private var expressPending: [Int32: String] = [:]

    /// 构造一个智能体实例控制客户端。
    ///
    /// - Parameters:
    ///   - roomId: 业务房间 ID（与 ZEGO 音视频房间 ID 一致），必填非空
    ///   - agentUserId: 1V1 等场景下后端 aiagent 进程加入 RTC 的 userID
    ///     （即 `rtcInfo.agentUserId`，形如 `@RBT#<agentId>`）；
    ///     数字人场景下本参数被忽略，套件按 `isDigitalHuman && agentInstanceId` 非空自动用
    ///     `ai_agent_<agentInstanceId>`（对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId
    ///     拼接出一个内部 userID 用于接收信令）
    ///   - userId: 当前终端用户 ID，必填非空
    ///   - agentInstanceId: 智能体实例 ID（数字人场景必传且非空，其它场景传 nil）
    ///   - isDigitalHuman: 是否为数字人通话（决定是否走 `ai_agent_<instanceId>` 拼接规则）
    ///   - deviceId: 设备 ID（用于构造请求 seq）；传 nil 时由套件自动生成
    ///   - timeoutMs: 默认超时（ms），默认 5000
    ///   - sender: 底层信令发送回调（通常实现为 `ZegoExpressEngine.callExperimentalAPI`）
    ///   - onResponse: 全局响应回调（可选）
    ///   - onError: 全局错误回调（可选）
    public init(
        roomId: String,
        agentUserId: String,
        userId: String,
        agentInstanceId: String? = nil,
        isDigitalHuman: Bool = false,
        deviceId: String? = nil,
        timeoutMs: Int = 5000,
        sender: @escaping Sender,
        onResponse: ResponseHandler? = nil,
        onError: ErrorHandler? = nil
    ) {
        Self.requireString(roomId, "roomId")
        Self.requireString(agentUserId, "agentUserId")
        Self.requireString(userId, "userId")
        self.roomId = roomId
        // 数字人场景下后端 aiagent 进程加入 RTC 用的 userID 是 `ai_agent_<agentInstanceId>`，与 `agentUserId`
        // 入参（即 `rtcInfo.agentUserId`，形如 `@RBT#<agentId>`）不一致；信令走 sendRoomChannelMessage 的
        // userList 点对点发送，userList 必须写后端真实 userID 才能被后端收到。
        // 规则对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId 拼接出一个内部 userID 用于接收信令。
        if isDigitalHuman, let instanceId = agentInstanceId, !instanceId.isEmpty {
            // 与后端 RTC 内部用户的拼接规则对齐（`ai_agent_` 前缀 + instanceId）
            self.agentUserId = "ai_agent_" + instanceId
        } else {
            self.agentUserId = agentUserId
        }
        self.userId = userId
        // 透传构造参数，供调用方做客户端复用判断（避免跨 instance 误用旧 client）
        self.agentInstanceId = agentInstanceId
        self.isDigitalHuman = isDigitalHuman
        self.deviceId = deviceId ?? "ios_" + UUID().uuidString.prefix(8)
        self.timeoutMs = timeoutMs
        self.sender = sender
        self.onResponse = onResponse
        self.onError = onError
    }

    /// 主动调用 TTS。
    ///
    /// 对应 5 类控制能力中的"主动调用 TTS"，业务侧传入 TTS 参数即可发起。
    public func sendAgentInstanceTTS(_ params: ZegoSendAgentInstanceTTSParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        Self.requireString(params.text, "text")
        send(action: ZegoAIAgentActionName.sendAgentInstanceTTS, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    /// 主动调用 LLM。
    ///
    /// 对应 5 类控制能力中的"主动调用 LLM"，业务侧传入 LLM 参数即可发起。
    public func sendAgentInstanceLLM(_ params: ZegoSendAgentInstanceLLMParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        Self.requireString(params.text, "text")
        send(action: ZegoAIAgentActionName.sendAgentInstanceLLM, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    /// 打断智能体实例。
    ///
    /// 对应 5 类控制能力中的"打断智能体实例"。
    public func interruptAgentInstance(timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.interruptAgentInstance, params: ZegoInterruptAgentInstanceParams(), timeoutMs: timeoutMs, completion: completion)
    }

    /// 智能体开始聆听。
    ///
    /// 对应 5 类控制能力中的"开始聆听"，业务侧可传入 Start 参数指定聆听用户。
    public func startListening(_ params: ZegoStartListeningParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.startListening, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    /// 智能体结束聆听。
    ///
    /// 对应 5 类控制能力中的"结束聆听"，业务侧可传入 Stop 参数指定聆听用户。
    public func stopListening(_ params: ZegoStopListeningParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.stopListening, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    /// 接收 Express 实验性 API 回调内容。
    ///
    /// 业务侧应在 `ZegoExpressEngine.onRecvExperimentalAPI` 回调中调用此方法，
    /// 把回调中的 `content` 字符串原样传入；Kit 会自动识别
    /// `liveroom.room.on_recive_room_channel_message` 与
    /// `liveroom.room.on_send_room_channel_message` 两种回调，匹配到对应的请求。
    ///
    /// - Returns: 表示是否匹配到一个 pending 请求（true = 已处理）
    @discardableResult
    public func handleRoomChannelMessage(content: String) -> Bool {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let method = json[ZegoAIAgentActionExpressKeys.method] as? String else {
            return false
        }

        if method == ZegoAIAgentActionExpressMethods.onReciveRoomChannelMessage {
            guard let params = json[ZegoAIAgentActionExpressKeys.params] as? [String: Any],
                  let msgType = params[ZegoAIAgentActionExpressKeys.msgType] as? Int,
                  msgType == ZegoAIAgentActionMsgType.response else {
                return false
            }
            ZegoAIAgentActionLogger.debug("handleRoomChannelMessage recv: \(content)")
            guard let msgContent = params[ZegoAIAgentActionExpressKeys.msgContent] as? String,
                  let contentData = msgContent.data(using: .utf8),
                  let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                  let seq = contentJson[ZegoAIAgentActionProtocolKeys.seq] as? String,
                  let action = contentJson[ZegoAIAgentActionProtocolKeys.action] as? String,
                  contentJson[ZegoAIAgentActionProtocolKeys.code] != nil else {
                ZegoAIAgentActionLogger.warn("on_recive_room_channel_message missing required fields: \(json)")
                return false
            }

            var item: Pending?
            queue.sync {
                item = pending.removeValue(forKey: seq)
                expressPending.removeAll { $0.value == seq }
            }
            guard let item else {
                ZegoAIAgentActionLogger.warn("on_recive_room_channel_message orphan seq=\(seq)")
                return false
            }
            item.timer.cancel()

            let responseProto = Self.decodeResponse(contentJson)
            let response = ZegoAIAgentActionResponse(
                action: responseProto.action,
                seq: seq,
                code: Int(responseProto.code),
                message: responseProto.message,
                requestId: responseProto.requestID,
                data: contentJson[ZegoAIAgentActionProtocolKeys.data],
                rawMessage: msgContent
            )
            ZegoAIAgentActionLogger.info("recv action=\(response.action) seq=\(response.seq) code=\(response.code) message=\(response.message)")
            onResponse?(response)
            if response.code == ZegoAIAgentActionErrorCodes.success {
                item.completion(.success(response))
            } else {
                let error = ZegoAIAgentActionError(seq: seq, action: action, code: response.code, message: response.message)
                onError?(error)
                item.completion(.failure(error))
            }
            return true
        } else if method == ZegoAIAgentActionExpressMethods.onSendRoomChannelMessage {
            ZegoAIAgentActionLogger.debug("handleRoomChannelMessage recv: \(content)")
            guard let params = json[ZegoAIAgentActionExpressKeys.params] as? [String: Any],
                  let errorCode = params[ZegoAIAgentActionExpressKeys.errorCode] as? Int,
                  errorCode != ZegoAIAgentActionErrorCodes.success,
                  let expressSeq = params[ZegoAIAgentActionExpressKeys.seq] as? Int32 else {
                return false
            }

            var item: Pending?
            var businessSeq: String?
            queue.sync {
                businessSeq = expressPending.removeValue(forKey: expressSeq)
                if let bSeq = businessSeq {
                    item = pending.removeValue(forKey: bSeq)
                }
            }

            if let bSeq = businessSeq, let item = item {
                item.timer.cancel()
                let errorMessage = (params[ZegoAIAgentActionExpressKeys.errorMessage] as? String) ?? ""
                ZegoAIAgentActionLogger.warn("on_send_room_channel_message error seq=\(bSeq) errorCode=\(errorCode) message=\(errorMessage)")
                let error = ZegoAIAgentActionError(seq: bSeq, action: item.action, code: errorCode, message: errorMessage)
                onError?(error)
                item.completion(.failure(error))
            }
            return true
        }

        return false
    }

    /// 取消所有未完成的请求。
    ///
    /// 通常在用户主动退出对话 / 切换实例时调用；被取消的请求会以
    /// `ZegoAIAgentActionErrorCodes.canceled` 触发 `onError` 与 `Completion.failure`。
    public func cancelAll(message: String = "agent action canceled") {
        let items = queue.sync { () -> [String: Pending] in
            let values = pending
            pending.removeAll()
            return values
        }
        ZegoAIAgentActionLogger.warn("cancelAll size=\(items.count) message=\(message)")
        for (seq, item) in items {
            item.timer.cancel()
            item.completion(.failure(ZegoAIAgentActionError(seq: seq, action: item.action, code: ZegoAIAgentActionErrorCodes.canceled, message: message)))
        }
    }

    private func send<M: SwiftProtobuf.Message>(action: String, params: M, timeoutMs: Int?, completion: @escaping Completion) {
        let seq = nextSeq()
        var envelope = ZegoAgentActionEnvelope()
        envelope.action = action
        envelope.seq = seq
        envelope.params = (try? params.serializedData()) ?? Data()
        let payload = Self.encodeEnvelope(envelope, params: params)
        let msgContent = String(data: try! JSONSerialization.data(withJSONObject: payload), encoding: .utf8)!

        let currentExpressSeq = queue.sync { () -> Int32 in
            expressSeq += 1
            expressPending[expressSeq] = seq
            return expressSeq
        }

        let expressParams: [String: Any] = [
            ZegoAIAgentActionExpressKeys.roomId: roomId,
            ZegoAIAgentActionExpressKeys.msgType: ZegoAIAgentActionMsgType.request,
            ZegoAIAgentActionExpressKeys.msgContent: msgContent,
            ZegoAIAgentActionExpressKeys.userList: [agentUserId],
            ZegoAIAgentActionExpressKeys.seq: currentExpressSeq
        ]
        let expressPayload: [String: Any] = [
            ZegoAIAgentActionExpressKeys.method: ZegoAIAgentActionExpressMethods.sendRoomChannelMessage,
            ZegoAIAgentActionExpressKeys.params: expressParams
        ]
        let expressJson = String(data: try! JSONSerialization.data(withJSONObject: expressPayload), encoding: .utf8)!
        ZegoAIAgentActionLogger.info("send action=\(action) seq=\(seq) expressSeq=\(currentExpressSeq) msgContent=\(msgContent)")

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(timeoutMs ?? self.timeoutMs))
        timer.setEventHandler { [weak self] in
            guard let self, let item = self.pending.removeValue(forKey: seq) else { return }
            ZegoAIAgentActionLogger.warn("timeout action=\(action) seq=\(seq)")
            item.completion(.failure(ZegoAIAgentActionError(seq: seq, action: action, code: ZegoAIAgentActionErrorCodes.timeout, message: "agent action timeout")))
        }
        queue.sync {
            pending[seq] = Pending(action: action, timer: timer, completion: completion)
        }
        timer.resume()

        sender(ZegoAIAgentActionSendParams(roomId: roomId, msgType: ZegoAIAgentActionMsgType.request, seq: seq, msgContent: msgContent, userList: [agentUserId]), expressJson) { [weak self] result in
            ZegoAIAgentActionLogger.debug("sender result action=\(action) seq=\(seq) errorCode=\(result.errorCode)")
            guard result.errorCode != ZegoAIAgentActionErrorCodes.success else { return }
            self?.queue.sync {
                if let item = self?.pending.removeValue(forKey: seq) {
                    item.timer.cancel()
                    item.completion(.failure(ZegoAIAgentActionError(seq: seq, action: action, code: ZegoAIAgentActionErrorCodes.sendFailed, message: "send failed")))
                }
            }
        }
    }

    private func nextSeq() -> String {
        queue.sync {
            localSeq += 1
            return "\(userId):\(deviceId):\(localSeq)"
        }
    }

    private static func requireString(_ value: String, _ name: String) {
        precondition(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(name) is required")
    }

    private static func encodeEnvelope<M: SwiftProtobuf.Message>(_ envelope: ZegoAgentActionEnvelope, params: M) -> [String: Any] {
        [
            ZegoAIAgentActionProtocolKeys.action: envelope.action,
            ZegoAIAgentActionProtocolKeys.seq: envelope.seq,
            ZegoAIAgentActionProtocolKeys.params: encodeParams(params)
        ]
    }

    private static func decodeResponse(_ json: [String: Any]) -> ZegoAgentActionResponse {
        var response = ZegoAgentActionResponse()
        response.action = json[ZegoAIAgentActionProtocolKeys.action] as? String ?? ""
        response.seq = json[ZegoAIAgentActionProtocolKeys.seq] as? String ?? ""
        response.code = Int32(json[ZegoAIAgentActionProtocolKeys.code] as? Int ?? ZegoAIAgentActionErrorCodes.success)
        response.message = json[ZegoAIAgentActionProtocolKeys.message] as? String ?? ""
        response.requestID = json[ZegoAIAgentActionProtocolKeys.requestId] as? String ?? ""
        return response
    }

    /// `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的任务优先级默认值（与 aigc-agent 接口文档保持一致）
    private static let defaultPriority = "Medium"
    /// `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的相同优先级打断策略默认值（与 aigc-agent 接口文档保持一致）
    private static let defaultSamePriorityOption = "ClearAndInterrupt"

    private static func encodeParams<M: SwiftProtobuf.Message>(_ params: M) -> [String: Any] {
        switch params {
        case let value as ZegoSendAgentInstanceTTSParams:
            var json: [String: Any] = [
                ZegoAIAgentActionProtocolKeys.text: value.text,
                // addHistory：业务方未显式赋值时兜底为 API 文档默认值 true；显式赋值（true/false）按业务方值输出。
                ZegoAIAgentActionProtocolKeys.addHistory: value.hasAddHistory ? value.addHistory : true,
                // priority / samePriorityOption 为枚举字符串，客户端不显式赋值时 protobuf 默认空串会触发服务端 410000003 "Priority is invalid"，此处兜底为文档默认值。
                ZegoAIAgentActionProtocolKeys.priority: value.hasPriority ? value.priority : Self.defaultPriority,
                ZegoAIAgentActionProtocolKeys.samePriorityOption: value.hasSamePriorityOption ? value.samePriorityOption : Self.defaultSamePriorityOption
            ]
            if value.interruptMode != 0 { json[ZegoAIAgentActionProtocolKeys.interruptMode] = Int(value.interruptMode) }
            if value.enqueueUserSpeech { json[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = true }
            return json
        case let value as ZegoSendAgentInstanceLLMParams:
            var json: [String: Any] = [
                ZegoAIAgentActionProtocolKeys.text: value.text,
                ZegoAIAgentActionProtocolKeys.systemPrompt: value.systemPrompt,
                ZegoAIAgentActionProtocolKeys.addQuestionToHistory: value.addQuestionToHistory,
                // addAnswerToHistory：业务方未显式赋值时兜底为 API 文档默认值 true；显式赋值（true/false）按业务方值输出。
                ZegoAIAgentActionProtocolKeys.addAnswerToHistory: value.hasAddAnswerToHistory ? value.addAnswerToHistory : true,
                // priority / samePriorityOption：业务方未显式赋值时兜底为文档默认值。
                ZegoAIAgentActionProtocolKeys.priority: value.hasPriority ? value.priority : Self.defaultPriority,
                ZegoAIAgentActionProtocolKeys.samePriorityOption: value.hasSamePriorityOption ? value.samePriorityOption : Self.defaultSamePriorityOption
            ]
            if value.enqueueUserSpeech { json[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = true }
            return json
        case let value as ZegoStartListeningParams:
            var json: [String: Any] = [:]
            if !value.userID.isEmpty { json[ZegoAIAgentActionProtocolKeys.userId] = value.userID }
            // sequence：业务方自增序列号；Swift protobuf 对普通 int64 字段不提供 has*，用 0 判断"未设置"。
            if value.sequence != 0 { json[ZegoAIAgentActionProtocolKeys.sequence] = value.sequence }
            return json
        case let value as ZegoStopListeningParams:
            var json: [String: Any] = [:]
            if !value.userID.isEmpty { json[ZegoAIAgentActionProtocolKeys.userId] = value.userID }
            // sequence：必须与对应 StartListening 的 sequence 相同；0 表示不传。
            if value.sequence != 0 { json[ZegoAIAgentActionProtocolKeys.sequence] = value.sequence }
            return json
        case is ZegoInterruptAgentInstanceParams:
            return [:]
        default:
            return [:]
        }
    }
}
