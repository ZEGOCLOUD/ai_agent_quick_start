import { get, post } from '../utils/http';
import type { Response } from '../types/http';
import config from '../config';

const ActionCmd = {
  GetZegoToken: "/api/zego-token", // 获取ZEGO Token
  Start: "/api/start", // 开始
  StartDigitalHuman: "/api/start-digital-human",
  StartLiveDigitalHuman: "/api/start-live-digital-human",
  Stop: "/api/stop", // 停止
}

export interface StartLiveDigitalHumanParams {
  roomId?: string;
  cdnUrl?: string;
  agentId?: string;
  tts?: Record<string, unknown>;
  callbackConfig?: Record<string, unknown>;
  advancedConfig?: Record<string, unknown>;
  extensionParams?: Record<string, unknown>;
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
    "digital_human_id": config.digitalHuman.id,
    "config_id": config.digitalHuman.configId
  });
}

/**
 * 播报数字人
 */
export function StartLiveDigitalHuman(params: StartLiveDigitalHumanParams): Promise<Response> {
  const data: Record<string, unknown> = {
    "digital_human_id": config.digitalHuman.id,
    "config_id": config.digitalHuman.configId,
  };

  if (params.roomId) {
    data.room_id = params.roomId;
  }
  if (params.cdnUrl) {
    data.cdn_url = params.cdnUrl;
  }
  if (params.agentId) {
    data.agent_id = params.agentId;
  }
  if (params.tts) {
    data.tts = params.tts;
  }
  if (params.callbackConfig) {
    data.callback_config = params.callbackConfig;
  }
  if (params.advancedConfig) {
    data.advanced_config = params.advancedConfig;
  }
  if (params.extensionParams) {
    data.extension_params = params.extensionParams;
  }

  return post(ActionCmd.StartLiveDigitalHuman, data);
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
