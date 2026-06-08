# Flutter Demo

Minimal runnable Flutter demo that shows how to call AI Agent Action APIs through ZEGO Express `callExperimentalAPI` with the [agentaction suite](../README.md).

## Project Layout

```text
flutter/demo/
├── pubspec.yaml              # Depends on ../agentaction and zego_express_engine
└── lib/main.dart             # Initializes Express, logs in, and exercises all 5 actions
```

The demo depends on `../agentaction` by path, so you do not need to copy the suite source to run it.

## Run

Fill in your `appID` and `appSign` in `lib/main.dart`, and adjust `roomId / userId / agentUserId` as needed.

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```

> Chinese version: [README.md](./README.md)

## Integration Shape

The demo follows the same external wiring as Android/iOS:

- Initialize `ZegoExpressEngine` and log in to the room.
- In `sender`, pass the generated `formatedJson` directly to `ZegoExpressEngine.instance.callExperimentalAPI(formatedJson)`.
- In `ZegoExpressEngine.onRecvExperimentalAPI`, forward the raw `content` string to `client.handleRoomChannelMessage(content)`.
- The UI buttons exercise TTS, LLM, Interrupt, StartListening, StopListening, and CancelAll.

For protocol fields, error codes, and defaults, see the [suite README](../README.md).
