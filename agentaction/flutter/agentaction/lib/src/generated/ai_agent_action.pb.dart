// This is a generated file - do not edit.
//
// Generated from ai_agent_action.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AgentActionEnvelope extends $pb.GeneratedMessage {
  factory AgentActionEnvelope({
    $core.String? action,
    $core.String? seq,
    $core.List<$core.int>? params,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (seq != null) result.seq = seq;
    if (params != null) result.params = params;
    return result;
  }

  AgentActionEnvelope._();

  factory AgentActionEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgentActionEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentActionEnvelope',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOS(2, _omitFieldNames ? '' : 'seq')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'params', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentActionEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentActionEnvelope copyWith(void Function(AgentActionEnvelope) updates) =>
      super.copyWith((message) => updates(message as AgentActionEnvelope))
          as AgentActionEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentActionEnvelope create() => AgentActionEnvelope._();
  @$core.override
  AgentActionEnvelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgentActionEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentActionEnvelope>(create);
  static AgentActionEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get seq => $_getSZ(1);
  @$pb.TagNumber(2)
  set seq($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get params => $_getN(2);
  @$pb.TagNumber(3)
  set params($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParams() => $_has(2);
  @$pb.TagNumber(3)
  void clearParams() => $_clearField(3);
}

class AgentActionResponse extends $pb.GeneratedMessage {
  factory AgentActionResponse({
    $core.String? action,
    $core.String? seq,
    $core.int? code,
    $core.String? message,
    $core.String? requestId,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (seq != null) result.seq = seq;
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (requestId != null) result.requestId = requestId;
    if (data != null) result.data = data;
    return result;
  }

  AgentActionResponse._();

  factory AgentActionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgentActionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentActionResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOS(2, _omitFieldNames ? '' : 'seq')
    ..aI(3, _omitFieldNames ? '' : 'code')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..aOS(5, _omitFieldNames ? '' : 'requestId')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentActionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentActionResponse copyWith(void Function(AgentActionResponse) updates) =>
      super.copyWith((message) => updates(message as AgentActionResponse))
          as AgentActionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentActionResponse create() => AgentActionResponse._();
  @$core.override
  AgentActionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgentActionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentActionResponse>(create);
  static AgentActionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get seq => $_getSZ(1);
  @$pb.TagNumber(2)
  set seq($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(2);
  @$pb.TagNumber(3)
  set code($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get requestId => $_getSZ(4);
  @$pb.TagNumber(5)
  set requestId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRequestId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get data => $_getN(5);
  @$pb.TagNumber(6)
  set data($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasData() => $_has(5);
  @$pb.TagNumber(6)
  void clearData() => $_clearField(6);
}

class SendAgentInstanceTTSParams extends $pb.GeneratedMessage {
  factory SendAgentInstanceTTSParams({
    $core.String? text,
    $core.bool? addHistory,
    $core.int? interruptMode,
    $core.String? priority,
    $core.String? samePriorityOption,
    $core.bool? enqueueUserSpeech,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (addHistory != null) result.addHistory = addHistory;
    if (interruptMode != null) result.interruptMode = interruptMode;
    if (priority != null) result.priority = priority;
    if (samePriorityOption != null)
      result.samePriorityOption = samePriorityOption;
    if (enqueueUserSpeech != null) result.enqueueUserSpeech = enqueueUserSpeech;
    return result;
  }

  SendAgentInstanceTTSParams._();

  factory SendAgentInstanceTTSParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendAgentInstanceTTSParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendAgentInstanceTTSParams',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'addHistory')
    ..aI(3, _omitFieldNames ? '' : 'interruptMode')
    ..aOS(4, _omitFieldNames ? '' : 'priority')
    ..aOS(5, _omitFieldNames ? '' : 'samePriorityOption')
    ..aOB(6, _omitFieldNames ? '' : 'enqueueUserSpeech')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendAgentInstanceTTSParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendAgentInstanceTTSParams copyWith(
          void Function(SendAgentInstanceTTSParams) updates) =>
      super.copyWith(
              (message) => updates(message as SendAgentInstanceTTSParams))
          as SendAgentInstanceTTSParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendAgentInstanceTTSParams create() => SendAgentInstanceTTSParams._();
  @$core.override
  SendAgentInstanceTTSParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendAgentInstanceTTSParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendAgentInstanceTTSParams>(create);
  static SendAgentInstanceTTSParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  /// optional 标记：让生成器产出 hasAddHistory()。当业务方未显式赋值时，encodeParams 兜底为 API 文档默认值 true；
  /// 业务方显式传 true/false 时按业务方值输出。
  @$pb.TagNumber(2)
  $core.bool get addHistory => $_getBF(1);
  @$pb.TagNumber(2)
  set addHistory($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddHistory() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddHistory() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get interruptMode => $_getIZ(2);
  @$pb.TagNumber(3)
  set interruptMode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInterruptMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearInterruptMode() => $_clearField(3);

  /// optional 标记：业务方未显式赋值时兜底为 "Medium"，避免触发服务端 "Priority is invalid"。
  @$pb.TagNumber(4)
  $core.String get priority => $_getSZ(3);
  @$pb.TagNumber(4)
  set priority($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPriority() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriority() => $_clearField(4);

  /// optional 标记：业务方未显式赋值时兜底为 "ClearAndInterrupt"。
  @$pb.TagNumber(5)
  $core.String get samePriorityOption => $_getSZ(4);
  @$pb.TagNumber(5)
  set samePriorityOption($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSamePriorityOption() => $_has(4);
  @$pb.TagNumber(5)
  void clearSamePriorityOption() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enqueueUserSpeech => $_getBF(5);
  @$pb.TagNumber(6)
  set enqueueUserSpeech($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnqueueUserSpeech() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnqueueUserSpeech() => $_clearField(6);
}

class SendAgentInstanceLLMParams extends $pb.GeneratedMessage {
  factory SendAgentInstanceLLMParams({
    $core.String? text,
    $core.String? systemPrompt,
    $core.bool? addQuestionToHistory,
    $core.bool? addAnswerToHistory,
    $core.String? priority,
    $core.String? samePriorityOption,
    $core.bool? enqueueUserSpeech,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (addQuestionToHistory != null)
      result.addQuestionToHistory = addQuestionToHistory;
    if (addAnswerToHistory != null)
      result.addAnswerToHistory = addAnswerToHistory;
    if (priority != null) result.priority = priority;
    if (samePriorityOption != null)
      result.samePriorityOption = samePriorityOption;
    if (enqueueUserSpeech != null) result.enqueueUserSpeech = enqueueUserSpeech;
    return result;
  }

  SendAgentInstanceLLMParams._();

  factory SendAgentInstanceLLMParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendAgentInstanceLLMParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendAgentInstanceLLMParams',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'systemPrompt')
    ..aOB(3, _omitFieldNames ? '' : 'addQuestionToHistory')
    ..aOB(4, _omitFieldNames ? '' : 'addAnswerToHistory')
    ..aOS(5, _omitFieldNames ? '' : 'priority')
    ..aOS(6, _omitFieldNames ? '' : 'samePriorityOption')
    ..aOB(7, _omitFieldNames ? '' : 'enqueueUserSpeech')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendAgentInstanceLLMParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendAgentInstanceLLMParams copyWith(
          void Function(SendAgentInstanceLLMParams) updates) =>
      super.copyWith(
              (message) => updates(message as SendAgentInstanceLLMParams))
          as SendAgentInstanceLLMParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendAgentInstanceLLMParams create() => SendAgentInstanceLLMParams._();
  @$core.override
  SendAgentInstanceLLMParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendAgentInstanceLLMParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendAgentInstanceLLMParams>(create);
  static SendAgentInstanceLLMParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get systemPrompt => $_getSZ(1);
  @$pb.TagNumber(2)
  set systemPrompt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSystemPrompt() => $_has(1);
  @$pb.TagNumber(2)
  void clearSystemPrompt() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get addQuestionToHistory => $_getBF(2);
  @$pb.TagNumber(3)
  set addQuestionToHistory($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddQuestionToHistory() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddQuestionToHistory() => $_clearField(3);

  /// optional 标记：让生成器产出 hasAddAnswerToHistory()。当业务方未显式赋值时，encodeParams 兜底为 API 文档默认值 true；
  /// 业务方显式传 true/false 时按业务方值输出。
  @$pb.TagNumber(4)
  $core.bool get addAnswerToHistory => $_getBF(3);
  @$pb.TagNumber(4)
  set addAnswerToHistory($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddAnswerToHistory() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddAnswerToHistory() => $_clearField(4);

  /// optional 标记：业务方未显式赋值时兜底为 "Medium"。
  @$pb.TagNumber(5)
  $core.String get priority => $_getSZ(4);
  @$pb.TagNumber(5)
  set priority($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => $_clearField(5);

  /// optional 标记：业务方未显式赋值时兜底为 "ClearAndInterrupt"。
  @$pb.TagNumber(6)
  $core.String get samePriorityOption => $_getSZ(5);
  @$pb.TagNumber(6)
  set samePriorityOption($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSamePriorityOption() => $_has(5);
  @$pb.TagNumber(6)
  void clearSamePriorityOption() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get enqueueUserSpeech => $_getBF(6);
  @$pb.TagNumber(7)
  set enqueueUserSpeech($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEnqueueUserSpeech() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnqueueUserSpeech() => $_clearField(7);
}

class InterruptAgentInstanceParams extends $pb.GeneratedMessage {
  factory InterruptAgentInstanceParams() => create();

  InterruptAgentInstanceParams._();

  factory InterruptAgentInstanceParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InterruptAgentInstanceParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InterruptAgentInstanceParams',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptAgentInstanceParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptAgentInstanceParams copyWith(
          void Function(InterruptAgentInstanceParams) updates) =>
      super.copyWith(
              (message) => updates(message as InterruptAgentInstanceParams))
          as InterruptAgentInstanceParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InterruptAgentInstanceParams create() =>
      InterruptAgentInstanceParams._();
  @$core.override
  InterruptAgentInstanceParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InterruptAgentInstanceParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InterruptAgentInstanceParams>(create);
  static InterruptAgentInstanceParams? _defaultInstance;
}

/// StartListening / StopListening 新增 sequence（int64）字段，对应 API 文档 Body 中的 Sequence 参数。
/// 业务方通过自增 Sequence 实现"AI Agent 后台只处理 Sequence 最新的请求"的效果。
class StartListeningParams extends $pb.GeneratedMessage {
  factory StartListeningParams({
    $core.String? userId,
    $fixnum.Int64? sequence,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (sequence != null) result.sequence = sequence;
    return result;
  }

  StartListeningParams._();

  factory StartListeningParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartListeningParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartListeningParams',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aInt64(2, _omitFieldNames ? '' : 'sequence')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartListeningParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartListeningParams copyWith(void Function(StartListeningParams) updates) =>
      super.copyWith((message) => updates(message as StartListeningParams))
          as StartListeningParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartListeningParams create() => StartListeningParams._();
  @$core.override
  StartListeningParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartListeningParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartListeningParams>(create);
  static StartListeningParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// 客户端自增序列号；proto3 int64 默认 0 表示不传（与 API 文档"不传则按后台接收顺序处理"语义一致）。
  @$pb.TagNumber(2)
  $fixnum.Int64 get sequence => $_getI64(1);
  @$pb.TagNumber(2)
  set sequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequence() => $_clearField(2);
}

/// StopListening 的 sequence 必须与对应 StartListening 的 sequence 相同，实现开始/结束配对。
class StopListeningParams extends $pb.GeneratedMessage {
  factory StopListeningParams({
    $core.String? userId,
    $fixnum.Int64? sequence,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (sequence != null) result.sequence = sequence;
    return result;
  }

  StopListeningParams._();

  factory StopListeningParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopListeningParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopListeningParams',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'zego.aiagent.action'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aInt64(2, _omitFieldNames ? '' : 'sequence')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopListeningParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopListeningParams copyWith(void Function(StopListeningParams) updates) =>
      super.copyWith((message) => updates(message as StopListeningParams))
          as StopListeningParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopListeningParams create() => StopListeningParams._();
  @$core.override
  StopListeningParams createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopListeningParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopListeningParams>(create);
  static StopListeningParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sequence => $_getI64(1);
  @$pb.TagNumber(2)
  set sequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequence() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
