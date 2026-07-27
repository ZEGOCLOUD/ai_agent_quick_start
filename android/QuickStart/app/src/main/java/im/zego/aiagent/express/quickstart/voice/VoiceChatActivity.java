package im.zego.aiagent.express.quickstart.voice;

import android.Manifest;
import android.graphics.Color;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import im.zego.aiagent.express.quickstart.Constant;
import im.zego.aiagent.express.quickstart.R;
import im.zego.aiagent.express.quickstart.util.ExpressHelper;
import im.zego.aiagent.express.quickstart.util.HttpHelper;
import im.zego.aiagent.express.quickstart.util.QuickStartApi;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser.AudioChatAgentStatusMessage;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser.AudioChatMessage;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser.AudioChatMessageListListener;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.entity.ZegoUser;
import java.util.HashMap;
import java.util.List;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * 语音通话：与 AI Agent 进行实时语音对话（双向语音，无数字人形象）。
 * <p>
 * 页面有一个「登录/登出」按钮：登录后开始通话，再次点击登出并停止。
 * <p>
 * 接口调用顺序：
 * <pre>
 * 1. initExpressSDK()            初始化 Express 引擎
 * 2. requestZegoToken()          GET  /api/zego-token      获取登录 token
 * 3. ExpressHelper.loginRoom()   登录 Express 房间（advancedConfig 仅 2 项，无 sideinfo）
 * 4. ├─ startPublishingStream()  房间登录成功后：推本地流
 *    └─ start()                  POST /api/start          启动 AI Agent
 * 5. (拉 Agent 流，开始语音对话)
 *
 * 结束（点击登出）：
 * 6. stop()                      POST /api/stop           停止 AI Agent + 登出房间
 * </pre>
 * 详见 README.md「核心流程」。
 */
public class VoiceChatActivity extends AppCompatActivity {

    private static final String TAG = "VoiceChatActivity";
    private AudioChatMessageParser audioChatMessageParser = new AudioChatMessageParser();
    private boolean login = false;
    private TextView loadingText;
    private String agent_instance_id;
    private String agent_user_id; //agent推流id，数字人推流id
    private String agent_stream_id; //agent推流id，数字人推流id
    private String agent_name; //agent推流id，数字人推流id

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_voice);
        initViews();
        initExpressSDK();
        initChatText();
    }

    /**
     * 初始化控件：状态栏内边距、用户/房间信息展示、登录按钮
     */
    private void initViews() {
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        // 展示当前用户与房间信息
        TextView userId = findViewById(R.id.user_id);
        TextView userName = findViewById(R.id.user_name);
        TextView roomId = findViewById(R.id.room_id);
        userId.setText(Constant.user_id);
        userName.setText(Constant.userName);
        roomId.setText("RoomId:" + Constant.room_id);
        loadingText = findViewById(R.id.loading_text);
        // 点击登录/登出按钮，先申请麦克风权限
        findViewById(R.id.login_room)
            .setOnClickListener(v -> requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO));
    }

    private final ActivityResultLauncher<String> requestPermissionLauncher = registerForActivityResult(
        new ActivityResultContracts.RequestPermission(), new ActivityResultCallback<Boolean>() {
            @Override
            public void onActivityResult(Boolean isGranted) {
                if (isGranted) {
                    if (login) {
                        showLoading(true);
                        loadingText.setText("Logout");
                        stop();
                    } else {
                        showLoading(true);
                        loadingText.setText("Login");
                        requestZegoToken();
                    }
                } else {
                    Toast.makeText(VoiceChatActivity.this, "please enable audio permission", Toast.LENGTH_SHORT).show();
                }
            }
        });


    private void start() {
        QuickStartApi.start(Constant.room_id, Constant.user_id, Constant.user_stream_id,
            new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                Log.d(TAG, "api/start onResponse: " + responseBody);
                try {
                    JSONObject json = new JSONObject(responseBody);
                    int errorCode = json.optInt("code", -1);
                    // 以下字段为业务元数据，后台可能不下发，缺失不应阻断主流程
                    agent_name = json.optString("agent_name");
                    agent_instance_id = json.optString("agent_instance_id");
                    agent_user_id = json.optString("agent_user_id");
                    agent_stream_id = json.optString("agent_stream_id");
                    if (errorCode == 0) {
                        ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                        updateUI();
                    } else {
                        ZegoExpressEngine.getEngine().logoutRoom();
                        resetUI("start failed");
                    }
                } catch (JSONException e) {
                    resetUI("start failed");
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                ZegoExpressEngine.getEngine().logoutRoom();
                resetUI("start failed");
            }
        });
    }

    private void updateUI() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                login = true;
                showLoading(false);
                Button loginRoom = findViewById(R.id.login_room);
                loginRoom.setBackgroundColor(Color.parseColor("#E56666"));
                loginRoom.setText("LogoutRoom");

                TextView agentUserId = findViewById(R.id.agent_user_id);
                TextView agentUserName = findViewById(R.id.agent_user_name);
                agentUserId.setText(agent_user_id);
                agentUserName.setText(agent_name);
            }
        });
    }

    private void resetUI(String s) {
        runOnUiThread(() -> {
            login = false;
            showLoading(false);
            if (!TextUtils.isEmpty(s)) {
                Toast.makeText(VoiceChatActivity.this, s, Toast.LENGTH_SHORT).show();
            }
            Button loginRoom = findViewById(R.id.login_room);
            loginRoom.setBackgroundColor(Color.parseColor("#99F233"));
            loginRoom.setText("LoginRoom");

            TextView agentUserId = findViewById(R.id.agent_user_id);
            TextView agentUserName = findViewById(R.id.agent_user_name);
            agentUserId.setText("");
            agentUserName.setText("");
        });
    }

    private void stop() {
        QuickStartApi.stop(agent_instance_id, new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                ZegoExpressEngine.getEngine().logoutRoom();
                resetUI("");
            }

            @Override
            public void onFailure(String errorMsg) {
                resetUI("");
                ZegoExpressEngine.getEngine().logoutRoom();
            }
        });
    }

    private void requestZegoToken() {
        QuickStartApi.getZegoToken(Constant.user_id, new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                try {
                    JSONObject json = new JSONObject(responseBody);
                    String token = (String) json.get("token");

                    if (!TextUtils.isEmpty(token)) {
                        // 语音场景的引擎高级配置（比数字人场景少 sideinfo 相关项）
                        HashMap<String, String> advancedConfig = new HashMap<>();
                        advancedConfig.put("set_audio_volume_ducking_mode", "1");
                        advancedConfig.put("enable_rnd_volume_adaptive", "true");
                        ExpressHelper.loginRoom(Constant.user_id, Constant.user_id, token, advancedConfig,
                            new IZegoRoomLoginCallback() {
                                @Override
                                public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                    if (errorCode == 0) {
                                        // 登录成功后推本地流，再启动 Agent
                                        ZegoExpressEngine.getEngine().startPublishingStream(Constant.user_stream_id);
                                        ZegoExpressEngine.getEngine().muteMicrophone(false);
                                        start();
                                    } else {
                                        resetUI("join room failed");
                                    }
                                }
                            });
                    } else {
                        resetUI("get token failed");
                    }
                } catch (JSONException e) {
                    resetUI("get token failed");
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                resetUI("get token failed");
            }
        });
    }

    private void initExpressSDK() {
        ExpressHelper.initEngine(getApplication());
    }

    private void initChatText() {
        ZegoExpressEngine.getEngine().setEventHandler(new IZegoEventHandler() {

            @Override
            public void onRecvExperimentalAPI(String content) {
                super.onRecvExperimentalAPI(content);
                Log.d(TAG, "onRecvExperimentalAPI() called with: content = [" + content + "]");
                try {
                    // 第一步：将 content 解析为 JSONObject
                    JSONObject json = new JSONObject(content);

                    // 第二步：检查 method 字段的值
                    if (json.has("method") && json.getString("method")
                        .equals("liveroom.room.on_recive_room_channel_message")) {
                        // 第三步：获取 params 并解析
                        JSONObject paramsObject = json.getJSONObject("params");
                        String msgContent = paramsObject.getString("msg_content");

                        // 假设 AudioChatTextMessage 有构造函数或方法来解析 JSON 字符串
                        audioChatMessageParser.parseAudioChatMessage(msgContent);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command) {
                super.onIMRecvCustomCommand(roomID, fromUser, command);
                Log.d(TAG, "onIMRecvCustomCommand() called with: roomID = [" + roomID + "], fromUser = [" + fromUser
                    + "], command = [" + command + "]");
            }

        });

        AIChatListView messageList = findViewById(R.id.ai_chat_list);
        audioChatMessageParser.setAudioChatMessageListListener(new AudioChatMessageListListener() {
            @Override
            public void onMessageListUpdated(List<AudioChatMessage> messagesList) {
                messageList.onMessageListUpdated(messagesList);
            }

            @Override
            public void onAudioChatStateUpdate(AudioChatAgentStatusMessage statusMessage) {

            }
        });

        findViewById(R.id.subtitles).setOnClickListener(v -> {
            if (messageList.getVisibility() == View.VISIBLE) {
                messageList.setVisibility(View.GONE);
            } else {
                messageList.setVisibility(View.VISIBLE);
            }
        });
    }

    private void showLoading(boolean show) {
        findViewById(R.id.loading_layout).setVisibility(show ? View.VISIBLE : View.GONE);
        findViewById(R.id.login_room).setEnabled(!show);
    }

    private boolean finishedInOnPauseLifeCycle = false;

    @Override
    protected void onPause() {
        super.onPause();
        if (isFinishing()) {
            // 正常 finish,直接 clear
            // 比如反复进出此页面，不会引起时序的问题。
            finishedInOnPauseLifeCycle = true;
            onActivityStartDestroy();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (!finishedInOnPauseLifeCycle) {
            onActivityStartDestroy();
        }
    }

    // 由于 onDestroy 是一个异步的过程，同一个界面反复进出可能会导致
    // 当前activity 的 oncreate 先执行，然后上一个activity的onDestroy后执行
    // 如果是正常的finish, 这里在 onPause 里面去判断，如果是 finish 状态，则先执行清理。
    protected void onActivityStartDestroy() {
        ExpressHelper.destroyEngine();
    }
}