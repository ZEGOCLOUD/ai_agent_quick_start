// 通用响应接口
export interface Response {
  code: number;
  message: string;
  renderType?: string;
  agent_instance_id?: string;
  agent_user_id?: string;
  agent_name?: string;
}

export interface GetZegoTokenReq {
  user_id: string;
}

export interface GetZegoTokenRes {
  token: string;
  expireTime: number;
  userId: string;
}