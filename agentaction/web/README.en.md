# Web Usage

## Directory Layout

- `web/agentaction`: copyable Web suite.
- `web/demo`: runnable browser demo.

> Chinese version: [README.md](./README.md)

## Copy Into Your Project

Copy `web/agentaction` into your Web project, then install the protobuf runtime in that folder:

```bash
cd web/agentaction
npm install
```

Load the suite from the copied folder:

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

The `sender` function is the only adapter point. It receives:

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

Forward Express `onRecvRoomChannelMessage` payloads to `client.handleRoomChannelMessage(data)`.

## Run Demo

Open `web/demo/index.html` in a browser. The demo imports `../agentaction/src/zego_ai_agent_action.js` and uses a mock room channel sender.
