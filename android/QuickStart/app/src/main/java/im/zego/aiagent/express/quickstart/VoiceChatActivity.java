package im.zego.aiagent.express.quickstart;

import android.net.Uri;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.squareup.picasso.Picasso;
import im.zego.aiagent.express.quickstart.backend.ZegoAIAgentAPI;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig;
import im.zego.aiagent.express.quickstart.backend.data.RtcInfo;
import im.zego.aiagent.express.quickstart.backend.network.CustomHttpClient;
import im.zego.aiagent.express.quickstart.backend.network_wrapper.ZegoAIAgentHttpHelper;
import im.zego.aiagent.express.quickstart.core.AuthData;
import im.zego.aiagent.express.quickstart.core.UserProfile;
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
import java.util.HashMap;
import timber.log.Timber;

public class VoiceChatActivity extends AppCompatActivity {

    private String background_url = "https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg";
    public Gson mGson = new GsonBuilder().setPrettyPrinting().create();
    private ZegoAIAgentAPI zegoAIAgentAPI = new ZegoAIAgentAPI(mGson,
        new ZegoAIAgentHttpHelper(mGson, new CustomHttpClient()));
    private String agentInstanceId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_voice_chat);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        AgentConfig agentConfig = mGson.fromJson(getIntent().getStringExtra("agentConfig"), AgentConfig.class);
        UserProfile userProfile = mGson.fromJson(getIntent().getStringExtra("userProfile"), UserProfile.class);
        AuthData authData = mGson.fromJson(getIntent().getStringExtra("authData"), AuthData.class);
        String agentId = getIntent().getStringExtra("agentId");

        TextView name = findViewById(R.id.ai_name);
        name.setText(agentConfig.name);
        ImageView bg = findViewById(R.id.background);
        Picasso.get().load(Uri.parse(background_url)).into(bg);

        findViewById(R.id.end_call).setOnClickListener(v -> {
            zegoAIAgentAPI.deleteAgentInstance(authData.appID, authData.serverSecret, agentInstanceId,
                (errorCode, message, requestId) -> {
                    if (errorCode == 0) {
                        TextView textView = findViewById(R.id.status);
                        textView.setText("已断开");
                    }
                    ZegoExpressEngine.getEngine().logoutRoom();
                    ZegoExpressEngine.destroyEngine(null);
                    finish();
                });
        });

        initExpressSDK(authData);

        loginRoom(agentId, userProfile, (errorCode, extendedData) -> {
            if (errorCode == 0) {
                String agentStreamID = generateAgentStreamID(agentId, userProfile);
                RtcInfo rtcInfo = new RtcInfo();
                rtcInfo.roomId = generateRoomID(agentId);
                rtcInfo.agentStreamId = generateAgentStreamID(agentId, userProfile);
                rtcInfo.userStreamId = generateUserStreamID(agentId, userProfile);
                rtcInfo.agentUserId = agentId;

                zegoAIAgentAPI.createAgentInstance(authData.appID, authData.serverSecret, agentId, userProfile.userID,
                    rtcInfo, (errorCode1, message, requestId, createAgentInstanceRsp) -> {
                        if (errorCode1 == 0) {
                            agentInstanceId = createAgentInstanceRsp.agentInstanceId;
                            ZegoExpressEngine.getEngine().startPlayingStream(agentStreamID);
                            onVoiceChatReady();
                        }else {
                            TextView textView = findViewById(R.id.status);
                            textView.setText("已断开");
                        }
                    });
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


    private void initExpressSDK(AuthData authData) {
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = authData.appID;
        zegoEngineProfile.appSign = authData.appSign;
        zegoEngineProfile.scenario = ZegoScenario.HIGH_QUALITY_CHATROOM;
        zegoEngineProfile.application = getApplication();
        ZegoExpressEngine.createEngine(zegoEngineProfile, null);
    }

    private void loginRoom(String agentId, UserProfile userProfile, IZegoRoomLoginCallback callback) {
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

        String roomId = generateRoomID(agentId);
        ZegoExpressEngine.getEngine()
            .loginRoom(roomId, new ZegoUser(userProfile.userID, userProfile.userName), roomConfig,
                (errorCode, extendedData) -> {
                    Timber.d("loginRoom() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData
                        + "]");
                    if (errorCode == 0) {
                        String userSteamID = generateUserStreamID(agentId, userProfile);
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

    public static String generateUserStreamID(String agentId, UserProfile userProfile) {
        return generateRoomID(agentId) + "_" + userProfile.userID + "_main";
    }

    public static String generateAgentStreamID(String agentId, UserProfile userProfile) {
        return agentId + "_" + userProfile.userID + "_robot" + "_main";
    }
}