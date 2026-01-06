import { ZegoLocalProxyConfig } from '../zego.entity';
import type { HttpReq, BusinessService } from '../../common/zego.entity';
import pb from '../../proto/rtc-minipb';
declare enum ServiceType {
    Accesshub = 0,
    Logger = 1,
    Detaillog = 2
}
interface HTTPReq extends HttpReq {
    service?: BusinessService;
    idName?: string;
    origin?: boolean;
    serviceType: number;
}
export declare class LocalProxyController {
    private _zgp_serverConfig;
    constructor(_zgp_serverConfig: ZegoLocalProxyConfig);
    init(options: {
        appID: number;
    }): void;
    createSocket(target: string, serviceType: ServiceType): WebSocket;
    private _zgp_changeDestUrl;
    /**
     * 发起http请求，短连接代理
     * @param params 请求参数
     * @param sucFunc 成功回调
     * @param errFunc 失败回调
     * @param ackFunc 接入服务收到回调
     * @internal
     */
    startHttpRequest(req: HTTPReq, sucFunc?: (msg: pb.webproxy.HTTPResponseData) => void | null, errFunc?: (msg: pb.webproxy.HTTPResponseData) => void | null, option?: {
        timeout?: number;
    }): void;
    destroy(): void;
}
export {};
