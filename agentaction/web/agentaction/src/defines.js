(function(root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.ZegoAIAgentActionDefines = factory();
    }
})(typeof self !== 'undefined' ? self : this, function() {
    'use strict';

    const ExpressMethods = {
        sendRoomChannelMessage: 'sendRoomChannelMessage',
        onRecvRoomChannelMessage: 'onRecvRoomChannelMessage',
    };

    const ExpressKeys = {
        method: 'method',
        params: 'params',
        content: 'content',
        roomId: 'roomID',
        msgType: 'msgType',
        msgContent: 'msgContent',
        userList: 'toUserIDList',
        seq: 'seq',
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
