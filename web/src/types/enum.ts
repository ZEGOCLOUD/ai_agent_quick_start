/**
 * AI Agent 交互状态枚举
 * 对应房间消息 Cmd=6 中 Data.Status 的取值
 */
export enum AgentStatus {
  /** 空闲中 */
  IDLE = 0,
  /** 正在听 */
  Listening = 1,
  /** 正在想 */
  Thinking = 2,
  /** 正在说话（可被打断） */
  Speaking = 3,
}
