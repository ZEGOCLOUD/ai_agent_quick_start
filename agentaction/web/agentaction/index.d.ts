export type AgentActionCode = number | string;

export interface ZegoAIAgentActionSendParams {
  roomId: string;
  msgType: number;
  msg_type?: number;
  seq: string;
  msgContent: string;
  msg_content?: string;
  userList: string[];
  user_list?: string[];
}

export interface ZegoAIAgentActionSendResult {
  errorCode: number;
  seq: string;
}

export interface ZegoAIAgentActionResponse {
  action: string;
  seq: string;
  code: number;
  message: string;
  requestId: string;
  data?: unknown;
  rawMessage: string;
}

export interface ZegoAIAgentActionError extends Error {
  seq: string;
  action: string;
  code: AgentActionCode;
}

export interface SendAgentInstanceTTSParams {
  setText(value: string): this;
  getText(): string;
  setAddHistory(value: boolean): this;
  getAddHistory(): boolean;
  setPriority(value: string): this;
  getPriority(): string;
  setSamePriorityOption(value: string): this;
  getSamePriorityOption(): string;
  setInterruptMode(value: number): this;
  getInterruptMode(): number;
  setEnqueueUserSpeech(value: boolean): this;
  getEnqueueUserSpeech(): boolean;
}

export interface SendAgentInstanceLLMParams {
  setText(value: string): this;
  getText(): string;
  setSystemPrompt(value: string): this;
  getSystemPrompt(): string;
  setAddQuestionToHistory(value: boolean): this;
  getAddQuestionToHistory(): boolean;
  setAddAnswerToHistory(value: boolean): this;
  getAddAnswerToHistory(): boolean;
  setPriority(value: string): this;
  getPriority(): string;
  setSamePriorityOption(value: string): this;
  getSamePriorityOption(): string;
  setEnqueueUserSpeech(value: boolean): this;
  getEnqueueUserSpeech(): boolean;
}

export interface StartListeningParams {
  setUserId(value: string): this;
  getUserId(): string;
}

export interface StopListeningParams {
  setUserId(value: string): this;
  getUserId(): string;
}

export interface ZegoAIAgentActionClientInstance {
  readonly roomId: string;
  readonly agentUserId: string;
  readonly userId: string;
  sendAgentInstanceTTS(params: SendAgentInstanceTTSParams, options?: { timeoutMs?: number }): Promise<ZegoAIAgentActionResponse>;
  sendAgentInstanceLLM(params: SendAgentInstanceLLMParams, options?: { timeoutMs?: number }): Promise<ZegoAIAgentActionResponse>;
  interruptAgentInstance(options?: { timeoutMs?: number }): Promise<ZegoAIAgentActionResponse>;
  startListening(params: StartListeningParams, options?: { timeoutMs?: number }): Promise<ZegoAIAgentActionResponse>;
  stopListening(params: StopListeningParams, options?: { timeoutMs?: number }): Promise<ZegoAIAgentActionResponse>;
  handleRoomChannelMessage(payload: unknown): boolean;
  cancelAll(message?: string): void;
}

export interface ZegoAIAgentActionLoggerInstance {
  installSink(handler: (level: number, label: string, line: string) => void): void;
  setLevel(level: number): void;
  debug(message: string): void;
  info(message: string): void;
  warn(message: string): void;
  error(message: string): void;
  LEVEL_DEBUG: number;
  LEVEL_INFO: number;
  LEVEL_WARN: number;
  LEVEL_ERROR: number;
}

export interface ZegoAIAgentActionModule {
  ZegoAIAgentActionClient: new (options: {
    roomId: string;
    agentUserId: string;
    userId: string;
    deviceId?: string;
    timeoutMs?: number;
    sender: (params: ZegoAIAgentActionSendParams, formatedJson: Record<string, unknown>) => Promise<ZegoAIAgentActionSendResult>;
    onResponse?: (response: ZegoAIAgentActionResponse) => void;
    onError?: (error: ZegoAIAgentActionError) => void;
  }) => ZegoAIAgentActionClientInstance;
  ErrorCodes: {
    SUCCESS: number;
    TIMEOUT: number;
    SEND_FAILED: number;
    CANCELED: number;
  };
  Protobuf: {
    SendAgentInstanceTTSParams: new () => SendAgentInstanceTTSParams;
    SendAgentInstanceLLMParams: new () => SendAgentInstanceLLMParams;
    StartListeningParams: new () => StartListeningParams;
    StopListeningParams: new () => StopListeningParams;
  };
  ZegoAIAgentActionLogger: ZegoAIAgentActionLoggerInstance;
}

declare const ZegoAIAgentAction: ZegoAIAgentActionModule;
export default ZegoAIAgentAction;
