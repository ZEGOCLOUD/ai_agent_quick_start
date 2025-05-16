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
  let userMsgSeq = 0;
  let agentMsgMap: Record<string, Message[]> = {};

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
    if (seqId > userMsgSeq) {
      if (data.EndFlag) {
        console.log(`"mytag 用户说话完毕", ${seqId}`);
      }

      const content = data.Text.trim();
      const messageId = data.MessageId;
      userMsgSeq = seqId;
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

      if (index !== -1) {
        messages.value[index].content = newMessage.content;
      } else {
        messages.value.push(newMessage);
      }
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
  }

  function clearMessages() {
    messages.value = [];
    userMsgSeq = 0;
    agentMsgMap = {};
  }

  return {
    messages,
    setupEventListeners,
    clearMessages,
  };
}
