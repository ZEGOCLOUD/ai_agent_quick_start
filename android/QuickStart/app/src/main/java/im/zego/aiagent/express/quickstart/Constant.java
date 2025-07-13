package im.zego.aiagent.express.quickstart;

import im.zego.aiagent.express.quickstart.util.StringUtil;

public class Constant {

    public static final long appId = ;  // 这个需要在机构申请

    public static final String agent_id = "agent_id_android"; //客户端推流
    public static final String agent_name = "小智"; //客户端推流
    public static final String digital_human_id = "c4b56d5c-db98-4d91-86d4-5a97b507da97"; //客户端推流

    public static final String user_id =  "user_id_" + StringUtil.generateRandomString(6); //客户端推流
    public static final String userName =  "user_name_" + StringUtil.generateRandomString(6); //客户端用户名
    public static final String user_stream_id = "west_user_stream_id_1"; //用户推流id
    public static final String room_id = "user_stream_id_"+ StringUtil.generateRandomString(6); //客户数字人共同进入的房间id

    public static final String agent_user_id = "agent_user_id_" + StringUtil.generateRandomString(6); //agent推流id，数字人推流id
    public static final String agent_stream_id = "agent_stream_id_" + StringUtil.generateRandomString(6); //agent推流id，数字人推流id
    public static final String agent_zim_uid = "ddddd";  // 你部署的业务后台用到的参数
    public static final String BASE_URL = ;  // 你部署的业务后台地址
}
