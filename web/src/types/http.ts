// 通用响应接口
export interface Response {
  code: number;
  message: string;
  renderType?: string;
  agent_id?: string;
  agent_instance_id?: string;
  agent_stream_id?: string;
  agent_user_id?: string;
  digital_human_config?: Record<string, unknown>;
  request_id?: string;
}

export interface GetZegoTokenReq {
  user_id: string;
}

export interface GetZegoTokenRes {
  token: string;
  expireTime: number;
  userId: string;
}

export interface SendAgentInstanceTTSResponse {
  code: number;
  message: string;
  agent_instance_id?: string;
  request_id?: string;
  round?: number;
}
