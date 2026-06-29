package com.zego.agentaction.demo;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.zego.agentaction.AIAgentActionProto;
import com.zego.agentaction.ZegoAIAgentActionClient;
import com.zego.agentaction.ZegoAIAgentActionDefines;
import com.zego.agentaction.ZegoAIAgentActionLogger;

import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.constants.ZegoScenario;
import im.zego.zegoexpress.entity.ZegoEngineProfile;
import im.zego.zegoexpress.entity.ZegoUser;

public class MainActivity extends Activity {
    private static final String TAG = "ZegoAIAgentActionDemo";

    private TextView logView;
    private ZegoAIAgentActionClient client;
    private final long appID = 0; // 请替换为你的 AppID
    private final String appSign = ""; // 请替换为你的 AppSign
    private final String roomId = "room_test";
    private final String userId = "client_A";
    private final String agentUserId = "agent_001";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        logView = new TextView(this);

        // 将 Kit 内部日志也输出到 Android Logcat 与 UI 日志面板。
        ZegoAIAgentActionLogger.installSink((level, label, message) -> log("[kit] " + message));
        if (BuildConfig.DEBUG) {
            ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
        } else {
            ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_WARN);
        }

        if (appID == 0) {
            log("Warning: appID is 0, please fill in your AppID and AppSign");
        }

        // 初始化 SDK
        log("createEngineWithProfile appID=" + appID);
        ZegoEngineProfile profile = new ZegoEngineProfile();
        profile.appID = appID;
        profile.appSign = appSign;
        profile.scenario = ZegoScenario.DEFAULT;
        ZegoExpressEngine.createEngine(profile, getApplication(), new IZegoEventHandler() {
            @Override
            public void onRecvExperimentalAPI(String content) {
                log("recv experimental api length=" + content.length());
                log("experimental api content: " + content);
                client.handleRoomChannelMessage(content);
            }
        });

        client = new ZegoAIAgentActionClient(
                roomId,                                                                                  // 1 roomId
                agentUserId,                                                                             // 2 agentUserId
                userId,                                                                                  // 3 userId
                null,                                                                                    // 4 agentInstanceId（非数字人场景传 null）
                false,                                                                                   // 5 isDigitalHuman
                null,                                                                                    // 6 deviceId（null 时套件自动生成 "android_<uuid8>"）
                5000,                                                                                    // 7 timeoutMs
                (params, formatedJson, callback) -> {
                    log("[sender] action=callExperimentalAPI seq=" + params.seq);
                    log("[sender] formatedJson=" + formatedJson);
                    try {
                        String result = ZegoExpressEngine.getEngine().callExperimentalAPI(formatedJson);
                        log("[sender] callExperimentalAPI result=" + result);
                    } catch (Throwable t) {
                        log("[sender] callExperimentalAPI error: " + t);
                        client.onError(new ZegoAIAgentActionClient.ZegoAIAgentActionError(
                                params.seq, "unknown", ZegoAIAgentActionDefines.ErrorCodes.SEND_FAILED, t.toString()));
                        callback.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
                                ZegoAIAgentActionDefines.ErrorCodes.SEND_FAILED, params.seq));
                        return;
                    }
                    callback.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
                            ZegoAIAgentActionDefines.ErrorCodes.SUCCESS, params.seq));
                },
                response -> log("[response] action=" + response.action + " seq=" + response.seq + " code=" + response.code + " message=" + response.message),
                error -> log("[error] action=" + error.action + " seq=" + error.seq + " code=" + error.code + " message=" + error.message)
        );

        // 登录房间
        log("loginRoom roomId=" + roomId);
        ZegoUser user = new ZegoUser(userId, userId);
        ZegoExpressEngine.getEngine().loginRoom(roomId, user);
        log("logging in to " + roomId + "...");

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        addButton(root, "TTS", () -> log("[action] TTS click"), () -> client.sendAgentInstanceTTS(
                AIAgentActionProto.SendAgentInstanceTTSParams.newBuilder()
                        .setText("你好")
                        .setAddHistory(true)
                        .setPriority("Medium")
                        .setSamePriorityOption("ClearAndInterrupt")
                        .build(),
                new LogCompletion("tts")));
        addButton(root, "LLM", () -> log("[action] LLM click"), () -> client.sendAgentInstanceLLM(
                AIAgentActionProto.SendAgentInstanceLLMParams.newBuilder()
                        .setText("你好")
                        .setSystemPrompt("")
                        .setAddQuestionToHistory(false)
                        .setAddAnswerToHistory(true)
                        .setPriority("Medium")
                        .setSamePriorityOption("ClearAndInterrupt")
                        .build(),
                new LogCompletion("llm")));
        addButton(root, "Interrupt", () -> log("[action] Interrupt click"), () -> client.interruptAgentInstance(new LogCompletion("interrupt")));
        addButton(root, "Start", () -> log("[action] Start click"), () -> client.startListening(AIAgentActionProto.StartListeningParams.newBuilder().build(), new LogCompletion("start")));
        addButton(root, "Stop", () -> log("[action] Stop click"), () -> client.stopListening(AIAgentActionProto.StopListeningParams.newBuilder().build(), new LogCompletion("stop")));
        addButton(root, "CancelAll", () -> log("[action] cancelAll click"), () -> client.cancelAll("demo cancel"));
        ScrollView scrollView = new ScrollView(this);
        scrollView.addView(logView);
        root.addView(scrollView);
        setContentView(root);
    }

    @Override
    protected void onDestroy() {
        ZegoExpressEngine.destroyEngine(null);
        super.onDestroy();
    }

    private void addButton(LinearLayout root, String title, Runnable preAction, Runnable action) {
        Button button = new Button(this);
        button.setText(title);
        button.setOnClickListener(v -> {
            preAction.run();
            action.run();
        });
        root.addView(button);
    }

    private void log(String line) {
        Log.d(TAG, line);
        logView.append(line + "\n");
    }

    private class LogCompletion implements ZegoAIAgentActionClient.Completion {
        private final String action;

        LogCompletion(String action) {
            this.action = action;
        }

        @Override
        public void onSuccess(ZegoAIAgentActionClient.ZegoAIAgentActionResponse response) {
            log("[action] " + action + " resolved seq=" + response.seq);
        }

        @Override
        public void onError(ZegoAIAgentActionClient.ZegoAIAgentActionError error) {
            log("[action] " + action + " error=" + error.message);
        }
    }
}
