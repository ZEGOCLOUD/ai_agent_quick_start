package im.zego.aiagent.express.quickstart.backend.callback;

public interface RegisterAgentCallback {

    void onResult(int errorCode, String message, String requestId);
}
