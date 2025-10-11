//
//  ZegoAudioChatTableView.m
//
//  Created by zego on 2024/5/13.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentSubtitlesTableView.h"

#import <Masonry/Masonry.h>

#import "ZegoAIAgentSubtitlesTableViewCell.h"
#import "ZegoAIAgentSubtitlesMessageModel.h"

@interface ZegoAIAgentSubtitlesTableView ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray<ZegoAIAgentSubtitlesMessageModel*>* chatMsgList;                       // 存储所有聊天消息的有序数组
@property (nonatomic, strong) NSMutableDictionary<NSString*,ZegoAIAgentSubtitlesMessageModel*>* tempAsrMsgList;    // 临时存储ASR(语音识别)消息的字典，键为message_id
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,NSMutableDictionary<NSNumber*, ZegoAIAgentSubtitlesMessageModel*>*>* tempLLMMsgList;  // 临时存储LLM(大语言模型)消息的嵌套字典，外层键为round id，内层键为seq id
@property (nonatomic, strong) NSMutableOrderedSet<NSNumber*>* roundEndFlag;

@end

@implementation ZegoAIAgentSubtitlesTableView
-(instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    if (self = [super initWithFrame:frame style:style]) {
        self.colors = [[ZegoAIAgentSubtitlesColors alloc]
                       initWithMyBackgroundColor:[UIColor colorWithRed:52 / 255.0
                                                                 green:120 / 255.0
                                                                  blue:252 / 255.0
                                                                 alpha:1.0]
                                     myTextColor:[UIColor whiteColor]
                            otherBackgroundColor:[UIColor whiteColor]
                       otherTextColor:[UIColor blackColor]];
        
        // 初始化各种存储容器
        self.chatMsgList = [[NSMutableArray alloc] initWithCapacity:100];
        self.tempAsrMsgList = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.tempLLMMsgList = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.roundEndFlag = [[NSMutableOrderedSet alloc] initWithCapacity:5];

        // 设置表格视图属性
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableFooterView = [[UIView alloc] init];
        self.estimatedRowHeight = 0.0;
        self.estimatedSectionFooterHeight = 0.0;
        self.estimatedSectionHeaderHeight = 0.0;
        self.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
        self.backgroundColor = [UIColor clearColor];
        self.dataSource = self;
        self.delegate = self;

        // 注册自定义单元格并添加点击手势
        [self registerClass:[ZegoAIAgentSubtitlesTableViewCell class] forCellReuseIdentifier:@"ZegoAudioChatTableViewCell"];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)tap:(UIGestureRecognizer *) recognizer {
    // 点击手势响应方法，当前为空实现
}

// 处理接收到的ASR(语音识别)文本，更新聊天信息
-(void)handleRecvAsrMessage:(ZegoAIAgentAudioSubtitlesMessage*)message{
    int messageCommand =message.cmd;
    long long messageSeqId =message.seq_id;
    long long messageRound =message.round;
    long messageTimeStamp =message.timestamp;
    
    NSString* messageContent = message.data.text;
    NSString* messageId = message.data.message_id;
    BOOL messageEndFlag = message.data.end_flag;
    
    if (messageContent && messageContent.length > 0) {
        NSNumber* objSeq = [NSNumber numberWithLongLong:messageSeqId];
        ZegoAIAgentSubtitlesMessageModel* existAsrMsgModel = [self.tempAsrMsgList objectForKey:messageId];
        if (existAsrMsgModel == nil) {
            // 如果是新消息，创建一个新的消息模型并添加到临时列表和聊天列表中
            existAsrMsgModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
            existAsrMsgModel.seqId = messageSeqId;
            existAsrMsgModel.isMine = YES;  // 标记为用户自己的消息
            existAsrMsgModel.content = messageContent;
            existAsrMsgModel.round = messageRound;
            existAsrMsgModel.end_flag = messageEndFlag;
            existAsrMsgModel.message_id = messageId;
            existAsrMsgModel.messageTimeStamp = messageTimeStamp;
            [self.tempAsrMsgList setObject:existAsrMsgModel forKey:messageId];
            [self insertCurMsgModel:messageCommand withMsgModel:existAsrMsgModel];
        }else if(existAsrMsgModel.message_id && [existAsrMsgModel.message_id isEqualToString: messageId]){
            if (messageSeqId < existAsrMsgModel.seqId) {
                // 如果当前显示的item的seqId已经是最新的了，就不需要再更新文本内容
            }else{
                // 更新现有消息的内容并刷新表格
                existAsrMsgModel.content = messageContent;
                existAsrMsgModel.seqId = messageSeqId; // 更新seqId
                [self reloadMessages]; // 刷新显示
            }
        }
    }
}

// 处理接收到的LLM(大语言模型)文本，更新聊天信息
-(void)handleRecvLLMMessage:(ZegoAIAgentAudioSubtitlesMessage*)message{
    int messageCmd =message.cmd;
    long long messageSeqId =message.seq_id;
    long long messageRound =message.round;
    long messageTimeStamp =message.timestamp;
    
    NSString* messageContent = message.data.text;
    NSString* messageId = message.data.message_id;
    BOOL messageEndFlag = message.data.end_flag;
    
    if (messageContent && messageContent.length > 0) {
        NSNumber* objSeqId = [NSNumber numberWithLongLong:messageSeqId];
        ZegoAIAgentSubtitlesMessageModel* existAsrMsgModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
        existAsrMsgModel.seqId = messageSeqId;
        existAsrMsgModel.isMine = NO;  // 标记为非用户自己的消息（AI回复）
        existAsrMsgModel.content = messageContent;
        existAsrMsgModel.round = messageRound;
        existAsrMsgModel.message_id = messageId;
        existAsrMsgModel.end_flag = messageEndFlag;
        existAsrMsgModel.messageTimeStamp = messageTimeStamp;
        
        NSMutableDictionary<NSNumber*,ZegoAIAgentSubtitlesMessageModel*>* existAsrMsgList = [self.tempLLMMsgList objectForKey:@(messageRound)];
        if (existAsrMsgList == nil) {
            // 如果是该消息id的第一条内容，创建新的存储容器
            existAsrMsgList = [[NSMutableDictionary alloc]initWithCapacity:5];
            [existAsrMsgList setObject:existAsrMsgModel forKey:objSeqId];
            [self.tempLLMMsgList setObject:existAsrMsgList forKey:@(messageRound)];
            
            // 创建一个新的消息模型添加到聊天列表中
            ZegoAIAgentSubtitlesMessageModel* chatTableCellModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
            chatTableCellModel.seqId = messageSeqId;
            chatTableCellModel.isMine = NO;
            chatTableCellModel.content = messageContent;
            chatTableCellModel.round = messageRound;
            chatTableCellModel.message_id = messageId;
            chatTableCellModel.end_flag = messageEndFlag;
            chatTableCellModel.messageTimeStamp = messageTimeStamp;
            [self insertCurMsgModel:messageCmd withMsgModel:chatTableCellModel];
        } else {
            // 判断message_id变化
            id firstSeqIdKey = [existAsrMsgList allKeys].firstObject;
            ZegoAIAgentSubtitlesMessageModel* firstValue = [existAsrMsgList objectForKey:firstSeqIdKey];
            if (![messageId isEqualToString:firstValue.message_id]) {
                //1.同个round来了一条messageId不同的消息，则判断seqId，如果当前的seqId比保存的更大，
                //则把原来保存的全部删除，用新的messageId及后续的同messageId消息
                
                // 遍历所有键，找到最大值
                NSArray *seqIDKeys = [existAsrMsgList allKeys];
                NSNumber *maxSeqIdKey = [seqIDKeys firstObject];
                for (NSNumber *seqIdKey in seqIDKeys) {
                    if ([seqIdKey compare:maxSeqIdKey] == NSOrderedDescending) {
                        maxSeqIdKey = seqIdKey;
                    }
                }
                
                // 如果新消息的seqId大于已保存消息的最大seqId，则删除所有旧消息
                if (messageSeqId > [maxSeqIdKey longLongValue]) {
                    [existAsrMsgList removeAllObjects];
                    
                    // 同时需要从chatMsgList中删除对应的消息，并记住原来的位置
                    ZegoAIAgentSubtitlesMessageModel* oldMsgModel = [self queryMsgModelWithMessageId:firstValue.message_id];
                    NSInteger oldIndex = -1;
                    if (oldMsgModel) {
                        for (NSInteger i = 0; i < self.chatMsgList.count; i++) {
                            ZegoAIAgentSubtitlesMessageModel* msgModel = self.chatMsgList[i];
                            if ([msgModel.message_id isEqualToString:firstValue.message_id]) {
                                oldIndex = i; // 记住原来的位置
                                [self.chatMsgList removeObjectAtIndex:i];
                                break;
                            }
                        }
                    }
                    
                    // 创建新的消息模型并替换到原来的位置
                    ZegoAIAgentSubtitlesMessageModel* newMsgModel = [[ZegoAIAgentSubtitlesMessageModel alloc] init];
                    newMsgModel.seqId = messageSeqId;
                    newMsgModel.isMine = NO;
                    newMsgModel.content = messageContent;
                    newMsgModel.round = messageRound;
                    newMsgModel.message_id = messageId;
                    newMsgModel.end_flag = messageEndFlag;
                    newMsgModel.messageTimeStamp = messageTimeStamp;
                    
                    if (oldIndex >= 0) {
                        // 插入到原来的位置，而不是插入到末尾
                        [self.chatMsgList insertObject:newMsgModel atIndex:oldIndex];
                        [self reloadMessages];
                    } else {
                        // 如果没有找到原来的位置，则正常插入
                        [self insertCurMsgModel:messageCmd withMsgModel:newMsgModel];
                    }
                }
            }
            
            // 如果已有该消息id的记录，添加新的片段到现有记录中
            // 注意：即使之前收到过end_flag=1的消息，这里也会继续处理同一message_id的新内容
            // 这是为了应对网络延迟导致的消息乱序到达情况
            [existAsrMsgList setObject:existAsrMsgModel forKey:objSeqId];
            
            // 获取所有键并按序列号排序
            // 这是第一处排序逻辑：将LLM消息片段按照seqId从小到大排序
            NSArray *seqIdKeysArray = [existAsrMsgList allKeys];
            NSArray * sortedSeqIdsArray = [seqIdKeysArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSNumber* obj1N = (NSNumber*)obj1;
                NSNumber* obj2N = (NSNumber*)obj2;
                return [obj1N longLongValue] > [obj2N longLongValue];  // 返回大于表示将obj1放在obj2后面，实现升序排序
            }];
            
            // 拼接totalContent
            NSString* totalContent = @"";
            for (NSNumber* seqIdKey in sortedSeqIdsArray) {
                // 按照排序后的顺序拼接所有消息片段
                ZegoAIAgentSubtitlesMessageModel* temp = [existAsrMsgList objectForKey:seqIdKey];
                totalContent = [totalContent stringByAppendingString:temp.content];
            }
            
            // 更新现有消息模型的内容和属性
            ZegoAIAgentSubtitlesMessageModel* curUserChatMsgModel = [self queryMsgModelWithMessageId:messageId];
            curUserChatMsgModel.seqId = messageSeqId;
            curUserChatMsgModel.isMine = NO;
            curUserChatMsgModel.end_flag = messageEndFlag;
            curUserChatMsgModel.messageTimeStamp = messageTimeStamp;
            curUserChatMsgModel.content = totalContent;
            [self reloadMessages]; // 刷新显示
        }
    }
    
    //end_flag标志不可靠不能依赖，同回合里可能有多个end_flag=true,且可能不是最后一条消息到达,这里采用延迟删除
    if (self.roundEndFlag.count <3) {
        [self.roundEndFlag addObject:@(messageRound)];
    }else{
        NSNumber* key = self.roundEndFlag.firstObject;
        
        [self.tempLLMMsgList removeObjectForKey:key];
        [self.roundEndFlag removeObject:key];
    }
}

// 向聊天列表中插入新的消息模型
-(void)insertCurMsgModel:(int)cmd
            withMsgModel:(ZegoAIAgentSubtitlesMessageModel*)curMsgModel{
    if (curMsgModel == nil) {
        return;
    }

    // 将消息添加到聊天列表末尾
    [self.chatMsgList addObject:curMsgModel];

    // 刷新显示
    [self reloadMessages];
}

// 替换聊天列表中指定位置的消息模型
-(void)replaceCurMsgModel:(int)cmd
             withMsgModel:(ZegoAIAgentSubtitlesMessageModel*)curMsgModel
                  atIndex:(NSInteger)index{
    if (curMsgModel == nil || index < 0 || index >= self.chatMsgList.count) {
        return;
    }
    NSLog(@"chatMsgList replace:cmd=%d, seqId=%lld, timeStamp=%lld, message=%@, isMine=%d, index=%ld",
          cmd,
          curMsgModel.seqId,
          curMsgModel.messageTimeStamp,
          curMsgModel.content,
          curMsgModel.isMine,
          (long)index);

    // 替换到原来的位置，而不是插入到末尾
    [self.chatMsgList replaceObjectAtIndex:index withObject:curMsgModel];

    // 刷新显示
    [self reloadMessages];
}

// 重新加载表格
-(void)reloadMessages {
    // 刷新表格
    [self reloadData];

    // 滚动到底部
    if (self.chatMsgList.count > 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.chatMsgList.count-1 inSection:0];
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

// 根据消息ID查询消息模型
-(ZegoAIAgentSubtitlesMessageModel*)queryMsgModelWithMessageId:(NSString*)msgId{
    // 遍历聊天列表查找匹配的message_id
    for (ZegoAIAgentSubtitlesMessageModel* msgModel in self.chatMsgList) {
        if ([msgModel.message_id isEqualToString:msgId]) {
            return msgModel;
        }
    }
    return nil;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 返回表中有多少个部分
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    // 使用chatMsgList的count
    return self.chatMsgList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ZegoAudioChatTableViewCell";
    ZegoAIAgentSubtitlesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ZegoAIAgentSubtitlesTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.colors = self.colors;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 从chatMsgList中直接根据索引获取消息模型
    ZegoAIAgentSubtitlesMessageModel* msgModel = self.chatMsgList[indexPath.row];
    
    cell.msgModel = msgModel;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 设置单元格的高度
    ZegoAIAgentSubtitlesMessageModel* msgModel = self.chatMsgList[indexPath.row];
    CGRect rect = msgModel.boundingBox;
    return rect.size.height + CELL_TOP_MARGIN;
}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
@end
