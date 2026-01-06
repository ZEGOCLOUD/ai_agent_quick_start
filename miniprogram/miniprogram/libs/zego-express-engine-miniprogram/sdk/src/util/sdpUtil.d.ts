import { ZegoVideoCodec } from "../common/zego.entity.web";
import { EncodecSelectionModeType } from "../common/zego.entity";
interface SdpVideoCodec {
    H264: string[];
    H265: string[];
    VP8: string[];
    VP9: string[];
    OTHER: string[];
}
export declare class SdpUtil {
    static getSDPVideoCodec(sdp: string): SdpVideoCodec;
    static getSDPByVideDecodeType(sdp: string, type: ZegoVideoCodec, isSoft?: boolean, encodecSelectionMode?: EncodecSelectionModeType): string;
}
export {};
