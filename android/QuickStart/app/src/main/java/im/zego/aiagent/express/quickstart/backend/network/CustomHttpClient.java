package im.zego.aiagent.express.quickstart.backend.network;

import androidx.annotation.NonNull;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Headers;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;
import okhttp3.logging.HttpLoggingInterceptor.Level;

/**
 * 通用的 http 请求,外部依赖模块也可以直接调用
 */
public class CustomHttpClient {

    // http 发送失败
    public final int ERROR_HTTP_REQUEST = -1;

    private OkHttpClient okHttpClient = new OkHttpClient.Builder().cookieJar(new CookieManager())
        .connectTimeout(30, TimeUnit.SECONDS).writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY)).build();

    public void asyncPostRequest(String url, Headers headers, RequestBody requestBody, OKHttpCallback callback) {
        Request request = new Request.Builder().url(url).headers(headers).post(requestBody).build();

        okHttpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                // 代表 http 失败，多半是网络原因
                if (callback != null) {
                    callback.onResult(ERROR_HTTP_REQUEST, e.getMessage(), null);
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                String bodyString = response.body() != null ? response.body().string() : null;

                if (response.isSuccessful()) {
                    if (callback != null) {
                        callback.onResult(0, "Success", bodyString);
                    }
                } else {
                    if (callback != null) {
                        callback.onResult(response.code(), bodyString != null ? bodyString : response.message(), null);
                    }
                }
            }
        });
    }

    public void asyncGetRequest(String url, Headers headers, OKHttpCallback callback) {
        Request request = new Request.Builder().url(url).headers(headers).get().build();
        okHttpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {

                if (callback != null) {
                    callback.onResult(ERROR_HTTP_REQUEST, e.getMessage(), null);
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                String bodyString = response.body() != null ? response.body().string() : null;

                if (response.isSuccessful()) {
                    if (callback != null) {
                        callback.onResult(0, "Success", bodyString);
                    }
                } else {
                    if (callback != null) {
                        callback.onResult(response.code(), bodyString != null ? bodyString : response.message(), null);
                    }
                }
            }
        });
    }

    public interface OKHttpCallback {

        void onResult(int errorCode, String message, String responseBody);
    }
}
