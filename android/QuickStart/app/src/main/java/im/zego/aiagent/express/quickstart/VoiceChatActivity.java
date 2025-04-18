package im.zego.aiagent.express.quickstart;

import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.squareup.picasso.Picasso;
import im.zego.zegoexpress.ZegoExpressEngine;
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
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import org.json.JSONException;
import org.json.JSONObject;
import timber.log.Timber;

public class VoiceChatActivity extends AppCompatActivity {

    private String background_url = "https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg";
    private String agentInstanceId;
    private String agentId;
    private String agentName;
    private String userId = ;  // 用户自己定义的 userId
    private String userName = ; // 用户自己定义的 userName
    private long appId =;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_voice_chat);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        agentId = getIntent().getStringExtra("agentId");
        agentName = getIntent().getStringExtra("agentName");

        TextView name = findViewById(R.id.ai_name);
        name.setText(agentName);
        ImageView bg = findViewById(R.id.background);
        Picasso.get().load(Uri.parse(background_url)).into(bg);

        findViewById(R.id.end_call).setOnClickListener(v -> {
            deleteAgentInstance();
        });

        initExpressSDK();

        requestZegoToken(userId);
    }

    private void createAgentInstance(String roomId, String userStreamId, String agentStreamId, String agentUserId,
        String agentStreamID) {
        ZegoQuickStartApi.createAgentInstance(agentId, roomId, userId, userStreamId, agentStreamId, agentUserId,
            new Callback() {
                @Override
                public void onFailure(@NonNull Call call, @NonNull IOException e) {
                    System.err.println("Request failed: " + e.getMessage());
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
                            String agentInstanceId = (String) json.get("agent_instance_id");
                            runOnUiThread(() -> {
                                if (errorCode == 0) {
                                    VoiceChatActivity.this.agentInstanceId = agentInstanceId;
                                    ZegoExpressEngine.getEngine().startPlayingStream(agentStreamID);
                                    onVoiceChatReady();
                                } else {
                                    TextView textView = findViewById(R.id.status);
                                    textView.setText("已断开");
                                }
                            });
                        } catch (JSONException e) {
                            throw new RuntimeException(e);
                        }
                    } else {
                        System.err.println("Request failed with status: " + response.code());
                    }

                }
            });
    }

    private void deleteAgentInstance() {
        ZegoQuickStartApi.deleteAgentInstance(agentInstanceId, new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
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
                        runOnUiThread(() -> {
                            if (errorCode == 0) {
                                TextView textView = findViewById(R.id.status);
                                textView.setText("已断开");
                            }
                            ZegoExpressEngine.getEngine().logoutRoom();
                            ZegoExpressEngine.destroyEngine(null);
                            finish();
                        });

                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                }

            }
        });
    }

    private void requestZegoToken(String userId) {
        ZegoQuickStartApi.getZegoToken(userId, new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
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
                            loginRoom(agentId, userId, userName, token, (errorCode, extendedData) -> {
                                if (errorCode == 0) {
                                    String agentStreamID = generateAgentStreamID(agentId, userId);
                                    String roomId = generateRoomID(agentId);
                                    String agentStreamId = generateAgentStreamID(agentId, userId);
                                    String userStreamId = generateUserStreamID(agentId, userId);
                                    String agentUserId = agentId;

                                    createAgentInstance(roomId, userStreamId, agentStreamId, agentUserId, agentStreamID);
                                }
                            });
                        } else {
                            runOnUiThread(() -> {
                                Toast.makeText(VoiceChatActivity.this, "获取token失败", Toast.LENGTH_SHORT).show();
                                finish();
                            });
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                }

            }
        });
    }

    private void onVoiceChatReady() {
        // AI READY
        TextView textView = findViewById(R.id.status);
        textView.setText("已连接");
    }

    @Override
    public void onBackPressed() {

    }


    private void initExpressSDK() {
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = appId;
        zegoEngineProfile.scenario = ZegoScenario.HIGH_QUALITY_CHATROOM;
        zegoEngineProfile.application = getApplication();
        ZegoExpressEngine.createEngine(zegoEngineProfile, null);
    }

    private void loginRoom(String agentId, String userId, String userName, String token,
        IZegoRoomLoginCallback callback) {
        ZegoEngineConfig config = new ZegoEngineConfig();
        HashMap<String, String> advanceConfig = new HashMap<String, String>();
        advanceConfig.put("set_audio_volume_ducking_mode", "1");
        advanceConfig.put("enable_rnd_volume_adaptive", "true");
        config.advancedConfig = advanceConfig;
        ZegoExpressEngine.setEngineConfig(config);

        ZegoExpressEngine.getEngine().setRoomScenario(ZegoScenario.HIGH_QUALITY_CHATROOM);

        ZegoExpressEngine.getEngine().setAudioDeviceMode(ZegoAudioDeviceMode.GENERAL);

        ZegoExpressEngine.getEngine().enableAEC(true);
        ZegoExpressEngine.getEngine().setAECMode(ZegoAECMode.AI_AGGRESSIVE);
        ZegoExpressEngine.getEngine().enableAGC(true);
        ZegoExpressEngine.getEngine().enableANS(true);
        ZegoExpressEngine.getEngine().setANSMode(ZegoANSMode.AI_BALANCED);

        ZegoRoomConfig roomConfig = new ZegoRoomConfig();
        roomConfig.isUserStatusNotify = true;
        roomConfig.token = token;

        String roomId = generateRoomID(agentId);
        ZegoExpressEngine.getEngine()
            .loginRoom(roomId, new ZegoUser(userId, userName), roomConfig, (errorCode, extendedData) -> {
                Timber.d(
                    "loginRoom() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                if (errorCode == 0) {
                    String userSteamID = generateUserStreamID(agentId, userId);
                    ZegoExpressEngine.getEngine().startPublishingStream(userSteamID);
                    ZegoExpressEngine.getEngine().muteMicrophone(false);
                }
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
                }

            });
    }

    public static String generateRoomID(String agentId) {
        return "ar_" + agentId;
    }

    public static String generateUserStreamID(String agentId, String userId) {
        return generateRoomID(agentId) + "_" + userId + "_main";
    }

    public static String generateAgentStreamID(String agentId, String userId) {
        return agentId + "_" + userId + "_robot" + "_main";
    }
}