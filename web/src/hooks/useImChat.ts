import { ref } from "vue";
import { ZIM } from "zego-zim-web";
import type { ZIMLoginConfig, ZIMMessageQueryConfig } from "zego-zim-web";
import { ZIMManage } from "@/solution/ZIMManage";
import config from "@/config";
import { GetZegoToken } from "@/api/agent";
import type { ChatMessage } from "@/types/chat";

export function useImChat() {
  const zim = ZIMManage.getInstance();
  const isLogin = ref(false);
  const messages = ref<ChatMessage[]>([]);
  const userID = ref("");

  // 初始化 IM SDK
  const initSDK = () => {
    try {
      zim.init(config.zego.appId);
      // 设置监听
      setupEventListener();
      console.log("IM SDK 初始化成功");
    } catch (error) {
      console.error("IM SDK 初始化失败:", error);
    }
  };

  // 登录
  const login = async (userId: string, userName: string) => {
    try {
      const { token } = await GetZegoToken({ userId });
      if (!token) {
        throw new Error("获取 token 失败");
      }
      const config: ZIMLoginConfig = {
        userName,
        token,
        customStatus: "",
        isOfflineLogin: false,
      };
      await zim.login(userId, config);
      userID.value = userId;
      isLogin.value = true;
      console.log("IM 登录成功");
    } catch (error) {
      console.error("IM 登录失败:", error);
      throw error;
    }
  };

  // 退出登录
  const logout = async () => {
    try {
      await zim.logout();
      resetState();
      console.log("IM 退出登录成功");
    } catch (error) {
      console.error("IM 退出登录失败:", error);
      throw error;
    }
  };

  // 发送消息
  const sendMessage = async (message: string, toConversationID: string) => {
    try {
      const conversationType = 0; // 会话类型，取值为 单聊:0, 房间:1, 群组:2
      const config = {
        priority: 3, // 设置消息优先级，取值为 低：1（默认），中：2，高：3
      };
      const result = await zim.sendMessage(
        { type: 1, message },
        toConversationID,
        conversationType,
        config
      );
      const newMessage: ChatMessage = {
        sender: "user",
        messageId: result.message.messageID,
        seqId: result.message.messageSeq,
        content: message,
        type: "message",
      };
      // 发送成功后将消息添加到列表
      messages.value.push(newMessage);
      console.log("消息发送成功:", result);
      return result;
    } catch (error) {
      console.error("消息发送失败:", error);
      throw error;
    }
  };

  // 查询历史消息
  const queryHistoryMessages = async (conversationID: string) => {
    try {
      const config: ZIMMessageQueryConfig = {
        count: 100,
        reverse: true,
      };
      const { messageList } = await zim.queryHistoryMessage(
        conversationID,
        ZIM.ConversationType.Peer,
        config
      );
      messages.value = messageList
        .map((message) => {
          return {
            sender: message.senderUserID === userID.value ? 'user' : 'bot',
            messageId: message.messageID,
            seqId: message.messageSeq,
            content: message.message,
            type: "message",
          } as ChatMessage;
        })
      console.log("查询历史消息成功:", messageList);
    } catch (error) {
      console.error("查询历史消息失败:", error);
      throw error;
    }
  };

  // 监听zim事件
  const setupEventListener = () => {
    // 注册监听“收到新消息”的回调
    zim.on("peerMessageReceived", (zim, { messageList }) => {
      console.log("收到新消息:", messageList);
      const newMessageList = messageList.map((message) => {
        return {
          sender: "bot",
          messageId: message.messageID,
          seqId: message.messageSeq,
          content: message.message,
          type: "message",
        } as ChatMessage;
      })
      messages.value.push(...newMessageList);
    });
    // 注册监听“连接状态改变”的回调
    zim.on(
      "connectionStateChanged",
      function (zim, { state, event, extendedData }) {
        console.log("connectionStateChanged", state, event, extendedData);
      }
    );
    // 注册监听“Token 即将过期”的回调
    zim.on("tokenWillExpire", async function (zim, { second }) {
      console.log("tokenWillExpire", second);
      const { token } = await GetZegoToken({ userId: userID.value });
      if (!token) {
        throw new Error("获取 token 失败");
      }
      zim
        .renewToken(token)
        .then(function ({ token }) {
          // 更新成功
          console.log("renewToken success", token);
        })
        .catch(function (err) {
          // 更新失败
          console.error("renewToken fail", err);
        });
    });
  };

  // 重置状态
  const resetState = () => {
    isLogin.value = false;
    userID.value = "";
    messages.value = [];
  };

  const destroySDK = async () => {
    console.log("destroySDK");
    if (isLogin.value) {
      await logout();
    }
    removeEventListener();
    zim.destroy();
  };

  // 移除监听
  const removeEventListener = () => {
    zim.off("peerMessageReceived");
    zim.off("connectionStateChanged");
    zim.off("tokenWillExpire");
  };

  return {
    isLogin,
    messages,
    initSDK,
    login,
    logout,
    queryHistoryMessages,
    sendMessage,
    destroySDK,
  };
}
