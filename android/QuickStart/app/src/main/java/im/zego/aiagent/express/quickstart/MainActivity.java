package im.zego.aiagent.express.quickstart;

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
import im.zego.aiagent.express.quickstart.AudioChatMessageParser.AudioChatMessage;
import im.zego.aiagent.express.quickstart.AudioChatMessageParser.AudioChatMessageListListener;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoAECMode;
import im.zego.zegoexpress.constants.ZegoANSMode;
import im.zego.zegoexpress.constants.ZegoAudioDeviceMode;
import im.zego.zegoexpress.constants.ZegoScenario;
import im.zego.zegoexpress.entity.ZegoEngineConfig;
import im.zego.zegoexpress.entity.ZegoEngineProfile;
import im.zego.zegoexpress.entity.ZegoRoomConfig;
import im.zego.zegoexpress.entity.ZegoUser;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private AudioChatMessageParser audioChatMessageParser = new AudioChatMessageParser();
    private long appId = ; // YOUR APPID from 即构
    private final String user_id = "user_id_1";
    private final String room_id = "room_id_1";
    private final String agent_stream_id = "agent_stream_id_1";
    private final String agent_user_id = "agent_user_id_1";
    private final String user_stream_id = "user_stream_id_1";
    private boolean login = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        initExpressSDK();

        initChatText();

        TextView userId = findViewById(R.id.user_id);
        TextView userName = findViewById(R.id.user_name);
        userId.setText(user_id);
        userName.setText(user_id);

        findViewById(R.id.login_room).setOnClickListener(v -> {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
        });
    }

    private final ActivityResultLauncher<String> requestPermissionLauncher = registerForActivityResult(
        new ActivityResultContracts.RequestPermission(), new ActivityResultCallback<Boolean>() {
            @Override
            public void onActivityResult(Boolean isGranted) {
                if (isGranted) {
                    if (login) {
                        showLoading(true);
                        stop();
                    } else {
                        showLoading(true);
                        requestZegoToken();
                    }
                } else {
                    Toast.makeText(MainActivity.this, "请先开启录音权限", Toast.LENGTH_SHORT).show();
                }
            }
        });


    private void start() {
        ZegoQuickStartApi.start(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                ZegoExpressEngine.getEngine().logoutRoom();
                resetUI("start 失败");
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    System.out.println(responseBody);

                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        String agent_id = (String) json.get("agent_id");
                        String agent_name = (String) json.get("agent_name");
                        if (errorCode == 0) {
                            ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                            updateUI(agent_name);
                        } else {
                            ZegoExpressEngine.getEngine().logoutRoom();
                            resetUI("start 失败");
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    ZegoExpressEngine.getEngine().logoutRoom();
                    resetUI("start 失败");
                }

            }
        });
    }

    private void updateUI(String agent_name) {
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
                Toast.makeText(MainActivity.this, s, Toast.LENGTH_SHORT).show();
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
        ZegoQuickStartApi.stop(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                resetUI("");
                ZegoExpressEngine.getEngine().logoutRoom();
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    System.out.println(responseBody);

                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        ZegoExpressEngine.getEngine().logoutRoom();
                        resetUI("");
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                }

            }
        });
    }

    private void requestZegoToken() {

        ZegoQuickStartApi.getZegoToken(user_id, new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                resetUI("获取token失败");
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    System.out.println(responseBody);
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        String token = (String) json.get("token");
                        long expireTime = (long) json.get("expire_time");

                        if (!TextUtils.isEmpty(token)) {
                            loginRoom(user_id, user_id, token, new IZegoRoomLoginCallback() {
                                @Override
                                public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                    if (errorCode == 0) {
                                        start();
                                    } else {
                                        resetUI("加入房间失败");
                                    }
                                }
                            });

                        } else {
                            resetUI("获取token失败");
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    resetUI("获取token失败");
                }

            }
        });
    }

    private void initExpressSDK() {
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = appId;
        zegoEngineProfile.scenario = ZegoScenario.HIGH_QUALITY_CHATROOM;
        zegoEngineProfile.application = getApplication();
        ZegoExpressEngine.createEngine(zegoEngineProfile, null);
    }

    private void initChatText() {
        ZegoExpressEngine.getEngine().setEventHandler(new IZegoEventHandler() {
            @Override
            public void onRecvExperimentalAPI(String content) {
                super.onRecvExperimentalAPI(content);
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

        });

        AIChatListView messageList = findViewById(R.id.ai_chat_list);
        audioChatMessageParser.setAudioChatMessageListListener(new AudioChatMessageListListener() {
            @Override
            public void onMessageListUpdated(List<AudioChatMessage> messagesList) {
                messageList.onMessageListUpdated(messagesList);
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

    private void loginRoom(String userId, String userName, String token, IZegoRoomLoginCallback callback) {
        ZegoEngineConfig config = new ZegoEngineConfig();
        HashMap<String, String> advanceConfig = new HashMap<String, String>();
        advanceConfig.put("set_audio_volume_ducking_mode", "1");
        advanceConfig.put("enable_rnd_volume_adaptive", "true");
        config.advancedConfig = advanceConfig;
        ZegoExpressEngine.setEngineConfig(config);

        ZegoExpressEngine.getEngine().setRoomScenario(ZegoScenario.HIGH_QUALITY_CHATROOM);

        ZegoExpressEngine.getEngine().setAudioDeviceMode(ZegoAudioDeviceMode.GENERAL);

        ZegoExpressEngine.getEngine().enableAEC(true);
        ZegoExpressEngine.getEngine().setAECMode(ZegoAECMode.AI_AGGRESSIVE2);
        ZegoExpressEngine.getEngine().enableAGC(true);
        ZegoExpressEngine.getEngine().enableANS(true);
        ZegoExpressEngine.getEngine().setANSMode(ZegoANSMode.MEDIUM);

        ZegoRoomConfig roomConfig = new ZegoRoomConfig();
        roomConfig.isUserStatusNotify = true;
        roomConfig.token = token;

        ZegoExpressEngine.getEngine()
            .loginRoom(room_id, new ZegoUser(userId, userName), roomConfig, (errorCode, extendedData) -> {
                Log.d(TAG,
                    "loginRoom() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                if (errorCode == 0) {
                    ZegoExpressEngine.getEngine().startPublishingStream(user_stream_id);
                    ZegoExpressEngine.getEngine().muteMicrophone(false);
                }
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
                }

            });
    }

    private void showLoading(boolean show) {
        findViewById(R.id.loading_progress).setVisibility(show ? View.VISIBLE : View.GONE);
        findViewById(R.id.login_room).setEnabled(!show);
    }
}