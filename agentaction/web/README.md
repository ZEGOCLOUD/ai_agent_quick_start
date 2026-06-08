# Web 使用说明

本目录提供 Web 端 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Web 套件源码。
- `demo/`：可运行的浏览器 Demo，详见 [demo/README.md](./demo/README.md)。

> 英文版本请见 [README.en.md](./README.en.md)。

## 套件结构图

```text
web/
├── agentaction/
│   ├── package.json
│   ├── index.js
│   ├── index.d.ts
│   └── src/
│       ├── zego_ai_agent_action.js
│       ├── defines.js
│       ├── logger.js
│       └── generated/
│           └── ai_agent_action_pb.js
└── demo/
    └── index.html
```

可以把这几层理解成：

- `index.js`：套件对外的默认入口。打包工程、CommonJS、TS 项目优先从这里导入。
- `index.d.ts`：给 TypeScript 工程用的类型声明。它不参与运行，只负责让 IDE 和编译器知道套件暴露了哪些类、方法和参数。
- `src/zego_ai_agent_action.js`：套件真正的实现入口，`index.js` 最终就是转发到这里。
- `src/defines.js`：Web Express 实验性 API 的方法名、字段名、错误码等常量。
- `src/logger.js`：套件内部日志工具。
- `src/generated/ai_agent_action_pb.js`：已经生成好的 Protobuf 参数类，供 CommonJS/打包场景直接使用。

## 集成步骤

### 1. 拷贝源码

将 `web/agentaction` 拷贝到你的 Web 项目中。

- 浏览器直接 `<script>` 引入：无需额外安装。
- CommonJS / 打包工具 / TypeScript 项目：在拷贝后的目录安装依赖。

```bash
cd web/agentaction
npm install
```

### 2. 加载套件

推荐分成两种接入方式理解。

#### 方式 A：浏览器直接引入

按以下顺序加载：

```html
<script src="./agentaction/src/defines.js"></script>
<script src="./agentaction/src/logger.js"></script>
<script src="./agentaction/src/zego_ai_agent_action.js"></script>
```

加载完成后，套件会挂到全局对象：

```js
window.ZegoAIAgentAction
```

这种方式最适合直接打开 `html` 的 Demo 或纯浏览器页面。

#### 方式 B：工程化项目引入

如果你的 Web 项目是 CommonJS、Vite、Webpack、TS 工程，优先走包入口：

```js
const ZegoAIAgentAction = require('./agentaction');
```

或：

```ts
import ZegoAIAgentAction from './agentaction';
```

这里真正起作用的是：

- `package.json` 的 `"main": "index.js"`：告诉运行时默认入口是 `index.js`
- `package.json` 的 `"types": "index.d.ts"`：告诉 TypeScript 类型入口是 `index.d.ts`
- `index.js` 再把实现转发到 `src/zego_ai_agent_action.js`

也就是说，业务项目通常不需要再关心 `src/*.js` 的内部路径，只需要面向套件入口使用即可。

### 3. 实现 Sender，桥接到 ZEGO Express

`ZegoAIAgentActionClient` 的 `sender` 接收套件组装好的元数据，以及一个名为 `formatedJson` 的请求对象。名字沿用旧习惯，但在 Web 端它实际就是可直接传给 Express 的对象。

Web 端 Express 实验性 API 与 Android/iOS 原生端并不完全一致：

- 发送方法名是 `sendRoomChannelMessage`
- 接收回调方法名是 `onRecvRoomChannelMessage`
- `recvExperimentalAPI` 通常回调对象，而不是原生端那种 JSON 字符串
- Web 发送没有回调，因此发送是否成功主要依赖 `callExperimentalAPI` 是否抛错，业务结果则继续等待房间消息或超时

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
  "method": "sendRoomChannelMessage",
  "params": {
    "roomID": "room_1",
    "msgType": 20,
    "msgContent": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
    "toUserIDList": ["agent_1"],
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

Express 的 `recvExperimentalAPI` 回调对象直接丢给 `client.handleRoomChannelMessage(payload)`，由套件判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回 `true`。
- Web 侧没有发送回调，只根据业务响应或超时来结束请求。
- 其他消息返回 `false`，可继续走业务自定义消息解析。

```js
zg.on('recvExperimentalAPI', (payload) => {
  const consumed = client.handleRoomChannelMessage(payload);
  if (consumed) {
    console.log('agentaction message consumed');
  }
});
```

部分 Web Express 版本需要显式开启实验性 API 房间消息通道接收：

```js
zg.callExperimentalAPI({
  method: ZegoAIAgentActionDefines.ExpressMethods.onRecvRoomChannelMessage,
  params: {}
});
```

### 6. 取消与清理

```js
client.cancelAll('logout');
```

### 7. 日志接管（可选）

套件内部日志会自带时间戳和 `[DEBUG]/[INFO]/[WARN]/[ERROR]` 前缀。`ZegoAIAgentActionLogger` 既可以作为浏览器全局变量访问，也可以通过主入口的命名导出访问。

#### 方式 A：浏览器直接引入

```js
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
ZegoAIAgentActionLogger.installSink((level, label, message) => {
  console.log('[AgentAction]', message);
});
```

#### 方式 B：工程化项目（CommonJS / Vite / Webpack / TypeScript）

把 `<pkg>` 替换为发布到 npm 的实际包名。

```ts
import ZegoAIAgentAction from '<pkg>';

ZegoAIAgentAction.ZegoAIAgentActionLogger.installSink((level, _label, message) => {
  // level: 0=DEBUG 1=INFO 2=WARN 3=ERROR
  const tagged = `[agentaction] ${message}`;
  if (level >= 3) console.error(tagged);
  else if (level >= 2) console.warn(tagged);
  else console.log(tagged);
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

## 疑难杂症

> 以下场景只针对把套件以 `file:` 依赖方式 vendored 进自己项目、二次开发套件源码的开发者。普通 `npm i <pkg>` 用户不涉及。

### 改了套件源后浏览器跑的还是旧版本

**症状**：修改了 vendored 副本里的源文件（典型路径 `<vendor-dir>/src/*.js`，比如把 `quickstart/.../agentaction/web/agentaction/` 拷贝到自己项目下），刷新页面后 console 仍然输出旧版本的日志，新加的 `console.log` / 改动后的逻辑没生效。

**根因**：pnpm `file:` 依赖在 `install` 时会把源目录复制一份快照到 `node_modules/.pnpm/<pkg>@file+<vendor-dir>/`，后续直接改源文件不会自动同步。同时 Vite 会把依赖预打包到 `node_modules/.vite/`，如果预打包缓存命中的是旧快照，dev server 仍会发旧版。

**解决步骤**：

```bash
# 1. 停掉 dev server（如还在跑）
# 2. 删 pnpm 套件快照
rm -rf node_modules/.pnpm/<pkg>@file+<vendor-dir>
# 3. 删 Vite 预打包缓存
rm -rf node_modules/.vite node_modules/.vite-temp
# 4. 重新 install（让 pnpm 重新做 file: 快照）
pnpm install
# 5. 启 dev server
pnpm run serve
# 6. 浏览器 Cmd+Shift+R / Ctrl+Shift+R 硬刷
```

**验证快照已同步**：

```bash
# 两个 MD5 必须完全一致，否则快照没刷新成功
md5 -q <vendor-dir>/src/zego_ai_agent_action.js \
  node_modules/.pnpm/<pkg>@file+<vendor-dir>/node_modules/<pkg>/src/zego_ai_agent_action.js
```

### console 报错指向套件源，但行号对不上 / 看着像另一个文件

同上，是 Vite 预打包缓存里残留了旧版本 SDK 的 sourcemap。删 `node_modules/.vite` 重启 dev server 即可。
