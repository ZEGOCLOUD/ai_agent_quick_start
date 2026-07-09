package im.zego.aiagent.express.quickstart;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import im.zego.aiagent.express.quickstart.video.VideoChatActivity;
import im.zego.aiagent.express.quickstart.voice.VoiceChatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        findViewById(R.id.button_voice_call).setOnClickListener(view -> {
            if (!checkConfigValid()) {
                return;
            }
            Intent intent = new Intent(MainActivity.this, VoiceChatActivity.class);
            startActivity(intent);
        });

        // 判断Android版本是否大于26
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            findViewById(R.id.button_video_call).setOnClickListener(view -> {
                if (!checkConfigValid()) {
                    return;
                }
                Intent intent = new Intent(MainActivity.this, VideoChatActivity.class);
                startActivity(intent);
            });
        } else {
            Toast.makeText(this, "Minimum Requirements: Android 26", Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * 跳转前校验 BASE_URL，避免进入目标页后才因非法 URL 崩溃或闪退
     */
    private boolean checkConfigValid() {
        String url = Constant.BASE_URL;
        if (TextUtils.isEmpty(url)
            || (!url.startsWith("http://") && !url.startsWith("https://"))) {
            Toast.makeText(this,
                "请先在 Constant.java 中配置正确的 BASE_URL（需以 http:// 或 https:// 开头）",
                Toast.LENGTH_LONG).show();
            return false;
        }
        return true;
    }
}
