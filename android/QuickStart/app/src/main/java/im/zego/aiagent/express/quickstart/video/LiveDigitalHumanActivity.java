package im.zego.aiagent.express.quickstart.video;

import android.graphics.PorterDuff;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.squareup.picasso.Picasso;
import im.zego.aiagent.express.quickstart.Constant;
import im.zego.aiagent.express.quickstart.R;
import im.zego.aiagent.express.quickstart.util.ExpressHelper;
import im.zego.aiagent.express.quickstart.util.HttpHelper;
import im.zego.aiagent.express.quickstart.util.QuickStartApi;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser.AudioChatAgentStatusMessage;
import im.zego.aiagent.express.quickstart.voice.AudioChatMessageParser.AudioChatMessage;
import im.zego.digitalmobile.IZegoDigitalMobile;
import im.zego.digitalmobile.ZegoDigitalHuman;
import im.zego.digitalmobile.ZegoDigitalView;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoCustomVideoRenderHandler;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.constants.ZegoVideoBufferType;
import im.zego.zegoexpress.constants.ZegoVideoFrameFormatSeries;
import im.zego.zegoexpress.entity.ZegoCustomVideoRenderConfig;
import im.zego.zegoexpress.entity.ZegoVideoFrameParam;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * 播报数字人：单向观看场景（用户只看不推流）。
 * <p>
 * 与 {@link DigitalHumanActivity} 的差异：不推流、不申请麦克风权限、onCreate 直接初始化；
 * 启动接口为 /api/start-live-digital-human（请求体仅需 digital_human_id / config_id / room_id）；
 * 额外支持 sendTTS 主动播报。
 * <p>
 * 接口调用顺序：
 * <pre>
 * 1. initExpressSDK()                初始化 Express 引擎
 * 2. requestZegoToken()              GET  /api/zego-token          获取登录 token
 * 3. ExpressHelper.loginRoom()       登录 Express 房间（advancedConfig 含 sideinfo）
 * 4. ├─ openExpressCustomRender()    房间登录成功后：开启自定义渲染（须在拉流前）
 *    └─ startLiveDigitalHumanChat()  POST /api/start-live-digital-human 启动播报数字人
 * 5. (拉数字人流 + initDigitalMobileSDK)   收到 start 响应后渲染数字人
 *
 * 互动（可选）：
 *    sendTTS()                       POST /api/send-agent-instance-tts   主动播报文本
 *
 * 结束：
 * 6. stopDigitalHumanChat()          POST /api/stop               停止数字人
 * 7. destroyExpressSDK()             销毁 Express 引擎
 * </pre>
 * 详见 README.md「核心流程」。
 */
public class LiveDigitalHumanActivity extends AppCompatActivity {

    public static final String TAG = "LiveDigitalHuman";
    private ZegoDigitalView digitalView;
    private View loadingView;
    private ImageView digitalPic;
    private TextView agentStatusView;
    private EditText ttsInput;
    private Button ttsSend;
    /** 解析业务后台通过 Express 房间消息下发的 Agent 状态 */
    private AudioChatMessageParser audioChatMessageParser = new AudioChatMessageParser();
    private IZegoDigitalMobile digitalMobileSDK;
    private String agent_user_id; // 数字人在 RTC 房间内的用户 ID
    private String agent_stream_id; // 数字人推流 id
    private String agent_name; // 数字人名称
    private String agent_instance_id; // 用于 sendTTS / stop

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_live_digital_human);
        initViews();
        // 播报场景为单向观看，无需麦克风权限，直接初始化
        init();
    }

    /**
     * 初始化控件：数字人视图、占位图、挂断按钮、TTS 输入栏
     */
    private void initViews() {
        digitalView = findViewById(R.id.digital_view);
        loadingView = findViewById(R.id.loading_view);
        digitalPic = findViewById(R.id.digital_pic);
        agentStatusView = findViewById(R.id.agent_status);
        ttsInput = findViewById(R.id.tts_input);
        ttsSend = findViewById(R.id.tts_send);
        Picasso.get().load(Uri.parse(Constant.digital_human_image_URL)).into(digitalPic);

        // 注册 Agent 状态回调：解析到 cmd==6（Agent 状态变更）时刷新顶部状态条
        audioChatMessageParser.setAudioChatMessageListListener(
            new AudioChatMessageParser.AudioChatMessageListListener() {
                @Override
                public void onMessageListUpdated(List<AudioChatMessage> messagesList) {
                    // 播报场景只展示播放状态，字幕不处理
                }

                @Override
                public void onAudioChatStateUpdate(AudioChatAgentStatusMessage statusMessage) {
                    if (statusMessage != null && statusMessage.data != null) {
                        updateAgentStatus(statusMessage.data.status);
                    }
                }
            });
        findViewById(R.id.end_call).setOnClickListener(v -> finish());
        // 输入文本后发送，让数字人主动播报
        ttsSend.setOnClickListener(v -> {
            String text = ttsInput.getText().toString().trim();
            if (TextUtils.isEmpty(text)) {
                Toast.makeText(this, "Please enter text to speak", Toast.LENGTH_SHORT).show();
                return;
            }
            sendTTS(text);
            ttsInput.setText("");
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopDigitalHumanChat();
        destroyExpressSDK();
        destroyDigitalMobileSDK();
    }

    private void init() {
        Log.i(TAG, "init");
        loadingView.setVisibility(View.VISIBLE);
        initExpressSDK();
        requestZegoToken();
    }

    /**
     * 初始化 express SDK
     */
    private void initExpressSDK() {
        Log.i(TAG, "initExpressSDK");
        ExpressHelper.initEngine(getApplication());
    }

    /**
     * 销毁 express SDK
     */
    private void destroyExpressSDK() {
        Log.i(TAG, "destroyExpressSDK");
        ExpressHelper.destroyEngine();
    }


    /**
     * 向业务后台请求 token，用于 express 登录
     */
    private void requestZegoToken() {
        Log.i(TAG, "requestZegoToken");
        QuickStartApi.getZegoToken(Constant.user_id, new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                try {
                    JSONObject json = new JSONObject(responseBody);
                    String token = (String) json.get("token");
                    if (!TextUtils.isEmpty(token)) {
                        // 数字人场景的引擎高级配置（比语音场景多 sideinfo 相关项）
                        HashMap<String, String> advancedConfig = new HashMap<>();
                        advancedConfig.put("set_audio_volume_ducking_mode", "1");
                        advancedConfig.put("enable_rnd_volume_adaptive", "true");
                        advancedConfig.put("sideinfo_callback_version", "3");
                        advancedConfig.put("sideinfo_bound_to_video_decoder", "true");
                        ExpressHelper.loginRoom(Constant.user_id, Constant.user_id, token, advancedConfig,
                            (errorCode, extendedData) -> {
                                if (errorCode == 0) {
                                    openExpressCustomRender();  // 开启自定义渲染，需在 startPlayingStream 前
                                    startLiveDigitalHumanChat();
                                } else {
                                    showError("requestZegoToken", "join room failed");
                                }
                            });
                    } else {
                        showError("requestZegoToken", "get token failed");
                    }
                } catch (JSONException e) {
                    showError("requestZegoToken", "parse json failed: " + e.getMessage());
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                showError("requestZegoToken", errorMsg);
            }
        });
    }

    /**
     * 开启自定义渲染
     */
    private void openExpressCustomRender() {
        // 开启自定义渲染
        ZegoCustomVideoRenderConfig renderConfig = new ZegoCustomVideoRenderConfig();
        renderConfig.bufferType = ZegoVideoBufferType.RAW_DATA;
        renderConfig.frameFormatSeries = ZegoVideoFrameFormatSeries.RGB;
        renderConfig.enableEngineRender = false;
        ZegoExpressEngine.getEngine().enableCustomVideoRender(true, renderConfig);
        // 监听视频帧回调
        ZegoExpressEngine.getEngine().setCustomVideoRenderHandler(new IZegoCustomVideoRenderHandler() {
            @Override
            public void onRemoteVideoFrameRawData(ByteBuffer[] data, int[] dataLength, ZegoVideoFrameParam param,
                String streamID) {
                IZegoDigitalMobile.ZegoVideoFrameParam digitalParam = new IZegoDigitalMobile.ZegoVideoFrameParam();
                digitalParam.format = IZegoDigitalMobile.ZegoVideoFrameFormat.getZegoVideoFrameFormat(
                    param.format.value());
                digitalParam.height = param.height;
                digitalParam.width = param.width;
                digitalParam.rotation = param.rotation;
                for (int i = 0; i < 4; i++) {
                    digitalParam.strides[i] = param.strides[i];
                }
                // 把 Express 视频帧数据传给数字人 SDK
                synchronized (IZegoDigitalMobile.class) {
                    if (digitalMobileSDK != null) {
                        digitalMobileSDK.onRemoteVideoFrameRawData(data, dataLength, digitalParam, streamID);
                    }
                }
            }
        });

        // 监听 Express SEI 数据
        ZegoExpressEngine.getEngine().setEventHandler(new IZegoEventHandler() {
            @Override
            public void onPlayerSyncRecvSEI(String streamID, byte[] data) {
                // 把 Express SEI 数据传给数字人 SDK
                synchronized (IZegoDigitalMobile.class) {
                    if (digitalMobileSDK != null) {
                        digitalMobileSDK.onPlayerSyncRecvSEI(streamID, data);
                    }
                }
            }

            @Override
            public void onRecvExperimentalAPI(String content) {
                super.onRecvExperimentalAPI(content);
                Log.d(TAG, "onRecvExperimentalAPI() called with: content = [" + content + "]");
                try {
                    JSONObject json = new JSONObject(content);
                    // 仅处理房间频道消息，取出 msg_content 交给解析器（cmd==6 为 Agent 状态变更）
                    if (json.has("method") && json.getString("method")
                        .equals("liveroom.room.on_recive_room_channel_message")) {
                        JSONObject paramsObject = json.getJSONObject("params");
                        String msgContent = paramsObject.getString("msg_content");
                        audioChatMessageParser.parseAudioChatMessage(msgContent);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    /**
     * 通知业务后台开启播报数字人
     */
    private void startLiveDigitalHumanChat() {
        Log.i(TAG, "startLiveDigitalHumanChat");
        QuickStartApi.startLiveDigitalHuman(Constant.digital_human_id, Constant.config_id,
            Constant.room_id, new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                try {
                    JSONObject json = new JSONObject(responseBody);
                    int errorCode = json.optInt("code", -1);
                    String message = json.optString("message");
                    // 以下字段为业务元数据，后台可能不下发，缺失不应阻断主流程
                    agent_name = json.optString("agent_name");
                    agent_instance_id = json.optString("agent_instance_id");
                    agent_user_id = json.optString("agent_user_id");
                    agent_stream_id = json.optString("agent_stream_id");
                    if (errorCode == 0) {
                        ZegoExpressEngine.getEngine().setPlayStreamBufferIntervalRange(agent_stream_id, 100, 2000);
                        ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                        // agent 已启动成功，此时它处于 IDLE 静止状态。
                        // 后台仅在「状态发生变化」时才下发 cmd==6，进房间不发文本时收不到回调，
                        // 因此这里主动显示初始 Idle 状态，待真正收到状态回调后再更新。
                        updateAgentStatus(AudioChatAgentStatusMessage.Data.IDLE);
                        runOnUiThread(() -> Toast.makeText(LiveDigitalHumanActivity.this, message, Toast.LENGTH_LONG)
                            .show());
                        final String digitalHumanConfig = json.optString("digital_human_config");
                        initDigitalMobileSDK(digitalHumanConfig);
                    } else {
                        ZegoExpressEngine.getEngine().logoutRoom();
                        showError("startLiveDigitalHumanChat", "start failed: " + errorCode);
                    }
                } catch (JSONException e) {
                    showError("startLiveDigitalHumanChat", "parse json failed: " + e.getMessage());
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                showError("startLiveDigitalHumanChat", errorMsg);
            }
        });
    }

    /**
     * 主动让数字人播报文本（调用 /api/send-agent-instance-tts）
     */
    private void sendTTS(String text) {
        Log.i(TAG, "sendTTS: " + text);
        if (TextUtils.isEmpty(agent_instance_id)) {
            Toast.makeText(this, "Digital human is not ready, please try again later", Toast.LENGTH_SHORT).show();
            return;
        }
        QuickStartApi.sendAgentInstanceTTS(agent_instance_id, text, new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
                try {
                    JSONObject json = new JSONObject(responseBody);
                    int code = (int) json.get("code");
                    String message = (String) json.get("message");
                    if (code == 0) {
                        runOnUiThread(() -> Toast.makeText(LiveDigitalHumanActivity.this,
                            "Sent", Toast.LENGTH_SHORT).show());
                    } else {
                        showError("sendTTS", message);
                    }
                } catch (JSONException e) {
                    showError("sendTTS", "parse json failed: " + e.getMessage());
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                showError("sendTTS", errorMsg);
            }
        });
    }

    /**
     * 通知业务后台停止播报数字人
     */
    private void stopDigitalHumanChat() {
        Log.i(TAG, "stopDigitalHumanChat");
        // onDestroy 也会走到这里，此时 BASE_URL 可能尚未配置，跳过停止请求避免崩溃
        if (!HttpHelper.isBaseUrlValid()) {
            return;
        }
        // 停止请求的结果不关心，回调传 null
        QuickStartApi.stop(agent_instance_id, null);
    }

    /**
     * 初始化数字人 SDK
     */
    private void initDigitalMobileSDK(String digitalHumanConfig) {
        Log.i(TAG, "initDigitalMobileSDK: " + digitalHumanConfig);
        runOnUiThread(() -> {

            digitalMobileSDK = ZegoDigitalHuman.create(LiveDigitalHumanActivity.this);
            digitalMobileSDK.start(digitalHumanConfig, new IZegoDigitalMobile.ZegoDigitalMobileListener() {
                @Override
                public void onDigitalMobileStartSuccess() {
                    Log.i(TAG, "onDigitalMobileStartSuccess");
                }

                @Override
                public void onError(int i, String s) {
                    runOnUiThread(() -> {
                        if (LiveDigitalHumanActivity.this.isDestroyed()) {
                            return;
                        }
                        String errorMsg = "initDigitalMobileSDK" + ": " + s;
                        Log.e(TAG, errorMsg);
                        loadingView.setVisibility(View.GONE);
                    });
                }

                @Override
                public void onSurfaceFirstFrameDraw() {
                    runOnUiThread(() -> {
                        Log.i(TAG, "onSurfaceFirstFrameDraw");
                        loadingView.setVisibility(View.GONE);
                        digitalPic.setVisibility(View.GONE);
                    });
                }
            });
            digitalMobileSDK.attach(digitalView);
        });
    }

    /**
     * 销毁数字人 SDK
     */
    private void destroyDigitalMobileSDK() {
        Log.i(TAG, "destroyDigitalMobileSDK");
        synchronized (IZegoDigitalMobile.class) {
            if (digitalMobileSDK != null) {
                digitalMobileSDK.stop();
                digitalMobileSDK = null;
            }
        }
    }

    private void showError(String infoTag, String msg) {
        runOnUiThread(() -> {
            if (this.isDestroyed()) {
                return;
            }
            String errorMsg = infoTag + ": " + msg;
            Log.e(TAG, errorMsg);
            loadingView.setVisibility(View.GONE);
            Toast.makeText(LiveDigitalHumanActivity.this, errorMsg, Toast.LENGTH_LONG).show();
            finish();
        });
    }

    /**
     * 根据 onAudioChatStateUpdate 回调的 status 刷新顶部状态条。
     * 状态值见 {@link AudioChatAgentStatusMessage.Data}：
     * IDLE=0 / LISTENING=1 / THINKING=2 / SPEAKING=3
     */
    private void updateAgentStatus(int status) {
        runOnUiThread(() -> {
            if (isDestroyed()) {
                return;
            }
            String text;
            int dotColor;
            switch (status) {
                case AudioChatAgentStatusMessage.Data.LISTENING:
                    text = "Listening";
                    dotColor = 0xFFFFC107; // 黄
                    break;
                case AudioChatAgentStatusMessage.Data.THINKING:
                    text = "Thinking";
                    dotColor = 0xFF2196F3; // 蓝
                    break;
                case AudioChatAgentStatusMessage.Data.SPEAKING:
                    text = "Speaking";
                    dotColor = 0xFF4CAF50; // 绿
                    break;
                case AudioChatAgentStatusMessage.Data.IDLE:
                default:
                    text = "Idle";
                    dotColor = 0xFFFFFFFF; // 白
                    break;
            }
            agentStatusView.setText(text);
            // 给左侧状态点着色（drawableStart 引用的 shape_status_dot，默认白色）
            Drawable[] drawables = agentStatusView.getCompoundDrawables();
            if (drawables != null && drawables.length > 0 && drawables[0] != null) {
                drawables[0].setColorFilter(dotColor, PorterDuff.Mode.SRC_IN);
            }
            agentStatusView.setVisibility(View.VISIBLE);
        });
    }
}
