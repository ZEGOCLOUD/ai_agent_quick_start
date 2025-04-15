package im.zego.aiagent.express.quickstart.backend.data;

import com.google.gson.annotations.SerializedName;

public class RtcInfo {

    @SerializedName("RoomId")
    public String roomId;
    @SerializedName("AgentStreamId")
    public String agentStreamId;
    @SerializedName("AgentUserId")
    public String agentUserId;
    @SerializedName("UserStreamId")
    public String userStreamId;
    @SerializedName("WelcomeMessage")
    public String welcomeMessage;
}
