package im.zego.aiagent.express.quickstart;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import im.zego.aiagent.express.quickstart.backend.ZegoAIAgentAPI;
import im.zego.aiagent.express.quickstart.backend.callback.RegisterAgentCallback;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig.LLM;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig.TTS;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig.TTS.Params;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig.TTS.Params.App;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig.TTS.Params.Audio;
import im.zego.aiagent.express.quickstart.backend.network.CustomHttpClient;
import im.zego.aiagent.express.quickstart.backend.network_wrapper.ZegoAIAgentHttpHelper;
import im.zego.aiagent.express.quickstart.core.AuthData;
import im.zego.aiagent.express.quickstart.core.UserProfile;
import timber.log.Timber;
import timber.log.Timber.DebugTree;

public class MainActivity extends AppCompatActivity {

    private String userId = ;  // 用户自己定义的 userId
    private String userName = ; // 用户自己定义的 userName

    public Gson mGson = new GsonBuilder().setPrettyPrinting().create();
    private ZegoAIAgentAPI zegoAIAgentAPI = new ZegoAIAgentAPI(mGson,
        new ZegoAIAgentHttpHelper(mGson, new CustomHttpClient()));

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        Timber.plant(new DebugTree());
        findViewById(R.id.start_voice_chat).setOnClickListener(v -> {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
        });
    }

    private final ActivityResultLauncher<String> requestPermissionLauncher = registerForActivityResult(
        new ActivityResultContracts.RequestPermission(), new ActivityResultCallback<Boolean>() {
            @Override
            public void onActivityResult(Boolean isGranted) {
                if (isGranted) {
                    registerAIAgent();
                }
            }
        });

    private void registerAIAgent() {
        String agentId = "zego_ai_agent";
        AgentConfig agentConfig = new AgentConfig();
        agentConfig.name = "小智";
        agentConfig.llm = new LLM();
        agentConfig.llm.url = ZegoAIAgentConfig.llmUrl;
        agentConfig.llm.apiKey = ZegoAIAgentConfig.llmApiKey;
        agentConfig.llm.model = ZegoAIAgentConfig.llmModel;
        agentConfig.llm.systemPrompt = "你是小智,是一个问答机器人";

        agentConfig.tts = new TTS();
        agentConfig.tts.vendor = ZegoAIAgentConfig.ttsVendor;
        agentConfig.tts.params = new Params();
        agentConfig.tts.params.app = new App();
        agentConfig.tts.params.app.appid = ZegoAIAgentConfig.ttsAppId;
        agentConfig.tts.params.app.token = ZegoAIAgentConfig.ttsToken;
        agentConfig.tts.params.app.cluster = ZegoAIAgentConfig.ttsCluster;
        agentConfig.tts.params.speedRatio = 1;
        agentConfig.tts.params.volumeRatio = 1;
        agentConfig.tts.params.pitchRatio = 1;
        agentConfig.tts.params.audio = new Audio();
        agentConfig.tts.params.audio.rate = 24000;
        agentConfig.tts.params.audio.voiceType = ZegoAIAgentConfig.ttsVoice;
        zegoAIAgentAPI.registerAgent(ZegoAIAgentConfig.zegoAppId, ZegoAIAgentConfig.zegoServerSecret, agentId,
            agentConfig, new RegisterAgentCallback() {
                @Override
                public void onResult(int errorCode, String message, String requestId) {
                    // 410001008 重复创建
                    if (errorCode == 0 || errorCode == 410001008) {
                        Intent intent = new Intent(MainActivity.this, VoiceChatActivity.class);
                        intent.putExtra("agentId", agentId);
                        intent.putExtra("agentConfig", mGson.toJson(agentConfig));
                        intent.putExtra("userProfile", mGson.toJson(new UserProfile(userId, userName)));
                        intent.putExtra("authData", mGson.toJson(
                            new AuthData(ZegoAIAgentConfig.zegoAppId, ZegoAIAgentConfig.zegoAppSign,
                                ZegoAIAgentConfig.zegoServerSecret)));
                        startActivity(intent);
                    }
                }
            });
    }
}