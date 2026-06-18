// This is a generated file - do not edit.
//
// Generated from ai_agent_action.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use agentActionEnvelopeDescriptor instead')
const AgentActionEnvelope$json = {
  '1': 'AgentActionEnvelope',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'seq', '3': 2, '4': 1, '5': 9, '10': 'seq'},
    {'1': 'params', '3': 3, '4': 1, '5': 12, '10': 'params'},
  ],
};

/// Descriptor for `AgentActionEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentActionEnvelopeDescriptor = $convert.base64Decode(
    'ChNBZ2VudEFjdGlvbkVudmVsb3BlEhYKBmFjdGlvbhgBIAEoCVIGYWN0aW9uEhAKA3NlcRgCIA'
    'EoCVIDc2VxEhYKBnBhcmFtcxgDIAEoDFIGcGFyYW1z');

@$core.Deprecated('Use agentActionResponseDescriptor instead')
const AgentActionResponse$json = {
  '1': 'AgentActionResponse',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'seq', '3': 2, '4': 1, '5': 9, '10': 'seq'},
    {'1': 'code', '3': 3, '4': 1, '5': 5, '10': 'code'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {'1': 'request_id', '3': 5, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'data', '3': 6, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `AgentActionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentActionResponseDescriptor = $convert.base64Decode(
    'ChNBZ2VudEFjdGlvblJlc3BvbnNlEhYKBmFjdGlvbhgBIAEoCVIGYWN0aW9uEhAKA3NlcRgCIA'
    'EoCVIDc2VxEhIKBGNvZGUYAyABKAVSBGNvZGUSGAoHbWVzc2FnZRgEIAEoCVIHbWVzc2FnZRId'
    'CgpyZXF1ZXN0X2lkGAUgASgJUglyZXF1ZXN0SWQSEgoEZGF0YRgGIAEoDFIEZGF0YQ==');

@$core.Deprecated('Use sendAgentInstanceTTSParamsDescriptor instead')
const SendAgentInstanceTTSParams$json = {
  '1': 'SendAgentInstanceTTSParams',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'add_history',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'addHistory',
      '17': true
    },
    {'1': 'interrupt_mode', '3': 3, '4': 1, '5': 5, '10': 'interruptMode'},
    {
      '1': 'priority',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'priority',
      '17': true
    },
    {
      '1': 'same_priority_option',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'samePriorityOption',
      '17': true
    },
    {
      '1': 'enqueue_user_speech',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'enqueueUserSpeech'
    },
  ],
  '8': [
    {'1': '_add_history'},
    {'1': '_priority'},
    {'1': '_same_priority_option'},
  ],
};

/// Descriptor for `SendAgentInstanceTTSParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendAgentInstanceTTSParamsDescriptor = $convert.base64Decode(
    'ChpTZW5kQWdlbnRJbnN0YW5jZVRUU1BhcmFtcxISCgR0ZXh0GAEgASgJUgR0ZXh0EiQKC2FkZF'
    '9oaXN0b3J5GAIgASgISABSCmFkZEhpc3RvcnmIAQESJQoOaW50ZXJydXB0X21vZGUYAyABKAVS'
    'DWludGVycnVwdE1vZGUSHwoIcHJpb3JpdHkYBCABKAlIAVIIcHJpb3JpdHmIAQESNQoUc2FtZV'
    '9wcmlvcml0eV9vcHRpb24YBSABKAlIAlISc2FtZVByaW9yaXR5T3B0aW9uiAEBEi4KE2VucXVl'
    'dWVfdXNlcl9zcGVlY2gYBiABKAhSEWVucXVldWVVc2VyU3BlZWNoQg4KDF9hZGRfaGlzdG9yeU'
    'ILCglfcHJpb3JpdHlCFwoVX3NhbWVfcHJpb3JpdHlfb3B0aW9u');

@$core.Deprecated('Use sendAgentInstanceLLMParamsDescriptor instead')
const SendAgentInstanceLLMParams$json = {
  '1': 'SendAgentInstanceLLMParams',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'system_prompt', '3': 2, '4': 1, '5': 9, '10': 'systemPrompt'},
    {
      '1': 'add_question_to_history',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'addQuestionToHistory'
    },
    {
      '1': 'add_answer_to_history',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'addAnswerToHistory',
      '17': true
    },
    {
      '1': 'priority',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'priority',
      '17': true
    },
    {
      '1': 'same_priority_option',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'samePriorityOption',
      '17': true
    },
    {
      '1': 'enqueue_user_speech',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'enqueueUserSpeech'
    },
  ],
  '8': [
    {'1': '_add_answer_to_history'},
    {'1': '_priority'},
    {'1': '_same_priority_option'},
  ],
};

/// Descriptor for `SendAgentInstanceLLMParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendAgentInstanceLLMParamsDescriptor = $convert.base64Decode(
    'ChpTZW5kQWdlbnRJbnN0YW5jZUxMTVBhcmFtcxISCgR0ZXh0GAEgASgJUgR0ZXh0EiMKDXN5c3'
    'RlbV9wcm9tcHQYAiABKAlSDHN5c3RlbVByb21wdBI1ChdhZGRfcXVlc3Rpb25fdG9faGlzdG9y'
    'eRgDIAEoCFIUYWRkUXVlc3Rpb25Ub0hpc3RvcnkSNgoVYWRkX2Fuc3dlcl90b19oaXN0b3J5GA'
    'QgASgISABSEmFkZEFuc3dlclRvSGlzdG9yeYgBARIfCghwcmlvcml0eRgFIAEoCUgBUghwcmlv'
    'cml0eYgBARI1ChRzYW1lX3ByaW9yaXR5X29wdGlvbhgGIAEoCUgCUhJzYW1lUHJpb3JpdHlPcH'
    'Rpb26IAQESLgoTZW5xdWV1ZV91c2VyX3NwZWVjaBgHIAEoCFIRZW5xdWV1ZVVzZXJTcGVlY2hC'
    'GAoWX2FkZF9hbnN3ZXJfdG9faGlzdG9yeUILCglfcHJpb3JpdHlCFwoVX3NhbWVfcHJpb3JpdH'
    'lfb3B0aW9u');

@$core.Deprecated('Use interruptAgentInstanceParamsDescriptor instead')
const InterruptAgentInstanceParams$json = {
  '1': 'InterruptAgentInstanceParams',
};

/// Descriptor for `InterruptAgentInstanceParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interruptAgentInstanceParamsDescriptor =
    $convert.base64Decode('ChxJbnRlcnJ1cHRBZ2VudEluc3RhbmNlUGFyYW1z');

@$core.Deprecated('Use startListeningParamsDescriptor instead')
const StartListeningParams$json = {
  '1': 'StartListeningParams',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 3, '10': 'sequence'},
  ],
};

/// Descriptor for `StartListeningParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startListeningParamsDescriptor = $convert.base64Decode(
    'ChRTdGFydExpc3RlbmluZ1BhcmFtcxIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSGgoIc2VxdW'
    'VuY2UYAiABKANSCHNlcXVlbmNl');

@$core.Deprecated('Use stopListeningParamsDescriptor instead')
const StopListeningParams$json = {
  '1': 'StopListeningParams',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 3, '10': 'sequence'},
  ],
};

/// Descriptor for `StopListeningParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopListeningParamsDescriptor = $convert.base64Decode(
    'ChNTdG9wTGlzdGVuaW5nUGFyYW1zEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIaCghzZXF1ZW'
    '5jZRgCIAEoA1IIc2VxdWVuY2U=');
