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
  message_id: string;
  seq_id: number;
  content: string;
  type: string;
}

export function useChat(zg: ExpressManager) {
  // 状态管理
  const signalStatus = ref<SignalStatus>();
  const messages = ref<Message[]>([]);
  const userMsgSeq = ref(0);
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
  function handleUserMessage(seq_id: number, data: MessageData, round: number) {
    console.log(`"mytag 用户说话文本内容：", ${seq_id}, ${data.Text}`);
    if (seq_id > userMsgSeq.value) {
      if (data.EndFlag) {
        console.log(`"mytag 用户说话完毕", ${seq_id}`);
      }
      const asrText = data.Text;
      const messageId = data.MessageId;
      addOrUpdateMessage({
        sender: "user",
        message_id: messageId,
        seq_id: seq_id,
        content: asrText,
        type: "message",
      });
      userMsgSeq.value = seq_id;
    }
  }

  // 处理智能体消息
  function handleAgentMessage(seq_id: number, data: MessageData, round: number) {
    const llmEndFlag = data.EndFlag;
    console.log(`"mytag 智能体说话文本内容：", ${seq_id}, ${data.Text}`);
    if (llmEndFlag) {
      console.log(`"mytag 智能体回答完毕", ${seq_id}, ${round}`);
    }
    const llmText = data.Text;
    const llmMessageId = data.MessageId;
    addOrUpdateMessage({
      sender: "bot",
      message_id: llmMessageId,
      seq_id: seq_id,
      content: llmText,
      type: "message",
    });

  }

  // 添加或更新消息
  function addOrUpdateMessage(newMessage: Message) {
    if (!newMessage.content?.trim()) {
      return;
    }

    const isBotMessage = newMessage.sender === "bot";
    const index = messages.value.findIndex(
      (message) => message.message_id === newMessage.message_id
    );
    if (isBotMessage) {
      if (!agentMsgMap[newMessage.message_id]) {
        agentMsgMap[newMessage.message_id] = []
      }
      agentMsgMap[newMessage.message_id].push({...newMessage});
    }

    if (index !== -1) {
      if (isBotMessage) {
        const newMessages = agentMsgMap[newMessage.message_id]
        const sortedMessages = newMessages
          .sort((a, b) => a.seq_id - b.seq_id)
          .map(({ content }) => content)
          .join("");
        if (sortedMessages.trim()) {
          messages.value[index].content = sortedMessages;
        }
      } else if (newMessage.content.trim()) {
        messages.value[index].content = newMessage.content;
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
    userMsgSeq.value = 0;
    agentMsgMap = {};
  }

  return {
    signalStatus,
    messages,
    handleUserMessage,
    handleAgentMessage,
    handleUserSpeakStatus,
    handleAgentSpeakStatus,
    setupEventListeners,
    clearMessages,
  };
}
