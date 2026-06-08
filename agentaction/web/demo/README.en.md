# Web Demo

Minimal runnable browser demo that shows how to call AI Agent Action APIs through ZEGO Express `callExperimentalAPI` with the [agentaction suite](../README.md).

## Project Layout

```text
web/demo/
└── index.html    # Initializes Express, logs in, and exercises all 5 actions
```

The demo imports `../agentaction/src/*.js` directly, so you can run it without copying another suite folder.

This is intentional: the demo uses the direct browser-loading path so `index.html` can be opened and verified immediately. For a TS, Vite, or Webpack project, prefer the package-entry path described in the suite README: `agentaction/index.js + index.d.ts`.

## Run

Fill in your `appID / server / token` in `index.html`, and adjust `roomId / userId / agentUserId` as needed. Then open it in a browser:

```bash
open agentaction/web/demo/index.html
```

> Chinese version: [README.md](./README.md)

## Integration Shape

The demo follows the same business flow as Android/iOS, but the Web experimental API method names and callback payload shape differ from the native platforms:

- Initialize `ZegoExpressEngine` and log in to the room.
- In `sender`, pass the suite-provided `formatedJson` object directly to `zg.callExperimentalAPI(...)`.
- In `recvExperimentalAPI`, forward the raw `payload` object to `client.handleRoomChannelMessage(payload)`.
- The page buttons exercise TTS, LLM, Interrupt, StartListening, StopListening, and CancelAll.

Additional Web notes:

- the Web experimental API method names are `sendRoomChannelMessage / onRecvRoomChannelMessage`
- unlike native platforms, Web has no send callback
- so "send succeeded" is mainly determined by whether `callExperimentalAPI` throws, while the business result still depends on the agent reply or timeout

## How Demo Relates to the Suite Entry

You can read the split like this:

- Demo: directly loads `src/defines.js`, `src/logger.js`, and `src/zego_ai_agent_action.js`
- Public suite runtime entry: `agentaction/index.js`
- TypeScript type entry: `agentaction/index.d.ts`

In other words:

- the demo is optimized for direct browser verification
- `index.js / index.d.ts` are optimized for integration into project-based apps

For protocol fields, error codes, and defaults, see the [suite README](../README.md).
