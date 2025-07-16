package im.zego.aiagent.express.quickstart;

import im.zego.aiagent.express.quickstart.util.StringUtil;

public class Constant {
    // 需要接入方填入
    public static final long appId = ;  // 这个需要在即构控制台申请
    public static final String BASE_URL = ;  // 你部署的业务后台地址


    // 生成的随机字符串
    public static final String user_id = "user_id_" + StringUtil.generateRandomString(6);
    public static final String userName = "user_name_" + StringUtil.generateRandomString(6);
    public static final String user_stream_id = "user_stream_id_1"; //用户推流id
    public static final String room_id = "user_stream_id_" + StringUtil.generateRandomString(6); //客户数字人共同进入的房间id


}
