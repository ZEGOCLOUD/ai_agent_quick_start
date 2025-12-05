package im.zego.aiagent.express.quickstart.voice;

import android.os.Build;
import android.text.TextUtils;
import android.util.Log;
import androidx.annotation.NonNull;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import com.google.gson.annotations.SerializedName;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Objects;
import java.util.stream.Collectors;

public class AudioChatMessageParser {

    private Gson gson = new GsonBuilder().setPrettyPrinting().create();
    /**
     * 消息列表的所有数据
     */
    private List<AudioChatMessage> rtcMessageList = new ArrayList<>();
    /**
     * LLM消息缓存
     */
    private Map<String, List<AudioChatMessage>> llmMessageTemp = new HashMap<>();
    /**
     * LLM消息时间记录
     */
    private Map<String, Long> messageTimes = new HashMap<>();

    private AudioChatMessageListListener listener;

    private long lastCMDSeq;

    private static String TAG = "AudioChatMessageParser";

    private static final boolean SUPPORT_STREAM = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O;

    /**
     * 输入
     *
     * @param message 消息输入
     * @return
     */
    public void parseAudioChatMessage(String message) {
        int cmd = parseCmdFromJson(message);

        if (cmd == 3) {
            updateASRChatMessage(message);
        } else if (cmd == 4) {
            addOrUpdateLLMChatMessage(message);
        } else if (cmd == 6) {
            AudioChatAgentStatusMessage statusMessage = gson.fromJson(message, AudioChatAgentStatusMessage.class);
            if (statusMessage.seqId < lastCMDSeq) { // 比上一次的seq小的话，舍弃掉
                return;
            }
            if (listener != null) {
                listener.onAudioChatStateUpdate(statusMessage);
            }
            lastCMDSeq = statusMessage.seqId;
        }
    }

    public int parseCmdFromJson(String jsonStr) {
        if (jsonStr == null || jsonStr.trim().isEmpty()) {
            return -1;
        }

        try {
            JsonObject obj = gson.fromJson(jsonStr, JsonObject.class);
            if (obj.has("Cmd")) {
                return obj.get("Cmd").getAsInt();
            } else if (obj.has("cmd")) {
                return obj.get("cmd").getAsInt();
            }
        } catch (Exception e) {
            // 记录日志
        }
        return -1; // 默认值
    }


    /**
     * 根据消息ID和序列ID比较，更新或插入语音聊天文本消息。 如果存在相同消息ID的消息，仅当新消息的序列ID更高时更新。 否则，将新消息插入列表。
     *
     * @param messageString 要处理的新语音聊天文本消息
     */
    private void updateASRChatMessage(String messageString) {
        AudioChatMessage newMessage = gson.fromJson(messageString, AudioChatMessage.class);

        AudioChatMessage existedMessage = null;
        if (SUPPORT_STREAM) {
            existedMessage = rtcMessageList.stream()
                .filter(m -> m.cmd == 3 && Objects.equals(m.data.messageId, newMessage.data.messageId))
                .findAny()
                .orElse(null);
        } else {
            for (AudioChatMessage m : rtcMessageList) {
                if (m.cmd == 3 && Objects.equals(m.data.messageId, newMessage.data.messageId)) {
                    existedMessage = m;
                    break;
                }
            }
        }

        if (existedMessage != null) {
            if (existedMessage.seqId < newMessage.seqId) {
                Log.d(TAG, "本地seq_id 比较小，更新消息 = [" + newMessage + "]");
                existedMessage.seqId = newMessage.seqId;
                existedMessage.timestamp = newMessage.timestamp;
                existedMessage.round = newMessage.round;
                existedMessage.data = newMessage.data;
                if (listener != null) {
                    listener.onMessageListUpdated(rtcMessageList);
                }
            } else {
                Log.d(TAG, "本地seq_id 比较大，不用更新 = [" + newMessage + "]");
            }
        } else {
            Log.d(TAG, "新消息，直接插入 = [" + newMessage + "]");
            rtcMessageList.add(newMessage);
            if (listener != null) {
                listener.onMessageListUpdated(rtcMessageList);
            }
        }
    }

    /**
     * 处理LLM聊天消息的添加或更新。 每个轮次可能包含多个messageId，每个messageId可能分批发送多个LLM消息。 客户端需按照 messageId
     * 对消息排序并合并，仅显示每个轮次中seqId最大的messageId对应的合并消息。
     *
     * @param messageString 新接收的语音聊天文本消息
     */
    private void addOrUpdateLLMChatMessage(String messageString) {
        AudioChatMessage newMessage = gson.fromJson(messageString, AudioChatMessage.class);

        String mergedLLMText = mergeLLMMessages(newMessage);

        Log.d(TAG, "addOrUpdateLLMChatMessage() called with: mergedLLMText = [" + mergedLLMText + "]");
        if (TextUtils.isEmpty(mergedLLMText)) {
            Log.d(TAG, "合并排序后文本为空，忽略");
            return;
        }

        // copy 一下，避免影响到 llmMessageTemp 里面的数据
        AudioChatMessage newLLMMessage = new AudioChatMessage();
        newLLMMessage.timestamp = newMessage.timestamp;
        newLLMMessage.seqId = newMessage.seqId;
        newLLMMessage.round = newMessage.round;
        newLLMMessage.cmd = newMessage.cmd;
        newLLMMessage.data = new AudioChatMessage.Data();
        newLLMMessage.data.text = mergedLLMText;
        newLLMMessage.data.messageId = newMessage.data.messageId;
        newLLMMessage.data.endFlag = newMessage.data.endFlag;

        List<AudioChatMessage> roundLLMMessages = new ArrayList<>();
        if (SUPPORT_STREAM) {
            roundLLMMessages = rtcMessageList.stream()
                .filter(m -> m.round == newMessage.round && m.cmd == 4)
                .collect(Collectors.toList());
        } else {
            for (AudioChatMessage m : rtcMessageList) {
                if (m.round == newMessage.round && m.cmd == 4) {
                    roundLLMMessages.add(m);
                }
            }
        }

        if (roundLLMMessages.isEmpty()) {
            // 如果这一轮round 在消息列表中还没有message,那么就直接插入这条消息。
            rtcMessageList.add(newLLMMessage);
        } else {
            //如果已经有了,rtcMessageList 中的这一轮round应该只有一条消息
            AudioChatMessage inListMessage = roundLLMMessages.get(0);
            if (inListMessage != null) {
                // 如果新消息和已经有的消息id相同
                if (Objects.equals(newMessage.data.messageId, inListMessage.data.messageId)) {
                    // 新消息的 seqId 比较小，忽略
                    Log.d(TAG, "同一 round 已存在相同 message_id 的消息: " + newMessage.data.messageId + ", seq_id: "
                        + newMessage.seqId + ",合并更新");

                    int index = rtcMessageList.indexOf(inListMessage);
                    rtcMessageList.set(index, newLLMMessage);
                } else {
                    // 这里是 同一轮里面，新消息和已经有的消息id 不同
                    if (inListMessage.seqId > newMessage.seqId) {
                        Log.d(TAG,
                            "同一 round 已存在不同 message_id 的消息: " + newMessage.data.messageId + ", seq_id: "
                                + newMessage.seqId + ",但是新消息 seqId 比较小，忽略");
                    } else {
                        Log.d(TAG,
                            "同一 round 已存在不同 message_id 的消息: " + newMessage.data.messageId + ", seq_id: "
                                + newMessage.seqId + ",新消息 seqId 比较大，更新");
                        int index = rtcMessageList.indexOf(inListMessage);
                        rtcMessageList.set(index, newLLMMessage);
                    }
                }
            }
        }

        clearCacheIfNeed(newMessage);

        if (listener != null) {
            listener.onMessageListUpdated(rtcMessageList);
        }
    }

    @NonNull
    private String mergeLLMMessages(AudioChatMessage newMessage) {
        // 找到新的messageId 对应的缓存并且把这个message 插入进去
        List<AudioChatMessage> rtcRoomMessages = llmMessageTemp.get(newMessage.data.messageId);
        // 先插入列表
        if (rtcRoomMessages == null) {
            rtcRoomMessages = new ArrayList<>();
            rtcRoomMessages.add(newMessage);
            llmMessageTemp.put(newMessage.data.messageId, rtcRoomMessages);
        } else {
            rtcRoomMessages.add(newMessage);
        }

        if (SUPPORT_STREAM) {
            return rtcRoomMessages.stream()
                .sorted(Comparator.comparingLong(m -> m.seqId))
                .map(m -> m.data.text != null ? m.data.text : "")
                .collect(Collectors.joining());
        } else {
            // 手动排序（简单插入排序或复制后 Collections.sort）
            List<AudioChatMessage> sorted = new ArrayList<>(rtcRoomMessages);
            Collections.sort(sorted, (a, b) -> Long.compare(a.seqId, b.seqId));

            StringBuilder sb = new StringBuilder();
            for (AudioChatMessage m : sorted) {
                if (m.data.text != null) {
                    sb.append(m.data.text);
                }
            }
            return sb.toString();
        }
    }

    private void clearCacheIfNeed(AudioChatMessage newMessage) {
        // 来了新消息，按照 <messageID,当前时间> 存入 map
        messageTimes.put(newMessage.data.messageId, System.currentTimeMillis());

        Iterator<Entry<String, Long>> iterator = messageTimes.entrySet().iterator();
        while (iterator.hasNext()) {
            Entry<String, Long> entry = iterator.next();
            String messageID = entry.getKey();
            long lastTime = entry.getValue();
            long current = System.currentTimeMillis();
            // 遍历整个map检查每一个messageID,如果超过 4 秒还没有更新，删除对应的缓存消息列表（假设同一条message 如果没发完，4秒内是会收到更新的）
            if (current - lastTime >= 4000) {
                llmMessageTemp.remove(messageID);
                Log.d(TAG,
                    " 清除 message_id :" + messageID + " 缓存列表，目前还有" + llmMessageTemp.size() + "个缓存列表");
                iterator.remove();
            }
        }
    }

    public void setAudioChatMessageListListener(AudioChatMessageListListener listener) {
        this.listener = listener;
    }


    public interface AudioChatMessageListListener {

        void onMessageListUpdated(List<AudioChatMessage> messagesList);

        void onAudioChatStateUpdate(AudioChatAgentStatusMessage statusMessage);
    }

    /**
     * 语音聊天界面，接收到的后台服务器发过来的 房间内的聊天消息的结构体
     */
    public static class AudioChatMessage {

        @SerializedName(value = "Timestamp", alternate = "timestamp")
        public long timestamp;
        @SerializedName(value = "SeqId", alternate = "seq_id")
        public long seqId;
        @SerializedName(value = "Round", alternate = "round")
        public long round;
        @SerializedName(value = "Cmd", alternate = "cmd")
        public int cmd;
        @SerializedName(value = "Data", alternate = "data")
        public Data data;

        public static class Data {

            @SerializedName(value = "Text", alternate = "text")
            public String text;
            @SerializedName(value = "MessageId", alternate = "message_id")
            public String messageId;
            @SerializedName(value = "EndFlag", alternate = "end_flag")
            public boolean endFlag;
            @SerializedName(value = "UserId", alternate = "user_id")
            public String userId;

            @Override
            public String toString() {
                return "Data{" + "text='" + text + '\'' + ", messageId='" + messageId + '\'' + '}';
            }
        }

        @Override
        public String toString() {
            return "AudioChatMessage{" + "seqId=" + seqId + ", round=" + round + ", data=" + data + '}';
        }
    }

    public static class AudioChatAgentStatusMessage {

        @SerializedName(value = "Timestamp", alternate = "timestamp")
        public long timestamp;
        @SerializedName(value = "SeqId", alternate = "seq_id")
        public long seqId;
        @SerializedName(value = "Round", alternate = "round")
        public long round;
        @SerializedName(value = "Cmd", alternate = "cmd")
        public int cmd;
        @SerializedName(value = "Data", alternate = "data")
        public Data data;

        public static class Data {

            @SerializedName(value = "Status")
            public int status;
            @SerializedName(value = "OldStatus")
            public int oldStatus;
            @SerializedName(value = "Reason")
            public String reason;

            public static final int IDLE = 0;
            public static final int LISTENING = 1;
            public static final int THINKING = 2;
            public static final int SPEAKING = 3;
        }
    }
}
