package im.zego.aiagent.express.quickstart.zim;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import im.zego.aiagent.express.quickstart.R;
import im.zego.zim.entity.ZIMMessage;
import im.zego.zim.entity.ZIMTextMessage;
import im.zego.zim.entity.ZIMUserInfo;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public class TextChatListView extends RecyclerView {

    private ChatMessageAdapter adapter;
    private Handler handler = new Handler(Looper.getMainLooper());

    public TextChatListView(@NonNull Context context) {
        super(context);
        initView();
    }

    public TextChatListView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public TextChatListView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        // 创建并设置布局管理器
        LinearLayoutManager layoutManager = new LinearLayoutManager(getContext());
        layoutManager.setStackFromEnd(true); // 设置从底部开始堆叠
        setLayoutManager(layoutManager);
        // 初始化适配器
        adapter = new ChatMessageAdapter();
        setAdapter(adapter);
    }

    private static final String TAG = "TextChatListView";

    public void addMessageList(List<ZIMMessage> messageList) {
        Log.d(TAG, "addMessageList() called with: messageList = [" + messageList + "]");
        if (messageList.isEmpty()) {
            return;
        }
        adapter.addMessageList(messageList);
        handler.post(() -> smoothScrollToPosition(adapter.getItemCount() - 1));
    }

    public void addMessage(ZIMMessage zimMessage) {
        adapter.addMessage(zimMessage);
        handler.post(() -> smoothScrollToPosition(adapter.getItemCount() - 1));
    }

    public void setUserInfo(ZIMUserInfo self, ZIMUserInfo robot) {
        adapter.setUserInfo(self, robot);
    }

    public static class ChatMessageAdapter extends Adapter<ChatMessageAdapter.MessageViewHolder> {

        private List<ZIMMessage> chatMessageList;
        private SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm", Locale.getDefault());
        private ZIMUserInfo self;
        private ZIMUserInfo robot;

        public ChatMessageAdapter() {
            this.chatMessageList = new ArrayList<>();
        }

        // 辅助方法：将 dp 转换为 px
        private int dpToPx(int dp, Context context) {
            return (int) (dp * context.getResources().getDisplayMetrics().density + 0.5f);
        }

        @NonNull
        @Override
        public MessageViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_chat_message, parent, false);
            return new MessageViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull MessageViewHolder holder, int position) {
            ZIMMessage message = chatMessageList.get(position);

            // 假设文本消息是 ZIMTextMessage 类型，需要类型转换
            if (message instanceof ZIMTextMessage) {
                ZIMTextMessage textMessage = (ZIMTextMessage) message;
                holder.contentTextView.setText(textMessage.message);
            }

            // 设置发送者名字
            if (self != null) {
                if (Objects.equals(message.getSenderUserID(), self.userID)) {
                    holder.senderNameTextView.setText(self.userName);
                }
            }

            if (robot != null) {
                if (Objects.equals(message.getSenderUserID(), robot.userID)) {
                    holder.senderNameTextView.setText(robot.userName);
                }
            }

            // 设置时间
            String time = dateFormat.format(new Date(message.getTimestamp()));
            holder.timestampTextView.setText(time);

            // 根据消息方向调整布局
            LinearLayout.LayoutParams containerParams = (LinearLayout.LayoutParams) holder.messageContainer.getLayoutParams();
            LinearLayout.LayoutParams contentParams = (LinearLayout.LayoutParams) holder.contentTextView.getLayoutParams();
            LinearLayout.LayoutParams timeParams = (LinearLayout.LayoutParams) holder.timestampTextView.getLayoutParams();
            LinearLayout.LayoutParams sendInfoLayoutParams = (LinearLayout.LayoutParams) holder.sendMessageInfoLayout.getLayoutParams();

            if (self != null) {
                if (Objects.equals(message.getSenderUserID(), self.userID)) {
                    holder.messageContainer.setGravity(Gravity.END); // 设置容器内的子视图靠右
                    holder.contentTextView.setBackgroundResource(R.drawable.item_im_bg_self);
                    contentParams.gravity = Gravity.END;
                    timeParams.gravity = Gravity.END;
                    sendInfoLayoutParams.gravity = (Gravity.END); // 名字也靠右
                } else {
                    holder.messageContainer.setGravity(Gravity.START); // 设置容器内的子视图靠左
                    holder.contentTextView.setBackgroundResource(R.drawable.item_im_bg_other);
                    contentParams.gravity = Gravity.START;
                    timeParams.gravity = Gravity.START;
                    sendInfoLayoutParams.gravity = (Gravity.START); // 名字靠左
                }
            }

            holder.contentTextView.setLayoutParams(contentParams);
            holder.messageContainer.setLayoutParams(containerParams);
        }

        @Override
        public int getItemCount() {
            return chatMessageList.size();
        }

        public void addMessageList(List<ZIMMessage> messageList) {
            this.chatMessageList.addAll(messageList);
            notifyItemRangeInserted(chatMessageList.size() - messageList.size(), messageList.size());
        }

        public void addMessage(ZIMMessage zimMessage) {
            chatMessageList.add(zimMessage);
            notifyItemInserted(chatMessageList.size() - 1);
        }

        public void setUserInfo(ZIMUserInfo self, ZIMUserInfo robot) {
            this.self = self;
            this.robot = robot;
        }

        static class MessageViewHolder extends ViewHolder {

            TextView senderNameTextView;
            TextView contentTextView;
            TextView timestampTextView;
            LinearLayout messageContainer;
            LinearLayout sendMessageInfoLayout;

            MessageViewHolder(@NonNull View itemView) {
                super(itemView);
                senderNameTextView = itemView.findViewById(R.id.tv_sender_name);
                contentTextView = itemView.findViewById(R.id.tv_message_content);
                timestampTextView = itemView.findViewById(R.id.tv_timestamp);
                messageContainer = itemView.findViewById(R.id.message_container);
                sendMessageInfoLayout = itemView.findViewById(R.id.send_msg_info_layout);
            }
        }
    }
}
