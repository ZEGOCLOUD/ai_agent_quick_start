package im.zego.aiagent.express.quickstart;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
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
            Intent intent = new Intent(MainActivity.this, VoiceChatActivity.class);
            startActivity(intent);
        });

        // 判断Android版本是否大于26
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
            findViewById(R.id.button_video_call).setOnClickListener(view -> {
                Intent intent = new Intent(MainActivity.this, VideoChatActivity.class);
                startActivity(intent);
            });
        } else {
            Toast.makeText(this, "Minimum Requirements: Android 26", Toast.LENGTH_SHORT).show();
        }
    }
}
