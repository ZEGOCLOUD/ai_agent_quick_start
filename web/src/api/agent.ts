import { get, post } from '../utils/http';
import type { Response } from '../types/http';
import config from '../config';

const ActionCmd = {
  GetZegoToken: "/api/zego-token", // 获取ZEGO Token
  Start: "/api/start", // 开始
  StartDigitalHuman: "/api/start-digital-human",
  Stop: "/api/stop", // 停止
}

/**
 * 进房
 */
export function Start(roomId: string, userID: string, userStreamId: string): Promise<Response> {
  return post(ActionCmd.Start, {
    "room_id": roomId,
    "user_id": userID,
    "user_stream_id": userStreamId,
  });
}

/**
 * 数字人视频通话
 */
export function StartDigitalHuman(roomId: string, userID: string, userStreamId: string): Promise<Response> {
  return post(ActionCmd.StartDigitalHuman, {
    "room_id": roomId,
    "user_id": userID,
    "user_stream_id": userStreamId,
    "digital_human_id": config.digitalHumanId,
    "config_id": config.configId
  });
}

/**
 * 退房
 */
export function Stop(agentInstanceId: string): Promise<Response> {
  return post(ActionCmd.Stop, {
    "agent_instance_id": agentInstanceId,
  });
}

/**
 * 获取ZEGO Token
 * @param params 获取ZEGO Token参数
 */
export function GetZegoToken(params: { userId: string; }): Promise<{ token: string }> {
  return get(ActionCmd.GetZegoToken, params);
}