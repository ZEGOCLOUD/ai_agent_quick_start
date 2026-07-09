package im.zego.aiagent.express.quickstart.util;

import android.text.TextUtils;
import androidx.annotation.NonNull;
import com.google.gson.JsonObject;
import im.zego.aiagent.express.quickstart.Constant;
import java.io.IOException;
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

/**
 * 轻量 HTTP 封装：统一管理 {@link OkHttpClient} 与 GET/POST 请求。
 * <p>
 * 只负责发请求、回传响应体字符串，不做任何 UI 操作与业务字段解析，
 * 由调用方自行解析 JSON 并决定如何处理成功/失败。
 * <p>
 * URL 会在内部拼接 {@code Constant.BASE_URL + path}，调用方只需传入接口路径，
 * 例如 {@code "/api/zego-token?userId=xxx"}。
 */
public class HttpHelper {

    private static final String TAG = "HttpHelper";
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

    /**
     * 全局单例 client：30s 超时 + BODY 级日志。
     * 三个 Activity 共用同一个，避免各自重复创建。
     */
    private static final OkHttpClient CLIENT = new OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY))
        .build();

    /**
     * 校验 BASE_URL 是否为合法的 http/https 地址。
     * 用于发请求前拦截非法（如尚未配置）的地址，避免 OkHttp 解析时抛
     * {@link IllegalArgumentException} 导致崩溃。
     *
     * @return true 表示可以安全发请求
     */
    public static boolean isBaseUrlValid() {
        String url = Constant.BASE_URL;
        return !TextUtils.isEmpty(url)
            && (url.startsWith("http://") || url.startsWith("https://"));
    }

    /**
     * 发起 GET 请求。
     *
     * @param path     接口路径（不含 host），如 {@code "/api/zego-token?userId=xxx"}
     * @param callback 成功回调 {@code onResponse} 给原始响应体字符串；失败回调 {@code onFailure} 给错误信息。
     *                 回调在 OkHttp 的工作线程触发，如需更新 UI 调用方需自行切回主线程。
     */
    public static void get(String path, HttpCallback callback) {
        Request request = new Request.Builder().url(Constant.BASE_URL + path).get().build();
        enqueue(request, callback);
    }

    /**
     * 发起 POST JSON 请求。
     *
     * @param path     接口路径（不含 host），如 {@code "/api/start"}
     * @param body     JSON 请求体
     * @param callback 同 {@link #get(String, HttpCallback)}
     */
    public static void post(String path, JsonObject body, HttpCallback callback) {
        RequestBody requestBody = RequestBody.create(body.toString(), JSON);
        Request request = new Request.Builder().url(Constant.BASE_URL + path).post(requestBody).build();
        enqueue(request, callback);
    }

    /**
     * 统一执行请求并分发回调：网络异常、HTTP 非 2xx、读取响应体失败都归入 onFailure，
     * 仅在拿到 2xx 响应时回调 onResponse，简化调用方逻辑。
     */
    private static void enqueue(Request request, HttpCallback callback) {
        CLIENT.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                if (callback != null) {
                    callback.onFailure("http failed: " + e.getMessage());
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (callback == null) {
                    return;
                }
                if (!response.isSuccessful()) {
                    callback.onFailure("http failed: " + response.code());
                    return;
                }
                try {
                    callback.onResponse(response.body().string());
                } catch (IOException e) {
                    callback.onFailure("read response failed: " + e.getMessage());
                }
            }
        });
    }

    /**
     * 简化回调接口：成功给原始响应体字符串，失败给错误信息。
     * 线程：均在子线程触发，如需更新 UI 请调用方自行切回主线程。
     */
    public interface HttpCallback {
        /**
         * 收到 2xx 响应。
         *
         * @param responseBody 响应体字符串，通常为 JSON，由调用方自行解析。
         */
        void onResponse(String responseBody) throws IOException;

        /**
         * 请求失败（网络异常 / HTTP 非 2xx / 读取响应体失败）。
         *
         * @param errorMsg 已拼接好的错误描述
         */
        void onFailure(String errorMsg);
    }
}
