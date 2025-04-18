package im.zego.aiagent.express.quickstart;

import java.util.concurrent.TimeUnit;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.logging.HttpLoggingInterceptor;
import okhttp3.logging.HttpLoggingInterceptor.Level;
import org.json.JSONObject;

public class ZegoQuickStartApi {

    private static final String BASE_URL = "https://cute-dango-81ced0.netlify.app";
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BASIC)).build();

    // 1. 注册AI Agent (异步)
    public static void registerAgent(String agentId, String agentName, Callback callback) {
        JSONObject json = new JSONObject();
        try {
            json.put("agent_id", agentId);
            json.put("agent_name", agentName);
        } catch (Exception e) {
            // 本地操作假设不会抛出异常，仅为健壮性添加
            System.err.println("Failed to create JSON for registerAgent: " + e.getMessage());
            return;
        }

        RequestBody body = RequestBody.create(json.toString(), JSON);
        Request request = new Request.Builder().url(BASE_URL + "/api/agent/register").post(body).build();

        client.newCall(request).enqueue(callback);
    }

    // 2. 创建AI Agent实例 (异步)
    public static void createAgentInstance(String agentId, String roomId, String userId, String userStreamId,
        String agentStreamId, String agentUserId, Callback callback) {
        JSONObject json = new JSONObject();
        try {
            json.put("agent_id", agentId);
            json.put("room_id", roomId);
            json.put("user_id", userId);
            json.put("user_stream_id", userStreamId);
            json.put("agent_stream_id", agentStreamId);
            json.put("agent_user_id", agentUserId);
        } catch (Exception e) {
            // 本地操作假设不会抛出异常，仅为健壮性添加
            System.err.println("Failed to create JSON for createAgentInstance: " + e.getMessage());
            return;
        }

        RequestBody body = RequestBody.create(json.toString(), JSON);
        Request request = new Request.Builder().url(BASE_URL + "/api/agent/create").post(body).build();

        client.newCall(request).enqueue(callback);
    }

    // 3. 删除AI Agent实例 (异步)
    public static void deleteAgentInstance(String agentInstanceId, Callback callback) {
        JSONObject json = new JSONObject();
        try {
            json.put("agent_instance_id", agentInstanceId);
        } catch (Exception e) {
            // 本地操作假设不会抛出异常，仅为健壮性添加
            System.err.println("Failed to create JSON for deleteAgentInstance: " + e.getMessage());
            return;
        }

        RequestBody body = RequestBody.create(json.toString(), JSON);
        Request request = new Request.Builder().url(BASE_URL + "/api/agent/delete").post(body).build();

        client.newCall(request).enqueue(callback);
    }

    // 4. 获取Token (异步)
    public static void getZegoToken(String userId, Callback callback) {
        Request request = new Request.Builder().url(BASE_URL + "/api/zegotoken?userId=" + userId).get().build();

        client.newCall(request).enqueue(callback);
    }
}