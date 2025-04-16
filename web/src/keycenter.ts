const config = {
  appId: 1234567,
  serverSecret: "",
  server: "",
  // 第三方服务商llm配置
  llm: {
    url: "",
    key: "",
    model: "",
  },
  // 第三方服务商tts配置
  tts: {
    vendor: "Bytedance",
    // 各家厂商的TTS参数，可根据实际情况进行调整
    params: {
      app: {
        appid: "",
        token: "",
        cluster: "",
      },
      audio: {
        voice_type: "",
      },
    }
  }
}

export default config