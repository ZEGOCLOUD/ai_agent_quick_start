package im.zego.aiagent.express.quickstart;

import im.zego.aiagent.express.quickstart.util.StringUtil;

/**
 * 配置中心。运行示例前请先修改下方【需要填入】的配置项（带 TODO 标注）。
 * <p>
 * 修改步骤详见 README.md「跑通步骤」。
 */
public class Constant {

    // ======================== 需要填入（带 TODO） ========================

    // TODO: 填入 ZEGO 控制台申请的 AppID（须与业务后台使用的一致），否则登录房间会失败
    public static final long appId = 0;

    // TODO: 填入你部署的业务后台地址，例如 https://your-server.example.com（末尾不要带斜杠）
    public static final String BASE_URL = "";

    // TODO: 数字人 / 播报数字人场景需要，填入你账号下有效的数字人形象 ID（语音通话场景可不改）
    public static final String digital_human_id = "";


    // ======================== 一般无需修改 ========================

    // 数字人场景默认配置，按需调整
    public static final String config_id = "mobile";
    public static final String digital_human_image_URL =
        "https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg";

    // 运行时随机生成的用户与房间标识，通常无需修改
    public static final String user_id = "user_id_" + StringUtil.generateRandomString(6);
    public static final String userName = "user_name_" + StringUtil.generateRandomString(6);
    public static final String user_stream_id = "user_stream_id_1"; // 用户推流 id
    public static final String room_id = "user_stream_id_" + StringUtil.generateRandomString(6); // 客户与数字人共同进入的房间 id

}
