package im.zego.aiagent.express.quickstart.backend.network;

public interface HttpCallback {

    void onResult(int errorCode, String message, String responseBody);
}
