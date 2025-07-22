// 通用响应接口
export interface Response {
  code: number;
  message: string;
}

export interface GetZegoTokenReq {
  user_id: string;
}

export interface GetZegoTokenRes {
  token: string;
  expireTime: number;
  userId: string;
}

export interface GetAgentInfoRes {
  code: number;
  message: string;
  agent_id: string;
  agent_name: string;
  robot_id: string;
  is_new_robot_registration: boolean;
}

export interface StartRes {
  code: number;
  message: string;
  agent_id: string;
  agent_name: string;
  agent_instance_id:string;
  robot_id: string;
  is_new_robot_registration: boolean;
}