import Foundation
import ZegoAIAgentAction
import ZegoExpressEngine

class DemoApp: NSObject, ZegoEventHandler {
    var client: ZegoAIAgentActionClient!
    let appID: UInt32 = 0 // 请替换为你的 AppID
    let appSign: String = "" // 请替换为你的 AppSign
    let roomId = "room_test"
    let userId = "client_A"
    let agentUserId = "agent_001"

    private func log(_ line: String) {
        print("ZegoAIAgentActionDemo \(line)")
    }

    func run() {
        // 将 Kit 内部日志同步到控制台。
        ZegoAIAgentActionLogger.installSink { line in
            print("ZegoAIAgentActionDemo [kit] \(line)")
        }
        #if DEBUG
        ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelDebug)
        #else
        ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelWarn)
        #endif

        if appID == 0 {
            log("Warning: appID is 0, please fill in your AppID and AppSign")
        }

        // 初始化 SDK
        log("createEngineWithProfile appID=\(appID)")
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = .default
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)

        client = ZegoAIAgentActionClient(
            roomId: roomId,
            agentUserId: agentUserId,
            userId: userId,
            sender: { [weak self] params, formatedJson, callback in
                guard let self = self else { return }
                self.log("[sender] action=callExperimentalAPI seq=\(params.seq)")
                self.log("[sender] formatedJson=\(formatedJson)")
                do {
                    let result = try ZegoExpressEngine.shared().callExperimentalAPI(formatedJson)
                    self.log("[sender] callExperimentalAPI result=\(result ?? "")")
                    callback(ZegoAIAgentActionSendResult(errorCode: ZegoAIAgentActionErrorCodes.success, seq: params.seq))
                } catch {
                    self.log("[sender] callExperimentalAPI error: \(error)")
                    self.client?.onError?(ZegoAIAgentActionError(
                        seq: params.seq,
                        action: "unknown",
                        code: ZegoAIAgentActionErrorCodes.sendFailed,
                        message: String(describing: error)
                    ))
                    callback(ZegoAIAgentActionSendResult(errorCode: ZegoAIAgentActionErrorCodes.sendFailed, seq: params.seq))
                }
            },
            onResponse: { response in
                self.log("[response] action=\(response.action) seq=\(response.seq) code=\(response.code) message=\(response.message)")
            },
            onError: { error in
                self.log("[error] action=\(error.action) seq=\(error.seq) code=\(error.code) message=\(error.message)")
            }
        )

        // 登录房间
        log("loginRoom roomId=\(roomId)")
        let user = ZegoUser(userID: userId, userName: userId)
        ZegoExpressEngine.shared().loginRoom(roomId, user: user)
        log("logging in to \(roomId)...")

        // 保持运行
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))

        let ttsParams = ZegoSendAgentInstanceTTSParams()
        ttsParams.text = "你好"
        log("[action] TTS click")
        client.sendAgentInstanceTTS(ttsParams) { result in
            switch result {
            case .success(let response):
                self.log("[action] TTS resolved seq=\(response.seq)")
            case .failure(let error):
                self.log("[action] TTS error: \(error.message)")
            }
        }

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 5.0))
        ZegoExpressEngine.destroy(nil)
    }

    // ZegoEventHandler
    func onRecvExperimentalAPI(_ content: String) {
        log("[express] recv experimental api length=\(content.count)")
        log("[express] \(content)")
        client.handleRoomChannelMessage(content: content)
    }

    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        log("[roomStateUpdate] roomID=\(roomID) state=\(state.rawValue) errorCode=\(errorCode)")
    }
}

let app = DemoApp()
app.run()
