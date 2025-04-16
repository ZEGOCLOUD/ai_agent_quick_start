import { post } from '../utils/http';
import type { CreateAgentInstanceReq, CreateAgentInstanceRes, CreateAgentReq, DeleteAgentInstanceReq, Response } from '../types/http';
import { generateParams } from '../utils/helper';

const ActionCmd = {
  RegisterAgent: "RegisterAgent", // 注册智能体
  DeleteAgent: "DeleteAgent", // 删除智能体
  CreateAgentInstance: "CreateAgentInstance", // 创建智能体实例
  DeleteAgentInstance: "DeleteAgentInstance", // 删除智能体实例
}

/**
 * 注册智能体
 * @param params 注册智能体参数
 */
export function RegisterAgent(params: CreateAgentReq): Promise<Response<null>> {
  const url = generateParams(ActionCmd.RegisterAgent)
  return post(url, params);
}

/**
 * 删除智能体
 * @param params 删除智能体参数
 */
export function DeleteAgent(params: { AgentId: string }): Promise<Response<null>> {
  const url = generateParams(ActionCmd.DeleteAgent)
  return post(url, params);
}

/**
 * 创建智能体实例
 * @param params 创建智能体实例参数
 */
export function CreateAgentInstance(params: CreateAgentInstanceReq): Promise<Response<CreateAgentInstanceRes>> {
  const url = generateParams(ActionCmd.CreateAgentInstance)
  return post(url, params);
}

/**
 * 删除智能体实例
 * @param params 删除智能体实例参数
 */
export function DeleteAgentInstance(params: DeleteAgentInstanceReq): Promise<Response<null>> {
  const url = generateParams(ActionCmd.DeleteAgentInstance)
  return post(url, params);
}