package im.zego.aiagent.express.quickstart.core;

/**
 * 认证数据类，用于存储和管理应用程序的认证信息。 该类包含了应用程序ID、签名等基本认证信息。
 */
public class AuthData {

    /**
     * 应用程序ID，用于标识应用程序的唯一性
     */
    public long appID;
    /**
     * 应用程序签名，用于验证应用程序的合法性
     */
    public String appSign;

    /**
     * 创建一个新的AuthData实例
     *
     * @param appID   应用程序ID
     * @param appSign 应用程序签名
     */

    public String serverSecret;

    public AuthData(long appID, String appSign, String serverSecret) {
        this.appID = appID;
        this.appSign = appSign;
        this.serverSecret = serverSecret;
    }


    @Override
    public String toString() {
        return "AuthData{" + "appID=" + appID + '}';
    }
}
