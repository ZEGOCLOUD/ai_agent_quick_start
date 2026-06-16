import Foundation
import SwiftProtobuf

public struct ZegoAIAgentActionSendParams {
    public let roomId: String
    public let msgType: Int
    public let seq: String
    public let msgContent: String
    public let userList: [String]
}

public struct ZegoAIAgentActionSendResult {
    public let errorCode: Int
    public let seq: String

    public init(errorCode: Int, seq: String) {
        self.errorCode = errorCode
        self.seq = seq
    }
}

public struct ZegoAIAgentActionResponse {
    public let action: String
    public let seq: String
    public let code: Int
    public let message: String
    public let requestId: String
    public let data: Any?
    public let rawMessage: String
}

public struct ZegoAIAgentActionError: Error {
    public let seq: String
    public let action: String
    public let code: Any
    public let message: String
}

public final class ZegoAIAgentActionClient {
    public typealias Sender = (ZegoAIAgentActionSendParams, String, @escaping (ZegoAIAgentActionSendResult) -> Void) -> Void
    public typealias ResponseHandler = (ZegoAIAgentActionResponse) -> Void
    public typealias ErrorHandler = (ZegoAIAgentActionError) -> Void
    public typealias Completion = (Result<ZegoAIAgentActionResponse, ZegoAIAgentActionError>) -> Void

    private struct Pending {
        let action: String
        let timer: DispatchSourceTimer
        let completion: Completion
    }

    private let roomId: String
    private let agentUserId: String
    private let userId: String
    private let deviceId: String
    private let timeoutMs: Int
    private let sender: Sender
    private let onResponse: ResponseHandler?
    private let onError: ErrorHandler?
    private let queue = DispatchQueue(label: "com.zego.aiagent.action")
    private var localSeq: Int64 = 0
    private var expressSeq: Int32 = 0
    private var pending: [String: Pending] = [:]
    private var expressPending: [Int32: String] = [:]

    public init(roomId: String, agentUserId: String, userId: String, deviceId: String? = nil, timeoutMs: Int = 5000, sender: @escaping Sender, onResponse: ResponseHandler? = nil, onError: ErrorHandler? = nil) {
        Self.requireString(roomId, "roomId")
        Self.requireString(agentUserId, "agentUserId")
        Self.requireString(userId, "userId")
        self.roomId = roomId
        self.agentUserId = agentUserId
        self.userId = userId
        self.deviceId = deviceId ?? "ios_" + UUID().uuidString.prefix(8)
        self.timeoutMs = timeoutMs
        self.sender = sender
        self.onResponse = onResponse
        self.onError = onError
    }

    public func sendAgentInstanceTTS(_ params: ZegoSendAgentInstanceTTSParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        Self.requireString(params.text, "text")
        send(action: ZegoAIAgentActionName.sendAgentInstanceTTS, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    public func sendAgentInstanceLLM(_ params: ZegoSendAgentInstanceLLMParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        Self.requireString(params.text, "text")
        send(action: ZegoAIAgentActionName.sendAgentInstanceLLM, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    public func interruptAgentInstance(timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.interruptAgentInstance, params: ZegoInterruptAgentInstanceParams(), timeoutMs: timeoutMs, completion: completion)
    }

    public func startListening(_ params: ZegoStartListeningParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.startListening, params: params, timeoutMs: timeoutMs, completion: completion)
    }

    public func stopListening(_ params: ZegoStopListeningParams, timeoutMs: Int? = nil, completion: @escaping Completion) {
        send(action: ZegoAIAgentActionName.stopListening, params: params, timeoutMs: timeoutMs, completion: completion)
    }

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
                ZegoAIAgentActionProtocolKeys.addHistory: value.addHistory,
                // priority / samePriorityOption 为枚举字符串，客户端不显式赋值时 protobuf 默认空串会触发服务端 410000003 "Priority is invalid"，此处兜底为文档默认值
                ZegoAIAgentActionProtocolKeys.priority: value.priority.isEmpty ? Self.defaultPriority : value.priority,
                ZegoAIAgentActionProtocolKeys.samePriorityOption: value.samePriorityOption.isEmpty ? Self.defaultSamePriorityOption : value.samePriorityOption
            ]
            if value.interruptMode != 0 { json[ZegoAIAgentActionProtocolKeys.interruptMode] = Int(value.interruptMode) }
            if value.enqueueUserSpeech { json[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = true }
            return json
        case let value as ZegoSendAgentInstanceLLMParams:
            var json: [String: Any] = [
                ZegoAIAgentActionProtocolKeys.text: value.text,
                ZegoAIAgentActionProtocolKeys.systemPrompt: value.systemPrompt,
                ZegoAIAgentActionProtocolKeys.addQuestionToHistory: value.addQuestionToHistory,
                ZegoAIAgentActionProtocolKeys.addAnswerToHistory: value.addAnswerToHistory,
                // 同 TTS：枚举字段空串兜底为文档默认值，避免服务端校验失败
                ZegoAIAgentActionProtocolKeys.priority: value.priority.isEmpty ? Self.defaultPriority : value.priority,
                ZegoAIAgentActionProtocolKeys.samePriorityOption: value.samePriorityOption.isEmpty ? Self.defaultSamePriorityOption : value.samePriorityOption
            ]
            if value.enqueueUserSpeech { json[ZegoAIAgentActionProtocolKeys.enqueueUserSpeech] = true }
            return json
        case let value as ZegoStartListeningParams:
            var json: [String: Any] = [:]
            if !value.userID.isEmpty { json[ZegoAIAgentActionProtocolKeys.userId] = value.userID }
            return json
        case let value as ZegoStopListeningParams:
            var json: [String: Any] = [:]
            if !value.userID.isEmpty { json[ZegoAIAgentActionProtocolKeys.userId] = value.userID }
            return json
        case is ZegoInterruptAgentInstanceParams:
            return [:]
        default:
            return [:]
        }
    }
}
