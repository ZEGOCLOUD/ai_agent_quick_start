package im.zego.aiagent.express.quickstart.backend.callback;


import im.zego.aiagent.express.quickstart.backend.data.CreateAgentInstanceRsp;

public interface CreateAgentInstanceCallback {

    void onResult(int errorCode, String message, String requestId, CreateAgentInstanceRsp createAgentInstanceRsp);
}
