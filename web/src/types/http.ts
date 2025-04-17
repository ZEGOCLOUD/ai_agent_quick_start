// 通用响应接口
export interface Response {
  code: number;
  message: string;
}

// 智能体id
export interface AgentId {
  agent_id: string;
}

export interface CreateAgentReq extends AgentId {
  agent_name: string; // 智能体名称
}

export interface CreateAgentRes extends Response {
  agent_id: string; // 智能体id
  agent_name: string; // 智能体名称
}

export interface CreateAgentInstanceReq extends AgentId {
  user_id: string;
  room_id: string;
  user_stream_id: string;
  agent_stream_id: string;
  agent_user_id: string;
  messages?: any[];
}

export interface CreateAgentInstanceRes extends Response {
  agent_instance_id: string;
}

export interface DeleteAgentInstanceReq {
  agent_instance_id: string;
}

export interface GetZegoTokenReq {
  user_id: string;
}

export interface GetZegoTokenRes {
  token: string;
  expireTime: number;
  userId: string;
}