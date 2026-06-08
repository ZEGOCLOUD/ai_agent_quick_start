# Web 使用说明

本目录提供 Web 端 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Web 套件源码。
- `demo/`：可运行的浏览器 Demo，详见 [demo/README.md](./demo/README.md)。

> 英文版本请见 [README.en.md](./README.en.md)。

## 集成步骤

### 1. 拷贝源码

将 `web/agentaction` 拷贝到你的 Web 项目中。浏览器直接 `<script>` 引入时无需额外安装；如果使用 CommonJS/打包工具引入，请在拷贝后的目录安装 Protobuf 运行时：

```bash
cd web/agentaction
npm install
```

### 2. 加载套件

浏览器直接引入时按以下顺序加载：

```html
<script src="./agentaction/src/defines.js"></script>
<script src="./agentaction/src/logger.js"></script>
<script src="./agentaction/src/zego_ai_agent_action.js"></script>
```

如果使用 CommonJS，也可以 `require('./agentaction/src/zego_ai_agent_action')`，此时会使用 `src/generated/ai_agent_action_pb.js` 与 `google-protobuf`。

### 3. 实现 Sender，桥接到 ZEGO Express

`ZegoAIAgentActionClient` 的 `sender` 接收套件组装好的 JSON 信封与 `roomId / msgType / userList / seq` 等元数据。实际接入时只需要把 `formatedJson` 原样透传给 Web Express SDK 的 `callExperimentalAPI`。

```js
const client = new ZegoAIAgentAction.ZegoAIAgentActionClient({
  roomId: 'room_1',
  userId: 'client_A',
  agentUserId: 'agent_1',
  sender: async (params, formatedJson) => {
    try {
      const result = await zg.callExperimentalAPI(formatedJson);
      console.log('callExperimentalAPI result=', result);
      return {
        errorCode: ZegoAIAgentActionDefines.ErrorCodes.SUCCESS,
        seq: params.seq
      };
    } catch (e) {
      return {
        errorCode: ZegoAIAgentActionDefines.ErrorCodes.SEND_FAILED,
        seq: params.seq
      };
    }
  },
  onResponse: (response) => {
    console.log('recv', response.action, response.seq, response.code, response.message);
  },
  onError: (error) => {
    console.error('err', error.action, error.seq, error.code, error.message);
  }
});
```

`formatedJson` 形如：

```json
{
  "method": "liveroom.room.send_room_channel_message",
  "params": {
    "room_id": "room_1",
    "msg_content": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
    "user_list": ["agent_1"],
    "seq": 1
  }
}
```

### 4. 发送 Action

```js
const params = new ZegoAIAgentAction.Protobuf.SendAgentInstanceTTSParams();
params.setText('你好');
params.setAddHistory(true);
params.setPriority('Medium');
params.setSamePriorityOption('ClearAndInterrupt');

const response = await client.sendAgentInstanceTTS(params);
console.log('tts ok seq=', response.seq);
```

其他四个方法完全对称：

```js
const llm = new ZegoAIAgentAction.Protobuf.SendAgentInstanceLLMParams();
llm.setText('hi');
llm.setSystemPrompt('');
llm.setAddQuestionToHistory(false);
llm.setAddAnswerToHistory(true);
llm.setPriority('Medium');
llm.setSamePriorityOption('ClearAndInterrupt');
await client.sendAgentInstanceLLM(llm);

await client.interruptAgentInstance();
await client.startListening(new ZegoAIAgentAction.Protobuf.StartListeningParams());
await client.stopListening(new ZegoAIAgentAction.Protobuf.StopListeningParams());
```

> `text` 长度限制 300 字符；超时默认 5 秒，可通过方法 options 的 `timeoutMs` 覆盖。

### 5. 转发房间通道回调

Express 的 `recvExperimentalAPI` 回调内容丢给 `client.handleRoomChannelMessage(content)`，由套件判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回 `true`。
- AI Agent Action 发送回执：仅在 `errorCode != 0` 时把对应 `seq` 标为失败；返回 `true`。
- 其他消息返回 `false`，可继续走业务自定义消息解析。

```js
zg.on('recvExperimentalAPI', (content) => {
  const consumed = client.handleRoomChannelMessage(content);
  if (consumed) {
    console.log('agentaction message consumed');
  }
});
```

部分 Web Express 版本需要显式开启实验性 API 房间消息通道接收：

```js
zg.callExperimentalAPI(JSON.stringify({
  method: ZegoAIAgentActionDefines.ExpressMethods.onReciveRoomChannelMessage,
  params: {}
}));
```

### 6. 取消与清理

```js
client.cancelAll('logout');
```

### 7. 日志接管（可选）

```js
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
ZegoAIAgentActionLogger.installSink((level, label, message) => {
  console.log('[AgentAction]', message);
});
```

## 错误码

`ZegoAIAgentActionDefines.ErrorCodes`：

| 常量 | 值 | 触发条件 |
|---|---:|---|
| `SUCCESS` | `0` | 套件内部判定的所有成功路径 |
| `TIMEOUT` | `-1` | 默认 5 秒内未收到 AI Agent Action 响应 |
| `SEND_FAILED` | `-2` | `sender` 抛异常或 Express 发送失败 |
| `CANCELED` | `-3` | 主动调用 `client.cancelAll()` |

## 运行 Demo

用浏览器直接打开 `web/demo/index.html` 即可。运行前请在文件中替换你的 `appID / server / token`，并按业务需要替换 `roomId / userId / agentUserId`。
