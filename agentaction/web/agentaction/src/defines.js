(function(root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.ZegoAIAgentActionDefines = factory();
    }
})(typeof self !== 'undefined' ? self : this, function() {
    'use strict';

    const ExpressMethods = {
        /// 发送房间通道消息的方法名
        sendRoomChannelMessage: 'liveroom.room.send_room_channel_message',

        /// 收到房间通道消息的回调方法名
        onReciveRoomChannelMessage: 'liveroom.room.on_recive_room_channel_message',

        /// 发送房间通道消息结果的回调方法名
        onSendRoomChannelMessage: 'liveroom.room.on_send_room_channel_message',
    };

    const ExpressKeys = {
        method: 'method',
        params: 'params',
        roomId: 'room_id',
        msgType: 'msg_type',
        msgContent: 'msg_content',
        userList: 'user_list',
        seq: 'seq',
        errorCode: 'error_code',
        errorMessage: 'error_message',
    };

    const ProtocolKeys = {
        action: 'Action',
        seq: 'Seq',
        params: 'Params',
        code: 'Code',
        message: 'Message',
        requestId: 'RequestId',
        data: 'Data',

        // Params 内部字段
        text: 'Text',
        addHistory: 'AddHistory',
        priority: 'Priority',
        samePriorityOption: 'SamePriorityOption',
        interruptMode: 'InterruptMode',
        enqueueUserSpeech: 'EnqueueUserSpeech',
        systemPrompt: 'SystemPrompt',
        addQuestionToHistory: 'AddQuestionToHistory',
        addAnswerToHistory: 'AddAnswerToHistory',
        userId: 'UserId',
    };

    return {
        ExpressMethods: ExpressMethods,
        ExpressKeys: ExpressKeys,
        ProtocolKeys: ProtocolKeys,
        ErrorCodes: {
            SUCCESS: 0,
            TIMEOUT: -1,
            SEND_FAILED: -2,
            CANCELED: -3,
        },
    };
});
