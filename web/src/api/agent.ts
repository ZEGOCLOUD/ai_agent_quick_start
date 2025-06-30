import { get, post } from '../utils/http';
import type { Response } from '../types/http';

const ActionCmd = {
  GetZegoToken: "/api/zego-token", // 获取ZEGO Token
  Start: "/api/start", // 开始
  StartDigitalHuman: "/api/start-digital-human",
  Stop: "/api/stop", // 停止
}

/**
 * 进房
 */
export function Start(): Promise<Response> {
  return post(ActionCmd.Start);
}

/**
 * 数字人视频通话
 */
export function StartDigitalHuman(): Promise<Response> {
  return post(ActionCmd.StartDigitalHuman, {
    "digital_human_id":"20be9bfb-ef6b-4d63-8c3b-1f20077599c5",
    "config_id":"web"
  });
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