# Web 使用说明

## 目录结构

- `web/agentaction`：可拷贝的 Web 套件。
- `web/demo`：可运行的浏览器 Demo。

> 英文版本请见 [README.en.md](./README.en.md)。

## 拷贝到你的项目

将 `web/agentaction` 拷贝到你的 Web 项目中，然后在拷贝后的目录安装 Protobuf 运行时：

```bash
cd web/agentaction
npm install
```

从拷贝后的目录加载套件：

```html
<script src="./agentaction/src/zego_ai_agent_action.js"></script>
<script>
const client = new ZegoAIAgentAction.ZegoAIAgentActionClient({
  roomId: 'room_1',
  userId: 'client_A',
  agentUserId: 'agent_1',
  sender: (params) => zegoExpress.sendRoomChannelMessage(params),
  onResponse: (response) => console.log(response)
});

const params = new ZegoAIAgentAction.Protobuf.SendAgentInstanceTTSParams();
params.setText('hello');
params.setAddHistory(true);
params.setPriority('Medium');
params.setSamePriorityOption('ClearAndInterrupt');
const response = await client.sendAgentInstanceTTS(params);
</script>
```

`sender` 函数是唯一的适配接入点，接收如下参数：

```js
{
  roomId,
  msgType: 20,
  msg_type: 20,
  seq,
  msgContent,
  msg_content,
  userList: [agentUserId]
  user_list: [agentUserId]
}
```

将 Express 的 `onRecvRoomChannelMessage` 回调载荷转发给 `client.handleRoomChannelMessage(data)`。

## 运行 Demo

用浏览器直接打开 `web/demo/index.html` 即可。Demo 引入 `../agentaction/src/zego_ai_agent_action.js`，并使用 Mock 房间通道发送器。
