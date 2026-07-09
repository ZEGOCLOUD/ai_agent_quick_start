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
import com.squareup.picasso.Picasso;
import im.zego.aiagent.express.quickstart.Constant;
import im.zego.aiagent.express.quickstart.R;
import im.zego.aiagent.express.quickstart.util.ExpressHelper;
import im.zego.aiagent.express.quickstart.util.HttpHelper;
import im.zego.aiagent.express.quickstart.util.QuickStartApi;
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
import org.json.JSONException;
import org.json.JSONObject;

/**
 * 数字人通话：与数字人进行双向音视频对话（用户推流 + 数字人形象渲染）。
 * <p>
 * 接口调用顺序：
 * <pre>
 * 1. initExpressSDK()              初始化 Express 引擎
 * 2. requestZegoToken()            GET  /api/zego-token          获取登录 token
 * 3. ExpressHelper.loginRoom()     登录 Express 房间（advancedConfig 含 sideinfo）
 * 4. ├─ openExpressCustomRender()  房间登录成功后：开启自定义渲染（须在推/拉流前）
 *    ├─ startPublishingStream()    推本地流
 *    └─ startDigitalHumanChat()    POST /api/start-digital-human 启动数字人
 * 5. (拉数字人流 + initDigitalMobileSDK)   收到 start 响应后渲染数字人
 *
 * 结束：
 * 6. stopDigitalHumanChat()        POST /api/stop               停止数字人
 * 7. destroyExpressSDK()           销毁 Express 引擎
 * </pre>
 * 详见 README.md「核心流程」。
 */
public class DigitalHumanActivity extends AppCompatActivity {

    public static final String TAG = "DigitalHumanActivity";
    private ZegoDigitalView digitalView;
    private View loadingView;
    private ImageView digitalPic;
    private IZegoDigitalMobile digitalMobileSDK;
    private String agent_user_id; //agent推流id，数字人推流id
    private String agent_stream_id; //agent推流id，数字人推流id
    private String agent_name; //agent推流id，数字人推流id
    private String agent_instance_id;

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
        setContentView(R.layout.activity_digital_human);
        initViews();
        // 申请麦克风权限，授权后在回调中 init()
        requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
    }

    /**
     * 初始化控件：数字人视图、占位图、挂断按钮
     */
    private void initViews() {
        digitalView = findViewById(R.id.digital_view);
        loadingView = findViewById(R.id.loading_view);
        digitalPic = findViewById(R.id.digital_pic);
        Picasso.get().load(Uri.parse(Constant.digital_human_image_URL)).into(digitalPic);
        findViewById(R.id.end_call).setOnClickListener(v -> finish());
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
                                    openExpressCustomRender();  // 开启自定义渲染，需在 startPublishingStream/startPlayingStream 前
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
        });
    }

    /**
     * 通知业务后台开启数字人通话
     */
    private void startDigitalHumanChat() {
        Log.i(TAG, "startDigitalHumanChat");
        QuickStartApi.startDigitalHuman(Constant.digital_human_id, Constant.config_id,
            Constant.user_id, Constant.room_id, Constant.user_stream_id,
            new HttpHelper.HttpCallback() {
            @Override
            public void onResponse(String responseBody) {
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
                            () -> Toast.makeText(DigitalHumanActivity.this, message, Toast.LENGTH_LONG).show());
                        final var digitalHumanConfig = (String) json.get("digital_human_config");
                        initDigitalMobileSDK(digitalHumanConfig);
                    } else {
                        ZegoExpressEngine.getEngine().logoutRoom();
                        showError("startDigitalHumanChat", "start failed: " + errorCode);
                    }
                } catch (JSONException e) {
                    showError("startDigitalHumanChat", "parse json failed: " + e.getMessage());
                }
            }

            @Override
            public void onFailure(String errorMsg) {
                showError("startDigitalHumanChat", errorMsg);
            }
        });
    }

    /**
     * 通知业务后台停止数字人通话
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

            digitalMobileSDK = ZegoDigitalHuman.create(DigitalHumanActivity.this);
            digitalMobileSDK.start(digitalHumanConfig, new IZegoDigitalMobile.ZegoDigitalMobileListener() {
                @Override
                public void onDigitalMobileStartSuccess() {
                    Log.i(TAG, "onDigitalMobileStartSuccess");
                }

                @Override
                public void onError(int i, String s) {
                    runOnUiThread(() -> {
                        if (DigitalHumanActivity.this.isDestroyed()) {
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
            Toast.makeText(DigitalHumanActivity.this, errorMsg, Toast.LENGTH_LONG).show();
            finish();
        });
    }
}
