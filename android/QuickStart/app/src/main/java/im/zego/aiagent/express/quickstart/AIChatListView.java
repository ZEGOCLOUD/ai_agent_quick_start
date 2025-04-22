package im.zego.aiagent.express.quickstart;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;
import androidx.constraintlayout.widget.ConstraintLayout;
import im.zego.aiagent.express.quickstart.AudioChatMessageParser.AudioChatMessage;
import java.util.ArrayList;
import java.util.List;

public class AIChatListView extends ListView {

    private static final String TAG = "AIChatListView";
    private ZegoVoiceCallMessageAdapter messageAdapter;
    private boolean autoScrollToBottom = true;

    public AIChatListView(Context context) {
        super(context);
        initView();
    }

    public AIChatListView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public AIChatListView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        messageAdapter = new ZegoVoiceCallMessageAdapter();
        setAdapter(messageAdapter);
        setDivider(null);
        setDividerHeight(0);

        // 监听触摸和滚动，判断是否需要自动滚动到底部
        setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                updateAutoScrollState();
            }
            return false;
        });

        setOnScrollListener(new OnScrollListener() {
            @Override
            public void onScrollStateChanged(AbsListView view, int scrollState) {
            }

            @Override
            public void onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount) {
                updateAutoScrollState();
            }
        });
    }

    // 更新自动滚动状态：如果列表底部完全可见，则启用自动滚动
    private void updateAutoScrollState() {
        if (getChildCount() == 0) {
            autoScrollToBottom = true;
            return;
        }

        View lastVisibleView = getChildAt(getChildCount() - 1);
        int lastVisiblePosition = getLastVisiblePosition();
        boolean isAtBottom = lastVisiblePosition == messageAdapter.getCount() - 1
            && lastVisibleView.getBottom() <= getHeight();
        autoScrollToBottom = isAtBottom;
    }

    // 简化的滚动到底部逻辑
    private void scrollToBottom() {
        if (!autoScrollToBottom || getChildCount() == 0) {
            return;
        }

        int lastPosition = messageAdapter.getCount() - 1;
        smoothScrollToPosition(lastPosition);
        Log.d(TAG, "Scrolled to position: " + lastPosition);
    }

    public void onMessageListUpdated(List<AudioChatMessage> messages) {
        messageAdapter.onMessageListUpdated(messages);
        scrollToBottom();
    }

    public static class ZegoVoiceCallMessageAdapter extends BaseAdapter {

        private final List<AudioChatMessage> messages = new ArrayList<>();

        public void onMessageListUpdated(List<AudioChatMessage> newMessages) {
            messages.clear();
            messages.addAll(newMessages);
            notifyDataSetChanged();
        }

        @Override
        public int getCount() {
            return messages.size();
        }

        @Override
        public AudioChatMessage getItem(int position) {
            return messages.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position; // 简化，使用 position 作为 ID
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            ViewHolder holder;
            if (convertView == null) {
                convertView = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.widget_voice_call_message_item, parent, false);
                holder = new ViewHolder();
                holder.content = convertView.findViewById(R.id.content);
                holder.cost = convertView.findViewById(R.id.cost);
                convertView.setTag(holder);
            } else {
                holder = (ViewHolder) convertView.getTag();
            }

            AudioChatMessage message = getItem(position);
            configureMessageView(holder, message);
            return convertView;
        }

        private void configureMessageView(ViewHolder holder, AudioChatMessage message) {
            ConstraintLayout.LayoutParams lp = (ConstraintLayout.LayoutParams) holder.content.getLayoutParams();
            if (message.cmd == 3) {
                // 己方消息
                holder.content.setBackgroundResource(R.drawable.rounded_im_me);
                holder.content.setTextColor(0xFFFFFFFF); // 白色
                holder.cost.setVisibility(View.GONE);
                lp.endToEnd = ConstraintLayout.LayoutParams.PARENT_ID;
                lp.startToStart = ConstraintLayout.LayoutParams.UNSET;
            } else {
                // 对方消息
                holder.content.setBackgroundResource(R.drawable.rounded_im_other);
                holder.content.setTextColor(0xFF000000); // 黑色
                lp.endToEnd = ConstraintLayout.LayoutParams.UNSET;
                lp.startToStart = ConstraintLayout.LayoutParams.PARENT_ID;
            }
            holder.content.setLayoutParams(lp);
            holder.content.setText(message.data.text);
        }

        static class ViewHolder {
            TextView content;
            TextView cost;
        }
    }
}