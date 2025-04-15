package im.zego.aiagent.express.quickstart.backend.network_wrapper;

public interface BackendCallback<T> {

    void onResult(int errorCode, String message, String requestId, T t);
}
