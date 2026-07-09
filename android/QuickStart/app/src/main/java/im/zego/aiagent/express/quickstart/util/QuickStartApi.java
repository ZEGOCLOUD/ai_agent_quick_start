package im.zego.aiagent.express.quickstart.util;

import com.google.gson.JsonObject;

/**
 * 业务后台接口封装：集中定义所有 HTTP 接口路径与请求方法。
 * <p>
 * 路径常量统一在此声明，避免在各 Activity 中散落魔法字符串；
 * 每个接口对应一个语义化方法，内部委托 {@link HttpHelper} 发请求。
 * <p>
 * 调用方只需关注请求体构造与响应解析，URL 拼接、超时、日志等由 {@link HttpHelper} 统一处理。
 */
public class QuickStartApi {

    // ======================== 接口路径 ========================

    /** 获取登录 Express 房间所需的 token */
    public static final String PATH_GET_TOKEN = "/api/zego-token";

    /** 语音通话：启动 AI Agent */
    public static final String PATH_START = "/api/start";

    /** 数字人通话：启动数字人 Agent */
    public static final String PATH_START_DIGITAL_HUMAN = "/api/start-digital-human";

    /** 播报数字人：启动播报数字人 Agent */
    public static final String PATH_START_LIVE_DIGITAL_HUMAN = "/api/start-live-digital-human";

    /** 播报数字人：主动让数字人播报文本（TTS） */
    public static final String PATH_SEND_AGENT_INSTANCE_TTS = "/api/send-agent-instance-tts";

    /** 停止 Agent 实例（语音 / 数字人 / 播报数字人通用） */
    public static final String PATH_STOP = "/api/stop";


    // ======================== 请求方法 ========================

    /**
     * 获取 Express 登录 token。
     *
     * @param userId   用户 ID
     * @param callback HTTP 回调，成功给响应体字符串
     */
    public static void getZegoToken(String userId, HttpHelper.HttpCallback callback) {
        HttpHelper.get(PATH_GET_TOKEN + "?userId=" + userId, callback);
    }

    /**
     * 启动语音通话 Agent（{@link #PATH_START}）。请求体由本方法内部组装。
     *
     * @param roomId        RTC 房间 ID
     * @param userId        用户 ID
     * @param userStreamId  用户推流 ID
     * @param callback      HTTP 回调
     */
    public static void start(String roomId, String userId, String userStreamId,
        HttpHelper.HttpCallback callback) {
        JsonObject body = new JsonObject();
        body.addProperty("room_id", roomId);
        body.addProperty("user_id", userId);
        body.addProperty("user_stream_id", userStreamId);
        HttpHelper.post(PATH_START, body, callback);
    }

    /**
     * 启动数字人 Agent（{@link #PATH_START_DIGITAL_HUMAN}）。请求体由本方法内部组装。
     *
     * @param digitalHumanId 数字人形象 ID
     * @param configId       数字人配置 ID
     * @param userId         用户 ID
     * @param roomId         RTC 房间 ID
     * @param userStreamId   用户推流 ID
     * @param callback       HTTP 回调
     */
    public static void startDigitalHuman(String digitalHumanId, String configId, String userId,
        String roomId, String userStreamId, HttpHelper.HttpCallback callback) {
        JsonObject body = new JsonObject();
        body.addProperty("digital_human_id", digitalHumanId);
        body.addProperty("config_id", configId);
        body.addProperty("user_id", userId);
        body.addProperty("room_id", roomId);
        body.addProperty("user_stream_id", userStreamId);
        HttpHelper.post(PATH_START_DIGITAL_HUMAN, body, callback);
    }

    /**
     * 启动播报数字人 Agent（{@link #PATH_START_LIVE_DIGITAL_HUMAN}）。请求体由本方法内部组装。
     * 单向观看，无需 userId / userStreamId。
     *
     * @param digitalHumanId 数字人形象 ID
     * @param configId       数字人配置 ID
     * @param roomId         RTC 房间 ID
     * @param callback       HTTP 回调
     */
    public static void startLiveDigitalHuman(String digitalHumanId, String configId, String roomId,
        HttpHelper.HttpCallback callback) {
        JsonObject body = new JsonObject();
        body.addProperty("digital_human_id", digitalHumanId);
        body.addProperty("config_id", configId);
        body.addProperty("room_id", roomId);
        HttpHelper.post(PATH_START_LIVE_DIGITAL_HUMAN, body, callback);
    }

    /**
     * 让播报数字人主动播报文本（{@link #PATH_SEND_AGENT_INSTANCE_TTS}）。请求体由本方法内部组装。
     *
     * @param agentInstanceId 由 start 接口返回的 Agent 实例 ID
     * @param text            需要合成并播报的文本
     * @param callback        HTTP 回调
     */
    public static void sendAgentInstanceTTS(String agentInstanceId, String text,
        HttpHelper.HttpCallback callback) {
        JsonObject body = new JsonObject();
        body.addProperty("agent_instance_id", agentInstanceId);
        body.addProperty("text", text);
        HttpHelper.post(PATH_SEND_AGENT_INSTANCE_TTS, body, callback);
    }

    /**
     * 停止 Agent 实例（{@link #PATH_STOP}），三个场景通用。
     *
     * @param agentInstanceId 由 start 接口返回的 Agent 实例 ID
     * @param callback        HTTP 回调，通常不关心结果可传 null
     */
    public static void stop(String agentInstanceId, HttpHelper.HttpCallback callback) {
        JsonObject body = new JsonObject();
        body.addProperty("agent_instance_id", agentInstanceId);
        HttpHelper.post(PATH_STOP, body, callback);
    }
}
