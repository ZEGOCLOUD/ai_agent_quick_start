// 通用响应接口
export interface Response<T = any> {
  Code: number;
  Data: T;
  Message: string;
  RequestId: string;
}

// 智能体id
export interface AgentId {
  AgentId: string;
}

export interface LLM {
  Url: string; // LLM 回调地址，要求与 OpenAI 协议兼容。
  ApiKey: string; // LLM 校验 api key。
  Model: string; // LLM 模型名称。
  SystemPrompt?: string; // 系统提示词。
  Temperature?: number;
  TopP?: number;
  Params?: Object; // 扩展参数
}

export interface FilterText {
  BeginCharacters: string;
  EndCharacters: string;
}

export interface TTS {
  Vendor: string; // 提供商
  Params: Object; // 扩展参数
  FilterText?: FilterText[]; // 过滤文本
  PauseDuration?: number;
}

export interface ASR {
  HotWord?: string; // 临时热词
  Params?: Object; // 扩展参数
}

// agentConfig定义
export interface AgentConfig {
  Name?: string; // Agent名称
  LLM: LLM; // LLM 配置
  TTS: TTS; // TTS 配置
  ASR?: ASR; // ASR 配置
  ExtensionParams?: Object; // 扩展参数
}

export interface CreateAgentReq extends AgentId {
  AgentConfig: AgentConfig;
}

export interface CreateAgentInstanceReq {
  UserId: string;
  AgentId: string;
  RtcInfo: RtcInfo;
  MessageHistory?: MessageHistory;
}

export interface CreateAgentInstanceRes {
  AgentInstanceId: string;
}

interface RtcInfo {
  RoomId: string;
  AgentStreamId: string;
  AgentUserId: string;
  UserStreamId: string;
  WelcomeMessage?: string;
}

interface MessageHistory {
  SyncMode?: number;
  Messages?: Message[];
  ZimRobotId?: string;
}

interface Message {
  Role: string;
  Content: string;
}

export interface CreateAgentInstanceRes {
  AgentInstanceId: string;
}

export interface DeleteAgentInstanceReq {
  AgentInstanceId: string;
}
