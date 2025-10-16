import { ref } from "vue";
import type { ExpressManager } from "../solution/ExpressManager";
import { logger } from "../utils/logger";
import { ErrorHandler } from "../utils/error-handler";

interface MessageData {
  MessageId: string;
  Text: string;
  EndFlag: boolean;
  SpeakStatus: number;
}

interface RoomMessage {
  Timestamp: number;
  SeqId: number;
  Round: number;
  Cmd: number;
  Data: MessageData | any;
}

export interface Message {
  sender: string;
  messageId: string;
  seqId: number;
  content: string;
  type: string;
  round: number;
}

export interface CustomMessage {
  [key: string]: any;
}

export function useChat(zg: ExpressManager) {
  // 状态管理
  const messages = ref<Message[]>([]);
  let agentMsgMap: Record<string, Message[]> = {};
  let userMsgMap: Record<string, Message[]> = {};
  const customMessages = ref<CustomMessage[]>([]);

  /**
   * 处理房间命令消息
   * @param {RoomMessage} message - 接收到的消息对象
   */
  function handleRoomCommandMessage(msg: RoomMessage) {

    const { Cmd, SeqId, Data, Round, Timestamp } = msg;

    switch (Cmd) {
      // 用户说话文本处理
      case 3:
        handleUserMessage(SeqId, Data, Round);
        break;
      // 智能体说话文本处理
      case 4:
        handleAgentMessage(SeqId, Data, Round);
        break;
      // 客户自定义信息处理
      case 102: 
        handleCustomMessage(SeqId, Data, Round, Timestamp);
        break;

      default:
        logger.warn('CHAT', '未知的消息命令', { cmd: Cmd, seqId: SeqId });
    }
  }
  // 处理用户消息
  function handleUserMessage(seqId: number, data: MessageData, round: number) {
    logger.debug('CHAT', '用户说话文本', { seqId, text: data.Text, round });
    if (data.EndFlag) {
      logger.debug('CHAT', '用户说话完毕', { seqId, round });
    }

    const content = data.Text.trim();
    const messageId = data.MessageId;
    if (!content) return;
    const index = messages.value.findIndex(
      (message) => message.sender === 'user' && message.round === round
    );
    const newMessage = {
      sender: "user",
      messageId: messageId,
      seqId: seqId,
      content: data.Text,
      type: "message",
      round,
    };

    if (!userMsgMap[round]) {
      userMsgMap[round] = [];
    }

    // 缓存新消息
    userMsgMap[round].push({ ...newMessage });

    if (index !== -1) {
      // 消息已存在,取出seqId最大的消息
      const maxMsg = userMsgMap[round].reduce((maxMsg, currentMsg) => {
        return currentMsg.seqId > maxMsg.seqId ? currentMsg : maxMsg;
      });
      messages.value[index].content = maxMsg.content;
    } else {
      messages.value.push(newMessage);
    }
  }

  // 处理智能体消息
  function handleAgentMessage(
    seqId: number,
    data: MessageData,
    round: number
  ) {
    logger.debug('CHAT', 'AI Agent 说话文本', { seqId, text: data.Text, round });
    const llmEndFlag = data.EndFlag;
    if (llmEndFlag) {
      logger.debug('CHAT', 'AI Agent 回答完毕', { seqId, round });
    }
    const content = data.Text.trim();
    const llmMessageId = data.MessageId;
    if (!content) return;
    const index = messages.value.findIndex(
      (message) => message.sender === 'bot' && message.round === round
    );
    const newMessage = {
      sender: "bot",
      messageId: llmMessageId,
      seqId: seqId,
      content: data.Text,
      type: "message",
      round,
    };
    if (!agentMsgMap[round]) {
      agentMsgMap[round] = [];
    }
    agentMsgMap[round].push({ ...newMessage });

    if (index !== -1) {
      const newMessages = agentMsgMap[round].filter(message => message.messageId === llmMessageId);
      const sortedMessages = newMessages
        .sort((a, b) => a.seqId - b.seqId)
        .map(({ content }) => content)
        .join("");
      if (sortedMessages) {
        messages.value[index].content = sortedMessages;
      }
    } else {
      messages.value.push(newMessage);
    }
  }

  // 处理自定义消息
  function handleCustomMessage(seqId: number, data: any, round: number, timestamp: number) {
    logger.debug('CHAT', '客户自定义消息', { seqId, text: data, round, timestamp });
    // 遍历data对象并打印key和value
    const obj: Record<string, any> = {};
    for (const [key, value] of Object.entries(data)) {
      obj[key] = value;
    }
    // 创建Date对象，并根据中国时区（UTC+8）调整时间
    const date = new Date(timestamp * 1000);
    const chinaTime = new Date(date.getTime() + (8 * 60 * 60 * 1000));
    obj.time = chinaTime;
    customMessages.value.push(obj);
  }

  /**
   * 设置事件监听
   */
  function setupEventListeners() {
    zg.on("recvExperimentalAPI", (result: Record<string, any>) => {
      const { method, content } = result;
      if (method === "onRecvRoomChannelMessage") {
        try {
          const recvMsg = JSON.parse(content.msgContent);
          handleRoomCommandMessage(recvMsg);
        } catch (error) {
          logger.error('CHAT', '解析房间消息失败', { method, content, error });
          ErrorHandler.handle(error, 'useChat.recvExperimentalAPI');
        }
      }
    });
    zg.callExperimentalAPI({ method: "onRecvRoomChannelMessage", params: {} });
    // 兼容旧的消息通道
    // zg.off("IMRecvCustomCommand");
    zg.on(
      "IMRecvCustomCommand",
      (_: string, __: any, command: string) => {
        logger.debug('CHAT', '接收自定义命令消息 (兼容模式)', { command });
        try {
          const message = JSON.parse(command);
          logger.debug('CHAT', '解析自定义命令消息', { message });
          
          if (message.cmd && message.data) {
            const { cmd, seq_id, round, timestamp } = message;
            const { message_id, text, end_flag, speak_status } = message.data;
            
            handleRoomCommandMessage({
              Cmd: cmd,
              SeqId: seq_id,
              Round: round,
              Timestamp: timestamp,
              Data: {
                MessageId: message_id,
                Text: text,
                EndFlag: end_flag,
                SpeakStatus: speak_status,
              },
            });
          }
        } catch (error) {
          logger.error('CHAT', '解析自定义命令消息失败', { command, error });
          ErrorHandler.handle(error, 'useChat.IMRecvCustomCommand');
        }
      }
    );
  }

  function clearMessages() {
    messages.value = [];
    customMessages.value = [];
    agentMsgMap = {};
    userMsgMap = {};
  }

  return {
    messages,
    customMessages,
    setupEventListeners,
    clearMessages,
  };
}
