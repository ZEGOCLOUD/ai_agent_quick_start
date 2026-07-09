package im.zego.aiagent.express.quickstart.util;

import android.app.Application;
import android.util.Log;
import im.zego.aiagent.express.quickstart.Constant;
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

/**
 * ZegoExpressEngine 轻量封装：抽取三个 Activity 中完全一致的引擎初始化 / 销毁 / 音频配置逻辑。
 * <p>
 * 不涉及业务差异部分（loginRoom 的 advancedConfig、推流时机），那些仍由各 Activity 自行处理。
 */
public class ExpressHelper {

    /**
     * 初始化 Express 引擎：用 {@link Constant#appId} + {@link ZegoScenario#HIGH_QUALITY_CHATROOM}
     * 场景创建单例引擎。
     *
     * @param app 当前应用的 Application，引擎内部用于获取上下文
     */
    public static void initEngine(Application app) {
        ZegoEngineProfile zegoEngineProfile = new ZegoEngineProfile();
        zegoEngineProfile.appID = Constant.appId;
        zegoEngineProfile.scenario = ZegoScenario.HIGH_QUALITY_CHATROOM;
        zegoEngineProfile.application = app;
        ZegoExpressEngine.createEngine(zegoEngineProfile, null);
    }

    /**
     * 销毁 Express 引擎：登出房间、解绑事件回调、销毁引擎实例。
     * 引擎尚未创建（为空）时安全跳过。
     */
    public static void destroyEngine() {
        if (ZegoExpressEngine.getEngine() != null) {
            ZegoExpressEngine.getEngine().logoutRoom();
            ZegoExpressEngine.getEngine().setEventHandler(null);
            ZegoExpressEngine.destroyEngine(null);
        }
    }

    /**
     * 应用音频处理配置：房间场景、音频设备模式、AEC(AI_BALANCED)、AGC、ANS(MEDIUM)。
     * 在 {@code loginRoom} 前调用，三个 Activity 的该段配置完全一致。
     */
    public static void applyAudioConfig() {
        ZegoExpressEngine.getEngine().setRoomScenario(ZegoScenario.HIGH_QUALITY_CHATROOM);
        ZegoExpressEngine.getEngine().setAudioDeviceMode(ZegoAudioDeviceMode.GENERAL);
        ZegoExpressEngine.getEngine().enableAEC(true);
        ZegoExpressEngine.getEngine().setAECMode(ZegoAECMode.AI_BALANCED);
        ZegoExpressEngine.getEngine().enableAGC(true);
        ZegoExpressEngine.getEngine().enableANS(true);
        ZegoExpressEngine.getEngine().setANSMode(ZegoANSMode.MEDIUM);
    }

    private static final String TAG = "ExpressHelper";

    /**
     * 登录 Express 房间（三个场景的统一入口）。
     * <p>
     * 内部完成：设置引擎高级配置 → 应用音频配置 → 登录 {@link Constant#room_id} 房间 → 回调结果。
     * <p>
     * 登录成功后的后续动作（如推流、开启自定义渲染、启动 Agent）由调用方在 callback 中自行处理，
     * 因此三个场景的差异（是否推流、推什么流）都收敛到各自的回调里，本方法本身保持一致。
     *
     * @param userId          用户 ID
     * @param userName        用户名
     * @param token           登录 token（由业务后台 /api/zego-token 返回）
     * @param advancedConfig  引擎高级配置；不同场景不同：语音场景传 2 项，数字人场景额外含 sideinfo
     * @param callback        登录结果回调，errorCode==0 表示成功
     */
    public static void loginRoom(String userId, String userName, String token,
        HashMap<String, String> advancedConfig, IZegoRoomLoginCallback callback) {
        ZegoEngineConfig config = new ZegoEngineConfig();
        config.advancedConfig = advancedConfig;
        ZegoExpressEngine.setEngineConfig(config);

        applyAudioConfig();

        ZegoRoomConfig roomConfig = new ZegoRoomConfig();
        roomConfig.isUserStatusNotify = true;
        roomConfig.token = token;
        ZegoExpressEngine.getEngine()
            .loginRoom(Constant.room_id, new ZegoUser(userId, userName), roomConfig, (errorCode, extendedData) -> {
                Log.d(TAG, "loginRoom() errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
                }
            });
    }
}
