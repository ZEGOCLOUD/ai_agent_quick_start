package im.zego.aiagent.express.quickstart.video;

import android.Manifest;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
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

public class VideoChatActivity extends AppCompatActivity {

    public static final String TAG = "VideoChatActivity";
    private ZegoDigitalView previewView;
    private View loadingView;
    private ImageView digitalPic;
    private IZegoDigitalMobile digitalMobileSDK;
    private String agent_user_id; //agent推流id，数字人推流id
    private String agent_stream_id; //agent推流id，数字人推流id
    private String agent_name; //agent推流id，数字人推流id
    private String agent_instance_id;

    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY)).build();

    private final ActivityResultLauncher<String> requestPermissionLauncher = registerForActivityResult(
        new ActivityResultContracts.RequestPermission(), isGranted -> {
            if (isGranted) {
                init();
            } else {
                showError("Activity", "please enable permission");
            }
        });

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video);
        previewView = findViewById(R.id.preview_view);
        loadingView = findViewById(R.id.loading_view);
        digitalPic = findViewById(R.id.digital_pic);
        Picasso.get().load(Uri.parse(Constant.digital_human_image_URL)).into(digitalPic);
        findViewById(R.id.end_call).setOnClickListener(v -> {
            finish();
        });
        requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
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
                                    openExpressCustomRender();  // 开启自定义渲染，express 开启自定义渲染需要在 startPublishingStream/startPlayingStream 前
                                    ZegoExpressEngine.getEngine().startPublishingStream(Constant.user_stream_id);
                                    ZegoExpressEngine.getEngine().muteMicrophone(false);
                                    startDigitalHumanChat();
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
     * 通知业务后台开启数字人通话
     */
    private void startDigitalHumanChat() {
        Log.i(TAG, "startDigitalHumanChat");
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("digital_human_id", Constant.digital_human_id); // 替换为实际的 数字人形象ID
        jsonObject.addProperty("config_id", Constant.config_id); // 替换为实际的 callId
        jsonObject.addProperty("user_id", Constant.user_id);
        jsonObject.addProperty("room_id", Constant.room_id);
        jsonObject.addProperty("user_stream_id", Constant.user_stream_id);

        RequestBody body = RequestBody.create(jsonObject.toString(),
            MediaType.parse("application/json; charset=utf-8"));
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/start-digital-human").post(body).build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                showError("startDigitalHumanChat", "http failed: " + e.getMessage());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        agent_name = (String) json.get("agent_name");
                        agent_instance_id = (String) json.get("agent_instance_id");
                        agent_user_id = (String) json.get("agent_user_id");
                        agent_stream_id = (String) json.get("agent_stream_id");
                        if (errorCode == 0) {
                            ZegoExpressEngine.getEngine().setPlayStreamBufferIntervalRange(agent_stream_id, 100, 2000);
                            ZegoExpressEngine.getEngine().startPlayingStream(agent_stream_id);
                            runOnUiThread(
                                () -> Toast.makeText(VideoChatActivity.this, message, Toast.LENGTH_LONG).show());
                            final var digitalHumanConfig = (String) json.get("digital_human_config");
                            initDigitalMobileSDK(digitalHumanConfig);
                        } else {
                            ZegoExpressEngine.getEngine().logoutRoom();
                            showError("startDigitalHumanChat", "start failed: " + errorCode);
                        }
                    } catch (JSONException e) {
                        showError("startDigitalHumanChat", "parse json failed: " + e.getMessage());
                    }
                } else {
                    showError("startDigitalHumanChat", "http failed: " + response.code());
                }
            }
        });
    }

    /**
     * 通知业务后台停止数字人通话
     */
    private void stopDigitalHumanChat() {
        Log.i(TAG, "stopDigitalHumanChat");
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

            digitalMobileSDK = ZegoDigitalHuman.create(VideoChatActivity.this);
            digitalMobileSDK.start(digitalHumanConfig, new IZegoDigitalMobile.ZegoDigitalMobileListener() {
                @Override
                public void onDigitalMobileStartSuccess() {
                    Log.i(TAG, "onDigitalMobileStartSuccess");
                    digitalPic.setVisibility(View.GONE);
                }

                @Override
                public void onError(int i, String s) {
                    runOnUiThread(() -> {
                        if (VideoChatActivity.this.isDestroyed()) {
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
                    });
                }
            });
            digitalMobileSDK.attach(previewView);
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
            Toast.makeText(VideoChatActivity.this, errorMsg, Toast.LENGTH_LONG).show();
            finish();
        });
    }
}
