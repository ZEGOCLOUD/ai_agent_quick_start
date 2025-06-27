package im.zego.aiagent.express.quickstart;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;


import im.zego.aiagent.express.quickstart.voice.VoiceChatActivity;
import im.zego.aiagent.express.quickstart.video.VideoChatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        findViewById(R.id.button_voice_call).setOnClickListener(view -> {
            Intent intent = new Intent(MainActivity.this, VoiceChatActivity.class);
            startActivity(intent);
        });

        findViewById(R.id.button_video_call).setOnClickListener(view -> {
            Intent intent = new Intent(MainActivity.this, VideoChatActivity.class);
            startActivity(intent);
        });
    }
}
