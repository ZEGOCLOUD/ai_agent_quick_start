import { ZegoProxyInfo } from '../zego.entity';
import { ProxySocket } from './ProxySocket';
import pb from '../../proto/rtc-minipb';
import type { HttpReq, BusinessService } from '../../common/zego.entity';
interface HTTPReq extends HttpReq {
    service?: BusinessService;
    idName?: string;
    origin?: boolean;
}
export declare class ProxyController {
    private proxyList;
    private token;
    /**
 * "/proxy/http"
"/proxy/ws"  get
"/turn/info"
"/intranet/check"
 */
    constructor(proxyList: ZegoProxyInfo[], token: string);
    userID: string;
    enable: boolean;
    get urls(): string[];
    private activeServer?;
    private _zgp_updateActiveServer;
    destroy(): void;
    appID: number;
    init(parmas: {
        appID: number;
    }): void;
    createSocket(target: string, service: number): ProxySocket;
    /** @internal */
    turnInfo?: pb.webproxy.TurnInfoResponse;
    turnExpireTime?: number;
    /** @internal */
    getTurnInfo(): Promise<pb.webproxy.TurnInfoResponse>;
    handleFetch(path: string | undefined, content: Uint8Array): Promise<ArrayBuffer | never[]>;
    /** @internal */
    intranetCheck(vrs_ipv4: number, vrs_ipv6: any): Promise<pb.webproxy.IntranetCheckResponse>;
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
}
export {};
