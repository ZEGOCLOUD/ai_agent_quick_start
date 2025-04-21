import { ref } from "vue";
import { AgentStatus, SignalStatus, UserStatus } from "../types/enum";
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
}

export function useChat(zg: ExpressManager) {
  // 状态管理
  const signalStatus = ref<SignalStatus>(SignalStatus.Listening);
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
      // 用户说话状态处理
      case 1:
        console.log(
          `"mytag 用户说话状态",${Data.SpeakStatus === 1 ? "开始" : "结束"}`
        );
        handleUserSpeakStatus(Data.SpeakStatus);
        break;

      // 智能体说话状态处理
      case 2:
        console.log(
          `"mytag 智能体说话状态",${Data.SpeakStatus === 1 ? "开始" : "结束"}`
        );
        handleAgentSpeakStatus(Data.SpeakStatus, SeqId);
        break;

      // 用户说话文本处理
      case 3:
        handleUserMessage(SeqId, Data);
        break;

      // 智能体说话文本处理
      case 4:
        handleAgentMessage(SeqId, Data);
        break;

      default:
        console.warn(`Unknown command: ${Cmd}`);
    }
  }
  // 处理用户消息
  function handleUserMessage(seqId: number, data: MessageData) {
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
        (message) => message.messageId === messageId
      );
      const newMessage = {
        sender: "user",
        messageId: messageId,
        seqId: seqId,
        content: content,
        type: "message",
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
    data: MessageData
  ) {
    const llmEndFlag = data.EndFlag;
    console.log(`"mytag 智能体说话文本内容：", ${seqId}, ${data.Text}`);
    if (llmEndFlag) {
      console.log(`"mytag 智能体回答完毕", ${seqId}`);
    }
    const content = data.Text.trim();
    const llmMessageId = data.MessageId;
    if (!content) return;
    const index = messages.value.findIndex(
      (message) => message.messageId === llmMessageId
    );
    const newMessage = {
      sender: "bot",
      messageId: llmMessageId,
      seqId: seqId,
      content: content,
      type: "message",
    };
    if (!agentMsgMap[newMessage.messageId]) {
      agentMsgMap[newMessage.messageId] = [];
    }
    agentMsgMap[newMessage.messageId].push({ ...newMessage });

    if (index !== -1) {
      const newMessages = agentMsgMap[newMessage.messageId];
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
   * 更新交互状态信号
   * @param {SignalStatus} signal - 状态信号
   */
  function handleSignal(signal: SignalStatus) {
    signalStatus.value = signal;
  }

  // 处理用户说话状态
  function handleUserSpeakStatus(status: UserStatus) {
    if (status === UserStatus.Listening) {
      handleSignal(SignalStatus.Listening);
    }
    if (status === UserStatus.Thinking) {
      handleSignal(SignalStatus.Thinking);
    }
  }

  // 处理智能体说话状态
  function handleAgentSpeakStatus(status: number, seq: number) {
    if (status === AgentStatus.Speaking) {
      handleSignal(SignalStatus.Speaking);
    }
    if (status === AgentStatus.Listening) {
      handleSignal(SignalStatus.Listening);
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
    signalStatus.value = SignalStatus.Listening;
    userMsgSeq = 0;
    agentMsgMap = {};
  }

  return {
    signalStatus,
    messages,
    setupEventListeners,
    clearMessages,
  };
}
