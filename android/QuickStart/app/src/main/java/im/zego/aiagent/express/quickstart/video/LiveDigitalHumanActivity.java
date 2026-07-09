package im.zego.aiagent.express.quickstart.video;

import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.gson.JsonObject;
import com.squareup.picasso.Picasso;
import im.zego.aiagent.express.quickstart.Constant;
import im.zego.aiagent.express.quickstart.R;
import im.zego.digitalmobile.IZegoDigitalMobile;
import im.zego.digitalmobile.ZegoDigitalHuman;
import im.zego.digitalmobile.ZegoDigitalView;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoCustomVideoRenderHandler;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoAECMode;
import im.zego.zegoexpress.constants.ZegoANSMode;
import im.zego.zegoexpress.constants.ZegoAudioDeviceMode;
import im.zego.zegoexpress.constants.ZegoScenario;
import im.zego.zegoexpress.constants.ZegoVideoBufferType;
import im.zego.zegoexpress.constants.ZegoVideoFrameFormatSeries;
import im.zego.zegoexpress.entity.ZegoCustomVideoRenderConfig;
import im.zego.zegoexpress.entity.ZegoEngineConfig;
import im.zego.zegoexpress.entity.ZegoEngineProfile;
import im.zego.zegoexpress.entity.ZegoRoomConfig;
import im.zego.zegoexpress.entity.ZegoUser;
import im.zego.zegoexpress.entity.ZegoVideoFrameParam;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.HashMap;
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

/**
 * 播报数字人：单向观看场景。
 * <p>
 * 与 {@link VideoChatActivity} 的差异： - 不推流、不申请麦克风权限，onCreate 直接初始化。 - 创建实例走 /api/start-live-digital-human，请求体仅需
 * digital_human_id / config_id / room_id。 - 新增 sendTTS：调用 /api/send-agent-instance-tts 让数字人主动播报文本。
 */
public class LiveDigitalHumanActivity extends AppCompatActivity {

    public static final String TAG = "LiveDigitalHuman";
    private ZegoDigitalView digitalView;
    private View loadingView;
    private ImageView digitalPic;
    private EditText ttsInput;
    private Button ttsSend;
    private IZegoDigitalMobile digitalMobileSDK;
    private String agent_user_id; // 数字人在 RTC 房间内的用户 ID
    private String agent_stream_id; // 数字人推流 id
    private String agent_name; // 数字人名称
    private String agent_instance_id; // 用于 sendTTS / stop

    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY)).build();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_live_digital_human);
        digitalView = findViewById(R.id.digital_view);
        loadingView = findViewById(R.id.loading_view);
        digitalPic = findViewById(R.id.digital_pic);
        ttsInput = findViewById(R.id.tts_input);
        ttsSend = findViewById(R.id.tts_send);
        Picasso.get().load(Uri.parse(Constant.digital_human_image_URL)).into(digitalPic);
        findViewById(R.id.end_call).setOnClickListener(v -> finish());
        ttsSend.setOnClickListener(v -> {
            String text = ttsInput.getText().toString().trim();
            if (TextUtils.isEmpty(text)) {
                Toast.makeText(this, "请输入要播报的文本", Toast.LENGTH_SHORT).show();
                return;
            }
            sendTTS(text);
            ttsInput.setText("");
        });
        // 播报场景为单向观看，无需麦克风权限，直接初始化
        init();
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
        if (!checkBaseUrlValid()) {
            return;
        }
        loadingView.setVisibility(View.VISIBLE);
        initExpressSDK();
        requestZegoToken();
    }

    /**
     * 校验 BASE_URL 格式，避免 OkHttp 解析非法 URL 时抛 IllegalArgumentException 导致崩溃
     */
    private boolean checkBaseUrlValid() {
        String url = Constant.BASE_URL;
        if (TextUtils.isEmpty(url) || (!url.startsWith("http://") && !url.startsWith("https://"))) {
            showError("Config",
                "请先在 Constant.java 中配置正确的 BASE_URL（需以 http:// 或 https:// 开头），当前值：" + url);
            return false;
        }
        return true;
    }

    /**
     * 初始化 express SDK
     */
    private void initExpressSDK() {
        Log.i(TAG, "initExpressSDK");
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = Constant.appId;
        zegoEngineProfile.scenario = ZegoScenario.HIGH_QUALITY_CHATROOM;
        zegoEngineProfile.application = getApplication();
        ZegoExpressEngine.createEngine(zegoEngineProfile, null);
    }

    /**
     * 销毁 express SDK
     */
    private void destroyExpressSDK() {
        Log.i(TAG, "destroyExpressSDK");
        if (ZegoExpressEngine.getEngine() != null) {
            ZegoExpressEngine.getEngine().logoutRoom();
            ZegoExpressEngine.getEngine().setEventHandler(null);
            ZegoExpressEngine.destroyEngine(null);
        }
    }


    /**
     * 向业务后台请求 token，用于 express 登录
     */
    private void requestZegoToken() {
        Log.i(TAG, "requestZegoToken");
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/zego-token?userId=" + Constant.user_id)
            .get().build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                showError("requestZegoToken", "http failed: " + e.getMessage());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    System.out.println(responseBody);
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        String token = (String) json.get("token");
                        if (!TextUtils.isEmpty(token)) {
                            loginRoom(Constant.user_id, Constant.user_id, token, (errorCode, extendedData) -> {
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
                        throw new RuntimeException(e);
                    }
                } else {
                    showError("requestZegoToken", "get token failed: " + response.code());
                }
            }
        });
    }

    /**
     * 登录 express 房间
     */
    private void loginRoom(String userId, String userName, String token, IZegoRoomLoginCallback callback) {
        Log.i(TAG, "loginRoom");
        ZegoEngineConfig config = new ZegoEngineConfig();
        HashMap<String, String> advanceConfig = new HashMap<String, String>();
        advanceConfig.put("set_audio_volume_ducking_mode", "1");
        advanceConfig.put("enable_rnd_volume_adaptive", "true");
        advanceConfig.put("sideinfo_callback_version", "3");
        advanceConfig.put("sideinfo_bound_to_video_decoder", "true");
        config.advancedConfig = advanceConfig;
        ZegoExpressEngine.setEngineConfig(config);
        ZegoExpressEngine.getEngine().setRoomScenario(ZegoScenario.HIGH_QUALITY_CHATROOM);
        ZegoExpressEngine.getEngine().setAudioDeviceMode(ZegoAudioDeviceMode.GENERAL);
        ZegoExpressEngine.getEngine().enableAEC(true);
        ZegoExpressEngine.getEngine().setAECMode(ZegoAECMode.AI_BALANCED);
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
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
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
        });
    }

    /**
     * 通知业务后台开启播报数字人
     */
    private void startLiveDigitalHumanChat() {
        Log.i(TAG, "startLiveDigitalHumanChat");
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("digital_human_id", Constant.digital_human_id);
        jsonObject.addProperty("config_id", Constant.config_id);
        jsonObject.addProperty("room_id", Constant.room_id);
        // 播报数字人不传 user_id / user_stream_id

        RequestBody body = RequestBody.create(jsonObject.toString(),
            MediaType.parse("application/json; charset=utf-8"));
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/start-live-digital-human").post(body)
            .build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                showError("startLiveDigitalHumanChat", "http failed: " + e.getMessage());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        if (json.has("agent_name")) {
                            agent_name = (String) json.get("agent_name");
                        }
                        agent_instance_id = (String) json.get("agent_instance_id");
                        agent_user_id = (String) json.get("agent_user_id");
                        agent_stream_id = (String) json.get("agent_stream_id");
                        if (errorCode == 0) {
                            ZegoExpressEngine.getEngine().setPlayStreamBufferIntervalRange(agent_stream_id, 100, 2000);
                            ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                            runOnUiThread(
                                () -> Toast.makeText(LiveDigitalHumanActivity.this, message, Toast.LENGTH_LONG).show());
                            final String digitalHumanConfig = (String) json.get("digital_human_config");
                            initDigitalMobileSDK(digitalHumanConfig);
                        } else {
                            ZegoExpressEngine.getEngine().logoutRoom();
                            showError("startLiveDigitalHumanChat", "start failed: " + errorCode);
                        }
                    } catch (JSONException e) {
                        showError("startLiveDigitalHumanChat", "parse json failed: " + e.getMessage());
                    }
                } else {
                    showError("startLiveDigitalHumanChat", "http failed: " + response.code());
                }
            }
        });
    }

    /**
     * 主动让数字人播报文本（调用 /api/send-agent-instance-tts）
     */
    private void sendTTS(String text) {
        Log.i(TAG, "sendTTS: " + text);
        if (TextUtils.isEmpty(agent_instance_id)) {
            Toast.makeText(this, "数字人尚未就绪，请稍后再试", Toast.LENGTH_SHORT).show();
            return;
        }
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("agent_instance_id", agent_instance_id);
        jsonObject.addProperty("text", text);
        RequestBody body = RequestBody.create(jsonObject.toString(),
            MediaType.parse("application/json; charset=utf-8"));
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/send-agent-instance-tts").post(body)
            .build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                showError("sendTTS", "http failed: " + e.getMessage());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int code = (int) json.get("code");
                        String message = (String) json.get("message");
                        if (code == 0) {
                            runOnUiThread(
                                () -> Toast.makeText(LiveDigitalHumanActivity.this, "已发送播报", Toast.LENGTH_SHORT)
                                    .show());
                        } else {
                            showError("sendTTS", message);
                        }
                    } catch (JSONException e) {
                        showError("sendTTS", "parse json failed: " + e.getMessage());
                    }
                } else {
                    showError("sendTTS", "http failed: " + response.code());
                }
            }
        });
    }

    /**
     * 通知业务后台停止播报数字人
     */
    private void stopDigitalHumanChat() {
        Log.i(TAG, "stopDigitalHumanChat");
        // onDestroy 也会走到这里，此时 BASE_URL 可能尚未配置，跳过停止请求避免崩溃
        if (!checkBaseUrlValid()) {
            return;
        }
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("agent_instance_id", agent_instance_id);
        RequestBody body = RequestBody.create(jsonObject.toString(),
            MediaType.parse("application/json; charset=utf-8"));

        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/stop").post(body).build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
            }
        });
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
}
