package im.zego.aiagent.express.quickstart.backend.network_wrapper;

import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import androidx.annotation.Nullable;
import com.google.gson.Gson;
import im.zego.aiagent.express.quickstart.backend.network.CustomHttpClient;
import java.security.MessageDigest;
import java.security.SecureRandom;
import okhttp3.Headers;
import okhttp3.HttpUrl;
import okhttp3.RequestBody;
import org.json.JSONObject;
import timber.log.Timber;

/**
 * 在通用的http 包基础上加了一些业务逻辑，主要是业务相关的数据结构的通用解析方法和回调
 */
public class ZegoAIAgentHttpHelper {


    private Handler mUIHandler = new Handler(Looper.getMainLooper());
    private CustomHttpClient okHttpClient;
    private Gson gson;

    public ZegoAIAgentHttpHelper(Gson gson, CustomHttpClient okHttpClient) {
        this.okHttpClient = okHttpClient;
        this.gson = gson;
    }

    public <T> void asyncPostRequest(String url, Headers headers, RequestBody requestBody, Class<T> classType,
        @Nullable BackendCallback<T> callBack) {

        okHttpClient.asyncPostRequest(url, headers, requestBody, (errorCode, message, responseBody) -> {
            if (errorCode == 0) {
                // http 请求是成功了，但是还要检查后台回复的数据咋样
                if (TextUtils.isEmpty(responseBody)) {
                    runCallBackOnUIThread(callBack, AIAgentError.ReadHttpBodyFailed,
                        "need " + classType + ",but body.string() error", "", null);
                } else {
                    onReceiveHttpResponse(classType, responseBody, callBack);
                }
            } else {
                // http 请求失败，要么是 http failed,要么是 server 回复的 http code failed
                runCallBackOnUIThread(callBack, errorCode, message, "", null);
            }
        });
    }

    public <T> void asyncGetRequest(String url, Headers headers, Class<T> classType,
        @Nullable BackendCallback<T> callBack) {

        okHttpClient.asyncGetRequest(url, headers, (errorCode, message, responseBody) -> {
            if (errorCode == 0) {
                // http 请求是成功了，但是还要检查后台回复的数据咋样
                if (TextUtils.isEmpty(responseBody)) {
                    runCallBackOnUIThread(callBack, AIAgentError.ReadHttpBodyFailed,
                        "need " + classType + ",but body.string() error", "", null);
                } else {
                    onReceiveHttpResponse(classType, responseBody, callBack);
                }
            } else {
                // http 请求失败，要么是 http failed,要么是 server 回复的 http code failed
                runCallBackOnUIThread(callBack, errorCode, message, "", null);
            }
        });
    }

    private <T> void onReceiveHttpResponse(Class<T> classType, String body, BackendCallback<T> callBack) {
        try {
            JSONObject jsonObject = new JSONObject(body);
            final int code = jsonObject.getInt("Code");
            final String message = jsonObject.getString("Message");
            String requestId = "";
            if (jsonObject.has("RequestId")) {
                requestId = jsonObject.getString("RequestId");
            }
            if (code == 0) {
                if (classType == null || classType == Object.class) {
                    runCallBackOnUIThread(callBack, code, message, requestId, null);
                } else {
                    if (jsonObject.has("Data")) {
                        JSONObject data = jsonObject.getJSONObject("Data");
                        T t = gson.fromJson(data.toString(), classType);
                        runCallBackOnUIThread(callBack, code, message, requestId, t);
                    } else {
                        Timber.d("onReceiveHttpResponse() called need " + classType + ",but parse 'Data' error,body:"
                            + body);
                        runCallBackOnUIThread(callBack, code, "need " + classType + ",but parse 'data' error",
                            requestId, null);
                    }
                }
            } else {
                // 反正失败了，data 肯定不正常，这里避免json 解析失败走到Exception 去了
                runCallBackOnUIThread(callBack, code, message, requestId, null);
            }
        } catch (Exception jsonException) {
            Timber.d("recv http response ,Parse response body Error,body:" + body);
            runCallBackOnUIThread(callBack, AIAgentError.ReadHttpBodyFailed,
                "Parse response body Error" + jsonException.getMessage(), "", null);
        }
    }

    public <T> void runCallBackOnUIThread(BackendCallback<T> callBack, int errorCode, String message, String requestId,
        T t) {
        if (callBack != null) {
            mUIHandler.post(
                () -> callBack.onResult(errorCode, AIAgentError.getErrorMessage(errorCode, message), requestId, t));
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuffer md5str = new StringBuffer();
        //把数组每一字节换成 16 进制连成 md5 字符串
        int digital;
        for (int i = 0; i < bytes.length; i++) {
            digital = bytes[i];
            if (digital < 0) {
                digital += 256;
            }
            if (digital < 16) {
                md5str.append("0");
            }
            md5str.append(Integer.toHexString(digital));
        }
        return md5str.toString();
    }

    // Signature=md5(AppId + SignatureNonce + ServerSecret + Timestamp)
    private static String GenerateSignature(long appId, String signatureNonce, String serverSecret, long timestamp) {
        String str = String.valueOf(appId) + signatureNonce + serverSecret + String.valueOf(timestamp);
        String signature = "";
        try {
            //创建一个提供信息摘要算法的对象，初始化为 md5 算法对象
            MessageDigest md = MessageDigest.getInstance("MD5");
            //计算后获得字节数组
            byte[] bytes = md.digest(str.getBytes("utf-8"));
            //把数组每一字节换成 16 进制连成 md5 字符串
            signature = bytesToHex(bytes);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return signature;
    }

    public static String getRequestUrl(long appId, String serverSecret, String baseUrl, String action) {
        //生成 16 进制随机字符串(16位)
        byte[] bytes = new byte[8];
        //使用SecureRandom获取高强度安全随机数生成器
        SecureRandom sr = new SecureRandom();
        sr.nextBytes(bytes);
        String signatureNonce = bytesToHex(bytes);
        long timestamp = System.currentTimeMillis() / 1000L;

        String signature = GenerateSignature(appId, signatureNonce, serverSecret, timestamp);

        HttpUrl.Builder urlBuilder = HttpUrl.parse(baseUrl).newBuilder().addQueryParameter("Action", action)
            .addQueryParameter("AppId", String.valueOf(appId)).addQueryParameter("SignatureNonce", signatureNonce)
            .addQueryParameter("Timestamp", String.valueOf(timestamp)).addQueryParameter("Signature", signature)
            .addQueryParameter("SignatureVersion", "2.0");

        // 获取完整的 URL 字符串
        String url = urlBuilder.build().toString();
        return url;
    }
}
