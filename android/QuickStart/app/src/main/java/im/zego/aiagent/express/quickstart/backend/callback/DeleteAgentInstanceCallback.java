package im.zego.aiagent.express.quickstart.backend.callback;

public interface DeleteAgentInstanceCallback {

    void onResult(int errorCode, String message, String requestId);
}
