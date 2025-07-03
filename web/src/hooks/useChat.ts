import { ref } from "vue";
import type { ExpressManager } from "../solution/ExpressManager";

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
  Data: MessageData;
}

export interface Message {
  sender: string;
  messageId: string;
  seqId: number;
  content: string;
  type: string;
  round: number;
}

export function useChat(zg: ExpressManager) {
  // 状态管理
  const messages = ref<Message[]>([]);
  let agentMsgMap: Record<string, Message[]> = {};
  let userMsgMap: Record<string, Message[]> = {};

  /**
   * 处理房间命令消息
   * @param {RoomMessage} message - 接收到的消息对象
   */
  function handleRoomCommandMessage(msg: RoomMessage) {

    const { Cmd, SeqId, Data, Round } = msg;

    switch (Cmd) {

      // 用户说话文本处理
      case 3:
        handleUserMessage(SeqId, Data, Round);
        break;

      // 智能体说话文本处理
      case 4:
        handleAgentMessage(SeqId, Data, Round);
        break;

      default:
        console.warn(`Unknown command: ${Cmd}`);
    }
  }
  // 处理用户消息
  function handleUserMessage(seqId: number, data: MessageData, round: number) {
    console.log(`"mytag 用户说话文本内容：", ${seqId}, ${data.Text}`);
    if (data.EndFlag) {
      console.log(`"mytag 用户说话完毕", ${seqId}`);
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
      content: content,
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
    console.log(`"mytag 智能体说话文本内容：", ${seqId}, ${data.Text}`);
    const llmEndFlag = data.EndFlag;
    if (llmEndFlag) {
      console.log(`"mytag 智能体回答完毕", ${seqId}`);
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
      content: content,
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
      if (sortedMessages.trim()) {
        messages.value[index].content = sortedMessages;
      }
    } else {
      messages.value.push(newMessage);
    }
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
          console.error("解析消息失败:", error);
        }
      }
    });
    zg.callExperimentalAPI({ method: "onRecvRoomChannelMessage", params: {} });
    // 兼容旧的消息通道
    // zg.off("IMRecvCustomCommand");
    zg.on(
      "IMRecvCustomCommand",
      (roomID: string, fromUser: any, command: string) => {
        console.warn("mytag IMRecvCustomCommand");
        try {
          const message = JSON.parse(command);
          console.warn("IMRecvCustomCommand", message);
          if (message.cmd && message.data) {
            const { cmd, seq_id, round, timestamp } = message;
            const { message_id, text, end_flag, speak_status, user_id } =
              message.data;
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
                  // UserId: user_id,
                },
              });
          }
        } catch (error) {
          console.error("解析消息失败:", error);
        }
      }
    );
  }

  function clearMessages() {
    messages.value = [];
    agentMsgMap = {};
    userMsgMap = {};
  }

  return {
    messages,
    setupEventListeners,
    clearMessages,
  };
}
