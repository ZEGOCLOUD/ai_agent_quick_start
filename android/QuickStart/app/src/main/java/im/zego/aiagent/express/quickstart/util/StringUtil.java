package im.zego.aiagent.express.quickstart.util;
import java.util.Random;

public class StringUtil {
    // 定义一个字符集
    private static final String CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    // 生成指定长度的随机字符串
    public static String generateRandomString(int length) {
        Random random = new Random();
        StringBuilder sb = new StringBuilder(length);

        for (int i = 0; i < length; i++) {
            // 随机选择字符集中的一个字符
            int index = random.nextInt(CHARSET.length());
            sb.append(CHARSET.charAt(index));
        }

        return sb.toString();
    }

    public static void main(String[] args) {
        // 生成一个长度为10的随机字符串
        System.out.println(generateRandomString(10));
    }
}
