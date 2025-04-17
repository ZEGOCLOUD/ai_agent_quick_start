import { get, post } from '../utils/http';
import type { CreateAgentInstanceReq, CreateAgentInstanceRes, CreateAgentReq, CreateAgentRes, DeleteAgentInstanceReq, Response } from '../types/http';

const ActionCmd = {
  RegisterAgent: "/api/agent/register", // 注册智能体
  CreateAgentInstance: "/api/agent/create", // 创建智能体实例
  DeleteAgentInstance: "/api/agent/delete", // 删除智能体实例
  GetZegoToken: "/api/zegotoken", // 获取ZEGO Token
}

/**
 * 注册智能体
 * @param params 注册智能体参数
 */
export function RegisterAgent(params: CreateAgentReq): Promise<CreateAgentRes> {
  return post(ActionCmd.RegisterAgent, params);
}


/**
 * 创建智能体实例
 * @param params 创建智能体实例参数
 */
export function CreateAgentInstance(params: CreateAgentInstanceReq): Promise<CreateAgentInstanceRes> {
  return post(ActionCmd.CreateAgentInstance, params);
}

/**
 * 删除智能体实例
 * @param params 删除智能体实例参数
 */
export function DeleteAgentInstance(params: DeleteAgentInstanceReq): Promise<Response> {
  return post(ActionCmd.DeleteAgentInstance, params);
}

/**
 * 获取ZEGO Token
 * @param params 获取ZEGO Token参数
 */
export function GetZegoToken(params: { userId: string; }): Promise<{ token: string }> {
  return get(ActionCmd.GetZegoToken, params);
}