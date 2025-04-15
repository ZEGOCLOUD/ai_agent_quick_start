package im.zego.aiagent.express.quickstart.backend;

import com.google.gson.Gson;
import im.zego.aiagent.express.quickstart.backend.callback.CreateAgentInstanceCallback;
import im.zego.aiagent.express.quickstart.backend.callback.DeleteAgentInstanceCallback;
import im.zego.aiagent.express.quickstart.backend.callback.RegisterAgentCallback;
import im.zego.aiagent.express.quickstart.backend.data.AgentConfig;
import im.zego.aiagent.express.quickstart.backend.data.CreateAgentInstanceRsp;
import im.zego.aiagent.express.quickstart.backend.data.RtcInfo;
import im.zego.aiagent.express.quickstart.backend.network.JsonBuilder;
import im.zego.aiagent.express.quickstart.backend.network_wrapper.ZegoAIAgentHttpHelper;
import okhttp3.Headers;
import okhttp3.HttpUrl;
import okhttp3.MediaType;
import okhttp3.RequestBody;
import timber.log.Timber;

/**
 * demo 后台接口
 */
public class ZegoAIAgentAPI {

    private static final String TAG = "ZegoAIAgentKitAPI";

    private static final String BASE_URL = "https://aigc-chat-api.zegotech.cn";

    private static String base_url = BASE_URL;

    private final ZegoAIAgentHttpHelper httpHelper;
    private Gson gson;

    public ZegoAIAgentAPI(Gson gson, ZegoAIAgentHttpHelper httpHelper) {
        this.httpHelper = httpHelper;
        this.gson = gson;
    }

    public void registerAgent(long appId, String serverSecret, String agentId, AgentConfig agentConfig,
        RegisterAgentCallback callback) {

        Headers headers = new Headers.Builder().build();

        String urlString = ZegoAIAgentHttpHelper.getRequestUrl(appId, serverSecret, base_url, "RegisterAgent");
        HttpUrl url = HttpUrl.parse(urlString).newBuilder().build();

        String jsonBody = new JsonBuilder(gson).addPrimitive("AgentId", agentId).addObject("AgentConfig", agentConfig)
            .build();

        Timber.d(" registerAgent() called with: jsonBody = [" + jsonBody + "]");

        MediaType JSON = MediaType.parse("application/json; charset=utf-8");
        RequestBody requestBody = RequestBody.create(jsonBody, JSON);

        httpHelper.asyncPostRequest(url.toString(), headers, requestBody, null,
            (errorCode, message, requestId, rsp) -> {
                Timber.d(
                    " registerAgent() onResult() called with: errorCode = [" + errorCode + "], message = [" + message
                        + "], requestId = [" + requestId + "]");
                if (callback != null) {
                    callback.onResult(errorCode, message, requestId);
                }
            });
    }

    public void createAgentInstance(long appId, String serverSecret, String agentId, String userId, RtcInfo rtcInfo,
        CreateAgentInstanceCallback callback) {

        Headers headers = new Headers.Builder().build();

        String urlString = ZegoAIAgentHttpHelper.getRequestUrl(appId, serverSecret, base_url, "CreateAgentInstance");
        HttpUrl url = HttpUrl.parse(urlString).newBuilder().build();

        String jsonBody = new JsonBuilder(gson).addPrimitive("AgentId", agentId).addPrimitive("UserId", userId)
            .addObject("RtcInfo", rtcInfo).build();

        Timber.d(" registerAgent() called with: jsonBody = [" + jsonBody + "]");

        MediaType JSON = MediaType.parse("application/json; charset=utf-8");
        RequestBody requestBody = RequestBody.create(jsonBody, JSON);

        httpHelper.asyncPostRequest(url.toString(), headers, requestBody, CreateAgentInstanceRsp.class,
            (errorCode, message, requestId, createAgentInstanceRsp) -> {
                Timber.d(" createAgentInstance() onResult() called with: errorCode = [" + errorCode + "], message = ["
                    + message + "], requestId = [" + requestId + "]");
                if (callback != null) {
                    callback.onResult(errorCode, message, requestId, createAgentInstanceRsp);
                }
            });
    }

    public void deleteAgentInstance(long appId, String serverSecret, String agentInstanceId,
        DeleteAgentInstanceCallback callback) {
        Headers headers = new Headers.Builder().build();

        String urlString = ZegoAIAgentHttpHelper.getRequestUrl(appId, serverSecret, base_url, "DeleteAgentInstance");
        HttpUrl url = HttpUrl.parse(urlString).newBuilder().build();

        String body = new JsonBuilder().addPrimitive("agentInstanceId", agentInstanceId).build();

        Timber.d("Kit deleteAgentInstance() called with: jsonBody = [" + body + "]");

        MediaType JSON = MediaType.parse("application/json; charset=utf-8");
        RequestBody requestBody = RequestBody.create(body, JSON);

        httpHelper.asyncPostRequest(url.toString(), headers, requestBody, null,
            (errorCode, message, requestId, rsp) -> {
                Timber.d(
                    "Kit deleteAgentInstance() onResult() called with: errorCode = [" + errorCode + "], message = ["
                        + message + "], requestId = [" + requestId + "]");
                if (callback != null) {
                    callback.onResult(errorCode, message, requestId);
                }
            });
    }
}
