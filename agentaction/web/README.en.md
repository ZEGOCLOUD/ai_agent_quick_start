# Web Usage

This folder provides the Web AI Agent Action client suite. It controls AI Agent instances through ZEGO Express room channel messages.

## Directory Layout

- `agentaction/`: copyable Web suite source.
- `demo/`: runnable browser demo. See [demo/README.md](./demo/README.md).

> Chinese version: [README.md](./README.md)

## Suite Structure

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

You can read the layers like this:

- `index.js`: the public runtime entry for the suite. Bundlers, CommonJS projects, and TS projects should import from here first.
- `index.d.ts`: type declarations for TypeScript. It does not run at runtime; it only describes the suite surface to the IDE and compiler.
- `src/zego_ai_agent_action.js`: the real implementation entry. `index.js` simply re-exports this file.
- `src/defines.js`: constants for the Web Express experimental API methods, keys, and error codes.
- `src/logger.js`: internal logging helper.
- `src/generated/ai_agent_action_pb.js`: generated protobuf parameter classes used by CommonJS and bundler scenarios.

## Integration

### 1. Copy the suite

Copy `web/agentaction` into your Web project.

- Direct browser `<script>` usage does not need extra installation.
- For CommonJS, bundlers, or TypeScript projects, install the dependency in the copied folder:

```bash
cd web/agentaction
npm install
```

### 2. Load the suite

Use one of the following loading styles.

#### Option A: direct browser scripts

Load scripts in this order:

```html
<script src="./agentaction/src/defines.js"></script>
<script src="./agentaction/src/logger.js"></script>
<script src="./agentaction/src/zego_ai_agent_action.js"></script>
```

After loading, the suite is exposed on:

```js
window.ZegoAIAgentAction
```

This is the best fit for a plain browser demo or a directly opened HTML page.

#### Option B: project-style import

For CommonJS, bundlers, or TypeScript projects, prefer the package entry:

```js
const ZegoAIAgentAction = require('./agentaction');
```

or:

```ts
import ZegoAIAgentAction from './agentaction';
```

This works because:

- `"main": "index.js"` makes `index.js` the runtime entry
- `"types": "index.d.ts"` makes `index.d.ts` the type entry
- `index.js` then forwards to `src/zego_ai_agent_action.js`

So the business project usually does not need to import `src/*.js` paths directly.

### 3. Implement the Sender

The `sender` receives the suite metadata plus one request object named `formatedJson`. The name is kept for continuity, but on Web it is actually the object payload that can be passed directly into Express.

Web Express experimental APIs are not fully identical to the native platforms:

- the send method is `sendRoomChannelMessage`
- the receive callback method is `onRecvRoomChannelMessage`
- Web `recvExperimentalAPI` usually delivers an object payload, not the native-style JSON string
- Web does not provide a send callback, so send success is mainly determined by the `callExperimentalAPI` call itself, and business completion still depends on the room-message response or timeout

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

`formatedJson` looks like:

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

### 4. Send Actions

```js
const params = new ZegoAIAgentAction.Protobuf.SendAgentInstanceTTSParams();
params.setText('你好');
params.setAddHistory(true);
params.setPriority('Medium');
params.setSamePriorityOption('ClearAndInterrupt');

const response = await client.sendAgentInstanceTTS(params);
console.log('tts ok seq=', response.seq);
```

The other four methods are symmetrical:

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

`text` is limited to 300 characters. The default timeout is 5 seconds and can be overridden with the method `options.timeoutMs`.

### 5. Forward Room Channel Callbacks

Forward the raw `recvExperimentalAPI` payload object to `client.handleRoomChannelMessage(payload)`. The suite decides whether the payload is an AI Agent Action message:

- AI Agent Action response: parse `Action/Seq/Code/Message/RequestId/Data` and trigger `onResponse` or `onError`; returns `true`.
- Web has no send callback; request completion is determined by the business response or timeout.
- Other messages return `false`.

```js
zg.on('recvExperimentalAPI', (payload) => {
  const consumed = client.handleRoomChannelMessage(payload);
  if (consumed) {
    console.log('agentaction message consumed');
  }
});
```

Some Web Express versions require explicitly enabling experimental API room channel receive:

```js
zg.callExperimentalAPI({
  method: ZegoAIAgentActionDefines.ExpressMethods.onRecvRoomChannelMessage,
  params: {}
});
```

### 6. Cancel and Clean Up

```js
client.cancelAll('logout');
```

### 7. Logging

Suite-internal logs include a timestamp and a `[DEBUG]/[INFO]/[WARN]/[ERROR]` prefix. `ZegoAIAgentActionLogger` is available either as a browser global or as a named property on the main module entry.

#### Option A: Direct `<script>` include

```js
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
ZegoAIAgentActionLogger.installSink((level, label, message) => {
  console.log('[AgentAction]', message);
});
```

#### Option B: Bundler / TypeScript project

Replace `<pkg>` with the actual npm package name.

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

## Error Codes

`ZegoAIAgentActionDefines.ErrorCodes`:

| Constant | Value | Trigger |
|---|---:|---|
| `SUCCESS` | `0` | Suite-level success |
| `TIMEOUT` | `-1` | No AI Agent Action response within the default 5 seconds |
| `SEND_FAILED` | `-2` | `sender` throws or Express send fails |
| `CANCELED` | `-3` | `client.cancelAll()` is called |

## Run Demo

Open `web/demo/index.html` in a browser. Before running it, fill in your `appID / server / token`, and adjust `roomId / userId / agentUserId` as needed.

## Troubleshooting

> The following only applies if you are vendoring the suite into your own project as a pnpm `file:` dependency and modifying its source. Plain `npm i <pkg>` users are not affected.

### Source changes not reflected at runtime

**Symptom**: You edit files under the vendored copy (typical path `<vendor-dir>/src/*.js`, e.g. the copy of `quickstart/.../agentaction/web/agentaction/` placed inside your own project) but the browser keeps running the old version — newly added `console.log` calls or modified logic do not take effect.

**Root cause**: pnpm `file:` dependencies copy a snapshot into `node_modules/.pnpm/<pkg>@file+<vendor-dir>/` at install time, and the snapshot is not auto-refreshed when you edit the source. Vite additionally pre-bundles dependencies into `node_modules/.vite/`, so even after a `pnpm install` the dev server may still serve the cached old build.

**Fix**:

```bash
# 1. Stop dev server (if running)
# 2. Remove pnpm snapshot
rm -rf node_modules/.pnpm/<pkg>@file+<vendor-dir>
# 3. Remove Vite pre-bundle cache
rm -rf node_modules/.vite node_modules/.vite-temp
# 4. Re-install (rebuilds the file: snapshot)
pnpm install
# 5. Start dev server
pnpm run serve
# 6. Hard-reload the browser (Cmd+Shift+R / Ctrl+Shift+R)
```

**Verify the snapshot is in sync**:

```bash
# Both MD5s must be identical. If they differ, the snapshot was not refreshed.
md5 -q <vendor-dir>/src/zego_ai_agent_action.js \
  node_modules/.pnpm/<pkg>@file+<vendor-dir>/node_modules/<pkg>/src/zego_ai_agent_action.js
```

### Stack traces point at suite source but the line numbers are off

Same root cause as above — the Vite pre-bundle cache is serving stale SDK source maps. Delete `node_modules/.vite` and restart the dev server.
