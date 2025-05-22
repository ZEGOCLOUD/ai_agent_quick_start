import { ZIM, ZIMSDK, type ZIMEventHandler, type ZIMLoginConfig, type ZIMMessageBase, type ZIMMessageQueryConfig, type ZIMMessageSendConfig } from "zego-zim-web";

export class ZIMManage {
  private static instance: ZIMManage;
  private isInit = false;

  public init(appID: number) {
    console.log("initZIMSDK", appID, this.isInit);
    if (this.isInit) return;
    ZIM.create({ appID });
    this.isInit = true;
  }

  public static getInstance(): ZIMManage {
    if (!ZIMManage.instance) {
      ZIMManage.instance = new ZIMManage();
    }
    return ZIMManage.instance;
  }

  get zim(): ZIMSDK {
    const zim = ZIM.getInstance();
    if (!zim) throw new Error("ZIM SDK 未初始化");
    return zim;
  }

  public on<K extends keyof ZIMEventHandler>(
    type: K,
    listener: ZIMEventHandler[K]
  ): void {
    this.zim.on(type, listener);
  }

  public off<K extends keyof ZIMEventHandler>(type: K): void {
    this.zim.off(type);
  }

  public login(userID: string, config: ZIMLoginConfig) {
    return this.zim.login(userID, config);
  }

  public logout() {
    return this.zim.logout();
  }

  public sendMessage(message: ZIMMessageBase, toConversationID: string, conversationType: ZIM.ConversationType, config: ZIMMessageSendConfig) {
    return this.zim.sendMessage(message, toConversationID, conversationType, config);
  }

  public queryHistoryMessage(conversationID: string, conversationType: ZIM.ConversationType, config: ZIMMessageQueryConfig) {
    return this.zim.queryHistoryMessage(conversationID, conversationType, config);
  }

  public destroy() {
    this.zim.destroy();
    this.isInit = false;
  }
}
