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