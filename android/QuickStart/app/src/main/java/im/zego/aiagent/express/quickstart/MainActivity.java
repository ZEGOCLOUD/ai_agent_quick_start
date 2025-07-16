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
import com.google.gson.JsonObject;
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
import java.util.concurrent.TimeUnit;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;
import okhttp3.logging.HttpLoggingInterceptor.Level;
import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private AudioChatMessageParser audioChatMessageParser = new AudioChatMessageParser();
    private boolean login = false;
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY)).build();
    private TextView loadingText;
    private String agent_instance_id;
    private String agent_user_id; //agent推流id，数字人推流id
    private String agent_stream_id; //agent推流id，数字人推流id
    private String agent_name; //agent推流id，数字人推流id
    private String agentId;

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
        TextView roomId = findViewById(R.id.room_id);
        userId.setText(Constant.user_id);
        userName.setText(Constant.userName);
        roomId.setText("RoomId:" + Constant.room_id);

        loadingText = findViewById(R.id.loading_text);

        findViewById(R.id.login_room).setOnClickListener(v -> {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
        });

        agentId = getIntent().getStringExtra("agent_id");
        agent_name = getIntent().getStringExtra("agent_name");
        boolean fromTextChat = getIntent().getBooleanExtra("fromTextChat", false);
        if (fromTextChat) {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
        }
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
                    Toast.makeText(MainActivity.this, "please enable record permission", Toast.LENGTH_SHORT).show();
                }
            }
        });


    private void start() {
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("room_id", Constant.room_id);
        jsonObject.addProperty("user_id", Constant.user_id);
        jsonObject.addProperty("user_stream_id", Constant.user_stream_id);
        jsonObject.addProperty("agent_id", agentId);
        RequestBody body = RequestBody.create(jsonObject.toString(), JSON);

        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/start").post(body).build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                ZegoExpressEngine.getEngine().logoutRoom();
                resetUI("start failed");
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
                        if (json.has("agent_name")) {
                            agent_name = (String) json.get("agent_name");
                        }
                        if (json.has("agent_user_id")) {
                            agent_user_id = (String) json.get("agent_user_id");
                        }
                        if (json.has("agent_stream_id")) {
                            agent_stream_id = (String) json.get("agent_stream_id");
                        }
                        if (json.has("agent_instance_id")) {
                            agent_instance_id = (String) json.get("agent_instance_id");
                        }
                        if (errorCode == 0) {
                            ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                            updateUI();
                        } else {
                            ZegoExpressEngine.getEngine().logoutRoom();
                            resetUI("start fail");
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    ZegoExpressEngine.getEngine().logoutRoom();
                    resetUI("start faild");
                }

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
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("agent_instance_id", agent_instance_id);
        RequestBody body = RequestBody.create(jsonObject.toString(), JSON);

        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/stop").post(body).build();

        client.newCall(request).enqueue(new Callback() {
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
                    boolean fromTextChat = getIntent().getBooleanExtra("fromTextChat", false);
                    if (fromTextChat) {
                        finish();
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                }

            }
        });
    }

    private void requestZegoToken() {
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/zego-token?userId=" + Constant.user_id)
            .get().build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                resetUI("get token failed");
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
                            loginRoom(Constant.user_id, Constant.user_id, token, new IZegoRoomLoginCallback() {
                                @Override
                                public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                    if (errorCode == 0) {
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
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    resetUI("get token failed");
                }

            }
        });
    }

    private void initExpressSDK() {
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = Constant.appId;
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
            .loginRoom(Constant.room_id, new ZegoUser(userId, userName), roomConfig, (errorCode, extendedData) -> {
                Log.d(TAG,
                    "loginRoom() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                if (errorCode == 0) {
                    ZegoExpressEngine.getEngine().startPublishingStream(Constant.user_stream_id);
                    ZegoExpressEngine.getEngine().muteMicrophone(false);
                }
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
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
        if (ZegoExpressEngine.getEngine() != null) {
            ZegoExpressEngine.getEngine().logoutRoom();
            ZegoExpressEngine.getEngine().setEventHandler(null);
            ZegoExpressEngine.destroyEngine(null);
        }
    }
}