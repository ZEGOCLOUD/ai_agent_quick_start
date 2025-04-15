package im.zego.aiagent.express.quickstart.core;

/**
 * 用户配置文件类，用于存储和管理用户的基本信息。 该类包含了用户ID、用户名和头像URL等基本用户信息。
 */
public class UserProfile {

    /**
     * 用户唯一标识符
     */
    public String userID;
    /**
     * 用户名称
     */
    public String userName;


    /**
     * 创建一个新的UserProfile实例
     *
     * @param userID   用户唯一标识符
     * @param userName 用户名称
     */
    public UserProfile(String userID, String userName) {
        this.userID = userID;
        this.userName = userName;
    }

    @Override
    public String toString() {
        return "UserProfile{" + "userID='" + userID + '\'' + ", userName='" + userName + '\'' + '}';
    }
}
