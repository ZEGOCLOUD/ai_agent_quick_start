export declare const kZMInitSetting: {
    event: string;
};
export declare const kZegoTaskCheckSystemRequirements: {
    event: string;
    error: {
        kCheckSystemGetSettingFailError: {
            code: number;
            message: string;
        };
    };
    check_system: (item: any) => any;
};
export declare const kZegoTaskPublishStart: {
    event: string;
    error: {
        kPublishStreamIDNullError: {
            code: number;
            message: string;
        };
        _zgp_kPublishParamError: {
            code: number;
            message: string;
        };
        kPublishStreamIDTooLongError: {
            code: number;
            message: string;
        };
        kPublishStreamIDInvalidCharacterError: {
            code: number;
            message: string;
        };
        _zgp_kPublishNetworkTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kPublishDispatchTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kPublishDispatchError: {
            code: number;
            message: string;
        };
        _zgp_kPublishNetworkBrokenError: {
            code: number;
            message: string;
        };
        _zgp_kPublishNoLoginError: {
            code: number;
            message: string;
        };
        _zgp_kPublishRetryTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kIsPublishing: {
            code: number;
            message: string;
        };
    };
    publishOption: (item: any) => any;
    stream: (item: any) => any;
    message: (item: any) => any;
};
export declare const kZegoTaskPlayStart: {
    event: string;
    error: {
        kPlayStreamIDNullError: {
            code: number;
            message: string;
        };
        _zgp_kPlayParamError: {
            code: number;
            message: string;
        };
        kPlayStreamIDTooLongError: {
            code: number;
            message: string;
        };
        _zgp_kPlayStreamIDInvalidCharacterError: {
            code: number;
            message: string;
        };
        _zgp_kPlayNoLoginError: {
            code: number;
            message: string;
        };
        _zgp_kPlayRepeatedPullError: {
            code: number;
            message: string;
        };
        _zgp_kPlayStreamNotFound: {
            code: number;
            message: string;
        };
        _zgp_kPlayNetworkTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kPlayDispatchTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kPlayDispatchError: {
            code: number;
            message: string;
        };
        _zgp_kPlayNetworkBrokenError: {
            code: number;
            message: string;
        };
        _zgp_kPlayRetryTimeoutError: {
            code: number;
            message: string;
        };
        _zgp_kIsPlaying: {
            code: number;
            message: string;
        };
    };
    playOption: (item: any) => any;
    message: (item: any) => any;
    session_id: (item: any) => any;
    stream: (item: any) => any;
    audio_activate: (item: any) => any;
    video_activate: (item: any) => any;
};
export declare const kZegoEventPublishStat = "/sdk/publish_stat_report";
export declare const kZegoEventPlayStat = "/sdk/play_stat_report";
export declare const kZegoTaskRePublish = "/sdk/republish";
export declare const kZegoTaskRePlay = "/sdk/replay";
export declare const kZegoTaskPublishStop: {
    event: string;
    error: {
        _zgp_kParamError: {
            code: number;
            message: string;
        };
    };
    stream: (item: any) => any;
    room_id: (item: any) => any;
};
export declare const kZegoTaskPlayStop: {
    event: string;
    error: {
        _zgp_kParamError: {
            code: number;
            message: string;
        };
    };
    stream: (item: any) => any;
};
export declare const kZegoTaskLiveRoomGetStreamUpdateInfo: {
    event: string;
    stream_update_type: (item: any) => any;
    update_stream: (item: any) => any;
};
export declare const kZegoTaskLiveRoomGetStreamExtraInfo: {
    event: string;
    update_stream: (item: any) => any;
};
