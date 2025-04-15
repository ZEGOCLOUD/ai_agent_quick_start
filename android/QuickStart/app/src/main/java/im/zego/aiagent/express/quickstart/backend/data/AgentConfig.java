package im.zego.aiagent.express.quickstart.backend.data;

import com.google.gson.annotations.SerializedName;

public class AgentConfig {

    @SerializedName("Name")
    public String name;
    @SerializedName("LLM")
    public LLM llm;
    @SerializedName("TTS")
    public TTS tts;

    public static class LLM {

        @SerializedName("Url")
        public String url;
        @SerializedName("ApiKey")
        public String apiKey;
        @SerializedName("Model")
        public String model;
        @SerializedName("SystemPrompt")
        public String systemPrompt;
    }

    public static class TTS {

        @SerializedName("Vendor")
        public String vendor;
        @SerializedName("Params")
        public Params params;

        public static class Params {

            @SerializedName("app")
            public App app;
            @SerializedName("speed_ratio")
            public Integer speedRatio;
            @SerializedName("volume_ratio")
            public Integer volumeRatio;
            @SerializedName("pitch_ratio")
            public Integer pitchRatio;
            @SerializedName("emotion")
            public String emotion;
            @SerializedName("audio")
            public Audio audio;

            public static class App {

                @SerializedName("appid")
                public String appid;
                @SerializedName("token")
                public String token;
                @SerializedName("cluster")
                public String cluster;
            }

            public static class Audio {

                @SerializedName("rate")
                public Integer rate;
                @SerializedName("voice_type")
                public String voiceType;
            }
        }
    }
}
