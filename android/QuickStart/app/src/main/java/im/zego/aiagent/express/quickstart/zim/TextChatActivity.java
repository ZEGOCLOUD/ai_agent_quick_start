package im.zego.aiagent.express.quickstart.zim;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.google.gson.JsonObject;
import im.zego.aiagent.express.quickstart.Constant;
import im.zego.aiagent.express.quickstart.MainActivity;
import im.zego.aiagent.express.quickstart.R;
import im.zego.zim.ZIM;
import im.zego.zim.callback.ZIMEventHandler;
import im.zego.zim.callback.ZIMLoggedInCallback;
import im.zego.zim.callback.ZIMMessageQueriedCallback;
import im.zego.zim.callback.ZIMMessageSentFullCallback;
import im.zego.zim.entity.ZIMAppConfig;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.entity.ZIMMediaMessage;
import im.zego.zim.entity.ZIMMessage;
import im.zego.zim.entity.ZIMMessageQueryConfig;
import im.zego.zim.entity.ZIMMessageReceivedInfo;
import im.zego.zim.entity.ZIMMessageSendConfig;
import im.zego.zim.entity.ZIMMultipleMessage;
import im.zego.zim.entity.ZIMTextMessage;
import im.zego.zim.entity.ZIMUserInfo;
import im.zego.zim.enums.ZIMConversationType;
import im.zego.zim.enums.ZIMErrorCode;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
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

public class TextChatActivity extends AppCompatActivity {

    private TextView loadingText;

    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(new HttpLoggingInterceptor().setLevel(Level.BODY)).build();
    private String agent_id;
    private String agent_name;
    private String robot_id;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_text_chat);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        TextChatListView chatListView = findViewById(R.id.chat_message_layout);

        loadingText = findViewById(R.id.loading_text);
        showLoading(true);
        loadingText.setText("Login...");

        ZIMAppConfig zimAppConfig = new ZIMAppConfig();
        zimAppConfig.appID = Constant.appId;
        ZIM.create(zimAppConfig, getApplication());

        ZIM.getInstance().setEventHandler(new ZIMEventHandler() {
            @Override
            public void onPeerMessageReceived(ZIM zim, ArrayList<ZIMMessage> messageList, ZIMMessageReceivedInfo info,
                String fromUserID) {
                // 只添加本会话的消息到本页面
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    List<ZIMMessage> collect = messageList.stream().filter(
                            zimMessage -> Objects.equals(robot_id, zimMessage.getConversationID()))
                        .collect(Collectors.toList());
                    chatListView.addMessageList(collect);
                } else {
                    ArrayList<ZIMMessage> collect = new ArrayList<ZIMMessage>();
                    for (ZIMMessage zimMessage : messageList) {
                        if (robot_id.equals(zimMessage.getConversationID())) {
                            collect.add(zimMessage);
                        }
                    }
                    chatListView.addMessageList(collect);
                }

            }
        });

        queryAgentInfo();

        EditText chatText = findViewById(R.id.chat_text);
        findViewById(R.id.send_text).setOnClickListener(v -> {
            String string = chatText.getText().toString();
            if (TextUtils.isEmpty(string)) {
                Toast.makeText(TextChatActivity.this, "Please input text", Toast.LENGTH_SHORT).show();
                return;
            }
            ZIMTextMessage zimMessage = new ZIMTextMessage();
            zimMessage.message = string;
            // 在单聊场景中，ZIMConversationType 设置为 PEER
            ZIM.getInstance().sendMessage(zimMessage, robot_id, ZIMConversationType.PEER,
                new ZIMMessageSendConfig(), new ZIMMessageSentFullCallback() {
                    @Override
                    public void onMessageAttached(ZIMMessage message) {
                        chatListView.addMessage(zimMessage);
                    }

                    @Override
                    public void onMessageSent(ZIMMessage message, ZIMError errorInfo) {

                    }

                    @Override
                    public void onMediaUploadingProgress(ZIMMediaMessage message, long currentFileSize,
                        long totalFileSize) {

                    }

                    @Override
                    public void onMultipleMediaUploadingProgress(ZIMMultipleMessage message, long currentFileSize,
                        long totalFileSize, int messageInfoIndex, long currentIndexFileSize, long totalIndexFileSize) {

                    }
                });
            chatText.setText("");
        });

        findViewById(R.id.voice_chat).setOnClickListener(v -> {
            Intent intent = new Intent(TextChatActivity.this, MainActivity.class);
            intent.putExtra("fromTextChat", true);
            intent.putExtra("agent_id", agent_id);
            intent.putExtra("agent_name", agent_name);
            startActivity(intent);
        });
    }

    private void showLoading(boolean show) {
        runOnUiThread(() -> findViewById(R.id.loading_layout).setVisibility(show ? View.VISIBLE : View.GONE));
    }

    // 拿到 token 之后登录 ZIM SDK
    private void requestZegoToken() {
        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/zego-token?userId=" + Constant.user_id)
            .get().build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                showLoading(false);
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();

                    Log.d(TAG, "requestZegoToken onResponse() called with: call = [" + call + "], response = [" + responseBody + "]");
                    try {
                        JSONObject json = new JSONObject(responseBody);
                        String token = (String) json.get("token");
                        long expireTime = (long) json.get("expire_time");
                        if (!TextUtils.isEmpty(token)) {
                            loginZIM(token);
                        }else {
                            showLoading(false);
                        }

                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    showLoading(false);
                }

            }
        });
    }

    // 登录成功之后查询历史消息
    public void loginZIM(String token) {
        Log.d(TAG, "loginZIM() called with: token = [" + token + "]");
        TextChatListView chatListView = findViewById(R.id.chat_message_layout);

        ZIMUserInfo robot = new ZIMUserInfo();
        robot.userID = robot_id;
        robot.userName = agent_name;

        ZIMUserInfo self = new ZIMUserInfo();
        self.userID = Constant.user_id;
        self.userName = Constant.userName;
        chatListView.setUserInfo(self, robot);

        ZIM.getInstance().login(self, token, new ZIMLoggedInCallback() {
            @Override
            public void onLoggedIn(ZIMError errorInfo) {
                if (errorInfo.code == ZIMErrorCode.SUCCESS) {
                    ZIMMessageQueryConfig queryConfig = new ZIMMessageQueryConfig();
                    queryConfig.count = 100;
                    queryConfig.reverse = true;

                    ZIM.getInstance()
                        .queryHistoryMessage(robot_id, ZIMConversationType.PEER, queryConfig,
                            new ZIMMessageQueriedCallback() {
                                @Override
                                public void onMessageQueried(String conversationID,
                                    ZIMConversationType conversationType, ArrayList<ZIMMessage> messageList,
                                    ZIMError errorInfo) {
                                    if (errorInfo.code == ZIMErrorCode.SUCCESS) {
                                        chatListView.addMessageList(messageList);
                                    } else {
                                        Toast.makeText(TextChatActivity.this, "查询历史消息失败", Toast.LENGTH_SHORT)
                                            .show();
                                    }
                                    showLoading(false);
                                }
                            });
                } else {
                    Toast.makeText(TextChatActivity.this, "登录失败", Toast.LENGTH_SHORT).show();
                    showLoading(false);
                }

            }
        });
    }

    private static final String TAG = "TextChatActivity";

    /**
     * 查询获取 robot_id，然后请求 zego token
     */
    private void queryAgentInfo() {
        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("user_id", Constant.user_id);
        RequestBody body = RequestBody.create(jsonObject.toString(), JSON);

        Request request = new Request.Builder().url(Constant.BASE_URL + "/api/getAgentInfo").post(body).build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
                showLoading(false);
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    Log.d(TAG, "queryAgentInfo onResponse() called with: call = [" + call + "], response = [" + responseBody + "]");

                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        if (errorCode == 0) {
                            agent_id = (String) json.get("agent_id");
                            agent_name = (String) json.get("agent_name");
                            robot_id = (String) json.get("robot_id");
                            runOnUiThread(() -> {
                                TextView aiName = findViewById(R.id.ai_name);
                                aiName.setText(agent_name);
                            });
                            requestZegoToken();
                        } else {
                            showLoading(false);
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                    showLoading(false);
                }

            }
        });
    }
}