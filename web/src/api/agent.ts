import { get, post } from '../utils/http';
import type { GetAgentInfoRes, Response, StartRes } from '../types/http';

const ActionCmd = {
  GetZegoToken: "/api/zego-token", // 获取ZEGO Token
  Start: "/api/start", // 开始
  Stop: "/api/stop", // 停止
  GetAgentInfo: "/api/getAgentInfo", // 获取Agent信息
}

/**
 * 进房
 */
export function Start(roomId: string, userID: string, userStreamId: string): Promise<StartRes> {
  return post(ActionCmd.Start, {
    "room_id": roomId,
    "user_id": userID,
    "user_stream_id": userStreamId,
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

/**
 * 进房
 */
export function GetAgentInfo( agentId: string, agentName: string): Promise<GetAgentInfoRes> {
  return post(ActionCmd.GetAgentInfo, {
    agent_id: agentId,
    agent_name: agentName,
  });
}
