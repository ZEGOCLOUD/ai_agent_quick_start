import { useRoom } from '../../hooks/useRoom';
import logger from '../../utils/logger';
import { ErrorHandler } from "../../utils/error-handler";
import { useChat } from '../../hooks/useChat';
import { AgentStatus } from "../../types/enum";

// 定义页面数据类型
interface VoiceChatData {
  roomId: string;
  userId: string;
  userName: string;
  userStreamId: string;
  isSubtitlesExpand: boolean;
  isLoginRoom: boolean
  agentName: string;
  agentUserId: string;
  agentInstanceId: string;
  agentStatus: AgentStatus;
  agentStatusMap: Record<AgentStatus, string>;
  zegoPlayerList: any[];
  messages: any[];
  toBottom: string;
}

interface IndexPageOptions {
  randomId: (prefix: string) => string;
  handleLoginRoom: () => void;
  toggleSubtitles: () => void;
  handleLogoutRoom: () => void;
  copyAgentInstanceId: () => void;
}

// 在页面作用域创建roomHook实例
const { zg, isLogin, initSDK, checkPermission, setupEventListeners, getToken, loginRoom, logoutRoom, startPublishingStream } = useRoom();
const { setupEventListeners: setupChatEventListeners, clearMessages, setMessagesChangeCallback, setAgentStatusChangeCallback } = useChat(zg);

Page<VoiceChatData, IndexPageOptions>({
  // 页面初始数据
  data: {
    roomId: '',
    userId: '',
    userName: '',
    userStreamId: '',
    isSubtitlesExpand: true,
    isLoginRoom: false,
    agentName: '',
    agentUserId: '',
    agentInstanceId: '',
    agentStatus: AgentStatus.Idle,
    agentStatusMap: {
      [AgentStatus.Idle]: '空闲',
      [AgentStatus.Listening]: '正在听...',
      [AgentStatus.Thinking]: '正在想...',
      [AgentStatus.Speaking]: '正在说...',
    },
    zegoPlayerList: [],
    messages: [],
    toBottom: '',
  },

  async onShow() {
    // 避免小程序在后台token过期后，重新进入小程序登录房间报错
    await getToken(this.data.userId);
  },

  async onLoad() {
    try {
      logger.info('INDEX', 'index页面初始化开始', { 
        roomId: this.data.roomId, 
        userId: this.data.userId 
      });
      // 页面加载时的初始化逻辑（如拉取房间信息）
      this.setData({
        roomId: this.randomId('room_'),
        userId: this.randomId('user_'),
        userName: this.randomId('user_name_'),
        userStreamId: this.randomId('user_stream_'),
      });
      // 初始化SDK
      await initSDK(this);
      checkPermission();
      setupEventListeners();
      setupChatEventListeners();
      // await getToken(this.data.userId);
      
      // 设置消息变化回调
      setMessagesChangeCallback((newMessages) => {
        this.setData({
          messages: newMessages,
          toBottom: 'bottom'
        });
      });

      setAgentStatusChangeCallback((status) => {
        this.setData({
          agentStatus: status,
        });
      });
      
      logger.info('INDEX', 'index页面初始化完成', { 
        roomId: this.data.roomId, 
        userId: this.data.userId 
      });
    } catch (error) {
      logger.error('INDEX', 'index页面初始化失败', { 
        roomId: this.data.roomId, 
        userId: this.data.userId,
        error
      });
      ErrorHandler.handle(error, 'index onLoad');
    }
  },

  randomId(prefix: string) {
    return prefix + Math.random().toString(36).substring(2, 10);
  },

  // 登录房间按钮点击
  async handleLoginRoom() {
    try {
      wx.showLoading({ title: "登录房间中..." });
      const res = await loginRoom(
        "normal",
        this.data.roomId,
        this.data.userId,
        this.data.userName,
        this.data.userStreamId
      );
      
      if (!res.code) {
        wx.showToast({ title: "已进入房间" });
        this.setData({
          isLoginRoom: true,
          agentName: res.agent_name,
          agentUserId: res.agent_user_id,
          agentInstanceId: res.agent_instance_id,
        })

        logger.userAction('用户登录成功', {
          res,
          roomId: this.data.roomId,
          userId: this.data.userId,
          agentInstanceId: res.agent_instance_id,
          isLogin,
        })

        await startPublishingStream(this.data.userStreamId, {enableCamera: false, mode: 'RTC'})
      } else {
        // API返回错误码时的处理
        console.error('登录房间失败:', res);
        wx.showToast({ 
          title: res.message || "登录房间失败", 
          icon: "error"
        });
        logger.userAction('用户登录失败', {
          roomId: this.data.roomId,
          userId: this.data.userId,
          error: res
        })
      }
    } catch (error) {
      console.error('登录房间失败:', error);
      wx.showToast({ title: "登录房间失败", icon: "error" });
      logger.userAction('用户登录失败', {
        roomId: this.data.roomId,
        userId: this.data.userId,
        error
      })
    } finally {
      wx.hideLoading();
    }
  },

  // 退出房间
  async handleLogoutRoom() {
    try {
      wx.showLoading({ title: "登出房间中..." });
      await logoutRoom(this.data.agentInstanceId);
      this.setData({
        isLoginRoom: false,
        agentName: '',
        agentUserId: '',
        agentInstanceId: '',
        agentStatus: AgentStatus.Idle,
        roomId: this.randomId('room_'),
        zegoPlayerList: []
      })
    } catch (error) {
      console.error('退出房间失败:', error);
      wx.showToast({ title: "退出房间失败", icon: "error" });
      logger.userAction('用户退出房间失败', {
        roomId: this.data.roomId,
        userId: this.data.userId,
        error
      })
    } finally {
      clearMessages();
      wx.hideLoading();
    }
  },

  // 切换字幕展开/折叠
  toggleSubtitles() {
    this.setData({
      isSubtitlesExpand: !this.data.isSubtitlesExpand
    });
  },

  // 复制AgentInstanceID
  copyAgentInstanceId() {
    wx.setClipboardData({
      data: this.data.agentInstanceId,
      success: () => {
        wx.showToast({
          title: '复制成功',
          icon: 'success'
        });
      },
      fail: (err) => {
        console.error('复制失败:', err);
        wx.showToast({
          title: '复制失败',
          icon: 'error'
        });
      }
    });
  },
});