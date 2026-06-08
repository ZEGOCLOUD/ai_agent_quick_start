# Web Demo

Minimal runnable browser demo that shows how to call AI Agent Action APIs through ZEGO Express `callExperimentalAPI` with the [agentaction suite](../README.md).

## Project Layout

```text
web/demo/
└── index.html    # Initializes Express, logs in, and exercises all 5 actions
```

The demo imports `../agentaction/src/*.js` directly, so you do not need to copy the suite source to run it.

## Run

Fill in your `appID / server / token` in `index.html`, and adjust `roomId / userId / agentUserId` as needed. Then open it in a browser:

```bash
open agentaction/web/demo/index.html
```

> Chinese version: [README.md](./README.md)

## Integration Shape

The demo follows the same external wiring as Android/iOS:

- Initialize `ZegoExpressEngine` and log in to the room.
- In `sender`, pass the generated `formatedJson` directly to `zg.callExperimentalAPI(formatedJson)`.
- In `recvExperimentalAPI`, forward the raw `content` string to `client.handleRoomChannelMessage(content)`.
- The page buttons exercise TTS, LLM, Interrupt, StartListening, StopListening, and CancelAll.

For protocol fields, error codes, and defaults, see the [suite README](../README.md).
