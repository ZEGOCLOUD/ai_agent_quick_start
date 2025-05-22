package im.zego.aiagent.express.quickstart.zim;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class TextChatActivity extends AppCompatActivity {

    private TextView loadingText;

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
        loadingText.setText("正在登录...");

        ZIMAppConfig zimAppConfig = new ZIMAppConfig();
        zimAppConfig.appID = Constant.appId;
        zimAppConfig.appSign = "cbf0692d6dd29f2ee4492fd8a0c488b90406d71f7e08ef696a1049e280ddda82";
        ZIM.create(zimAppConfig, getApplication());

        ZIMUserInfo robot = new ZIMUserInfo();
        robot.userID = Constant.agent_zim_robotid;
        robot.userName = Constant.agent_name;

        ZIMUserInfo self = new ZIMUserInfo();
        self.userID = Constant.user_id;
        self.userName = Constant.userName;
        chatListView.setUserInfo(self, robot);

        ZIM.getInstance().login(self, new ZIMLoggedInCallback() {
            @Override
            public void onLoggedIn(ZIMError errorInfo) {
                if (errorInfo.code == ZIMErrorCode.SUCCESS) {
                    ZIMMessageQueryConfig queryConfig = new ZIMMessageQueryConfig();
                    queryConfig.count = 100;
                    queryConfig.reverse = true;

                    ZIM.getInstance().queryHistoryMessage(Constant.agent_zim_robotid, ZIMConversationType.PEER, queryConfig,
                        new ZIMMessageQueriedCallback() {
                            @Override
                            public void onMessageQueried(String conversationID, ZIMConversationType conversationType,
                                ArrayList<ZIMMessage> messageList, ZIMError errorInfo) {
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

        ZIM.getInstance().setEventHandler(new ZIMEventHandler() {
            @Override
            public void onPeerMessageReceived(ZIM zim, ArrayList<ZIMMessage> messageList, ZIMMessageReceivedInfo info,
                String fromUserID) {
                // 只添加本会话的消息到本页面
                List<ZIMMessage> collect = messageList.stream()
                    .filter(zimMessage -> Objects.equals(Constant.agent_zim_robotid, zimMessage.getConversationID()))
                    .collect(Collectors.toList());
                chatListView.addMessageList(collect);
            }
        });

        TextView aiName = findViewById(R.id.ai_name);
        aiName.setText(Constant.agent_name);

        EditText chatText = findViewById(R.id.chat_text);
        findViewById(R.id.send_text).setOnClickListener(v -> {
            String string = chatText.getText().toString();
            if (TextUtils.isEmpty(string)) {
                Toast.makeText(TextChatActivity.this, "请输入文本", Toast.LENGTH_SHORT).show();
                return;
            }
            ZIMTextMessage zimMessage = new ZIMTextMessage();
            zimMessage.message = string;
            // 在单聊场景中，ZIMConversationType 设置为 PEER
            ZIM.getInstance().sendMessage(zimMessage, Constant.agent_zim_robotid, ZIMConversationType.PEER, new ZIMMessageSendConfig(),
                new ZIMMessageSentFullCallback() {
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
            intent.putExtra("fromTextChat",true);
            startActivity(intent);
        });
    }

    private void showLoading(boolean show) {
        findViewById(R.id.loading_layout).setVisibility(show ? View.VISIBLE : View.GONE);
    }
}