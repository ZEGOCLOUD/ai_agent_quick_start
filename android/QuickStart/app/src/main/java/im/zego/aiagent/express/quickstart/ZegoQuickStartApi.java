package im.zego.aiagent.express.quickstart;

import java.util.concurrent.TimeUnit;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.logging.HttpLoggingInterceptor;
import okhttp3.logging.HttpLoggingInterceptor.Level;

public class ZegoQuickStartApi {

    private static final String BASE_URL = "https://astounding-pothos-06fee6.netlify.app";
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BASIC)).build();


    public static void start(Callback callback) {
        RequestBody body = RequestBody.create("", JSON);
        Request request = new Request.Builder().url(BASE_URL + "/api/start").post(body).build();

        client.newCall(request).enqueue(callback);
    }

    public static void stop(Callback callback) {
        RequestBody body = RequestBody.create("", JSON);
        Request request = new Request.Builder().url(BASE_URL + "/api/stop").post(body).build();

        client.newCall(request).enqueue(callback);
    }

    public static void getZegoToken(String userId, Callback callback) {
        Request request = new Request.Builder().url(BASE_URL + "/api/zego-token?userId=" + userId).get().build();

        client.newCall(request).enqueue(callback);
    }
}