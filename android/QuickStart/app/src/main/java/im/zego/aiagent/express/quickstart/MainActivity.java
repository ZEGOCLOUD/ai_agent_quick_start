package im.zego.aiagent.express.quickstart;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import java.io.IOException;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import org.json.JSONException;
import org.json.JSONObject;
import timber.log.Timber;
import timber.log.Timber.DebugTree;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        Timber.plant(new DebugTree());
        findViewById(R.id.start_voice_chat).setOnClickListener(v -> {
            requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO);
        });
    }

    private final ActivityResultLauncher<String> requestPermissionLauncher = registerForActivityResult(
        new ActivityResultContracts.RequestPermission(), new ActivityResultCallback<Boolean>() {
            @Override
            public void onActivityResult(Boolean isGranted) {
                if (isGranted) {
                    registerAIAgent();
                }
            }
        });

    private void registerAIAgent() {
        String agentId = "zego_ai_agent";
        String agentName = "小智";

        ZegoQuickStartApi.registerAgent(agentId, agentName, new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                System.err.println("Request failed: " + e.getMessage());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    System.out.println(responseBody);

                    try {
                        JSONObject json = new JSONObject(responseBody);
                        int errorCode = (int) json.get("code");
                        String message = (String) json.get("message");
                        // 410001008 重复创建
                        if (errorCode == 0 || errorCode == 410001008) {
                            Intent intent = new Intent(MainActivity.this, VoiceChatActivity.class);
                            intent.putExtra("agentId", agentId);
                            intent.putExtra("agentName", agentName);
                            startActivity(intent);
                        } else {
                            Toast.makeText(MainActivity.this, "注册失败", Toast.LENGTH_SHORT).show();
                        }
                    } catch (JSONException e) {
                        throw new RuntimeException(e);
                    }
                } else {
                    System.err.println("Request failed with status: " + response.code());
                }

            }
        });
    }
}