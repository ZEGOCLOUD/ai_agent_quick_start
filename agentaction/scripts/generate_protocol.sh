#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROTO="$ROOT_DIR/proto/ai_agent_action.proto"

export PATH="$HOME/.pub-cache/bin:$HOME/.cache/dart/pub/bin:/opt/homebrew/bin:$ROOT_DIR/web/agentaction/node_modules/.bin:$ROOT_DIR/web/node_modules/.bin:/tmp/agentaction-protoc-tools/node_modules/.bin:$PATH"

missing=()
for tool in protoc protoc-gen-js protoc-gen-dart protoc-gen-swift; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing+=("$tool")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing protoc tools: ${missing[*]}" >&2
  echo "Install hints:" >&2
  echo "  dart pub global activate protoc_plugin" >&2
  echo "  brew install swift-protobuf" >&2
  echo "  npm install --prefix /tmp/agentaction-protoc-tools protoc-gen-js" >&2
  exit 1
fi

mkdir -p \
  "$ROOT_DIR/web/agentaction/src/generated" \
  "$ROOT_DIR/flutter/agentaction/lib/src/generated" \
  "$ROOT_DIR/android/agentaction/src/main/java" \
  "$ROOT_DIR/ios_swift/agentaction/Sources/ZegoAIAgentAction/Generated" \
  "$ROOT_DIR/ios_oc/agentaction/Sources/ZegoAIAgentActionObjC/Generated"

protoc \
  --proto_path="$ROOT_DIR/proto" \
  --js_out=import_style=commonjs,binary:"$ROOT_DIR/web/agentaction/src/generated" \
  --dart_out="$ROOT_DIR/flutter/agentaction/lib/src/generated" \
  --java_out="$ROOT_DIR/android/agentaction/src/main/java" \
  --swift_opt=Visibility=Public \
  --swift_out="$ROOT_DIR/ios_swift/agentaction/Sources/ZegoAIAgentAction/Generated" \
  --objc_out="$ROOT_DIR/ios_oc/agentaction/Sources/ZegoAIAgentActionObjC/Generated" \
  "$PROTO"

echo "Generated protocol classes from $PROTO"
