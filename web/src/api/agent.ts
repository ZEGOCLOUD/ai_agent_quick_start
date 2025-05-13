import { get, post } from '../utils/http';
import type { Response } from '../types/http';

const ActionCmd = {
  GetZegoToken: "/api/zego-token", // 获取ZEGO Token
  Start: "/api/start", // 开始
  Stop: "/api/stop", // 停止
}

/**
 * 进房
 */
export function Start(): Promise<Response> {
  return post(ActionCmd.Start);
}


/**
 * 退房
 */
export function Stop(): Promise<Response> {
  return post(ActionCmd.Stop);
}

/**
 * 获取ZEGO Token
 * @param params 获取ZEGO Token参数
 */
export function GetZegoToken(params: { userId: string; }): Promise<{ token: string }> {
  return get(ActionCmd.GetZegoToken, params);
}