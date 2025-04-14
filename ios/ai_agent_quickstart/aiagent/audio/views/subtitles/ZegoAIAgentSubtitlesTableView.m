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
@property (nonatomic, assign) long msgTotalCount;                                                       // 消息总数计数器
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,ZegoAIAgentSubtitlesMessageModel*>* chatMsgList;       // 存储所有聊天消息的字典，键为消息索引
@property (nonatomic, strong) NSMutableArray<ZegoAIAgentSubtitlesMessageModel*>* sortedChatMsgList;                // 按seqId排序的消息数组，用于展示
@property (nonatomic, strong) NSMutableDictionary<NSString*,ZegoAIAgentSubtitlesMessageModel*>* tempAsrMsgList;    // 临时存储ASR(语音识别)消息的字典，键为message_id
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSMutableDictionary<NSNumber*, ZegoAIAgentSubtitlesMessageModel*>*>* tempLLMMsgList;  // 临时存储LLM(大语言模型)消息的嵌套字典，外层键为message_id，内层键为seqId
@property (nonatomic, strong) NSMutableArray<NSString*>* tempDelayRemoveLLMsgList;                     // 延迟移除LLM消息的临时列表

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
        self.chatMsgList = [[NSMutableDictionary alloc] initWithCapacity:100];
        self.sortedChatMsgList = [[NSMutableArray alloc] initWithCapacity:100]; // 初始化排序后的消息数组
        self.msgTotalCount = 0;
        self.tempAsrMsgList = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.tempLLMMsgList = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.tempDelayRemoveLLMsgList = [[NSMutableArray alloc] initWithCapacity:5];

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
-(void)handleRecvAsrMessage:(ZegoAIAgentAudioSubtitlesMessage*)msgDict{
    int cmd =msgDict.cmd;
    long long seqId =msgDict.seq_id;
    long long round =msgDict.round;
    long timeStamp =msgDict.timestamp;
    
    NSString* content = msgDict.data.text;
    NSString* message_id = msgDict.data.message_id;
    BOOL end_flag = msgDict.data.end_flag;
    
    if (content && content.length > 0) {
        NSNumber* objSeq = [NSNumber numberWithLongLong:seqId];
        ZegoAIAgentSubtitlesMessageModel* existAsrMsgModel = [self.tempAsrMsgList objectForKey:message_id];
        if (existAsrMsgModel == nil) {
            // 如果是新消息，创建一个新的消息模型并添加到临时列表和聊天列表中
            existAsrMsgModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
            existAsrMsgModel.seqId = seqId;
            existAsrMsgModel.isMine = YES;  // 标记为用户自己的消息
            existAsrMsgModel.content = content;
            existAsrMsgModel.round = round;
            existAsrMsgModel.end_flag = end_flag;
            existAsrMsgModel.message_id = message_id;
            existAsrMsgModel.messageTimeStamp = timeStamp;
            [self.tempAsrMsgList setObject:existAsrMsgModel forKey:message_id];
            [self insertCurMsgModel:cmd withMsgModel:existAsrMsgModel];
        }else if(existAsrMsgModel.message_id && [existAsrMsgModel.message_id isEqualToString: message_id]){
            if (seqId < existAsrMsgModel.seqId) {
                // 如果当前显示的item的seqId已经是最新的了，就不需要再更新文本内容
                 NSLog(@"recvasr curSeqId=%lld < existAsrMsgModel.seqId=%lld", seqId, existAsrMsgModel.seqId);
            }else{
                // 更新现有消息的内容并刷新表格
                existAsrMsgModel.content = content;
                existAsrMsgModel.seqId = seqId; // 更新seqId
                [self resortAndReloadMessages]; // 重新排序并刷新
            }
        }
    }
}

// 处理接收到的LLM(大语言模型)文本，更新聊天信息
-(void)handleRecvLLMMessage:(ZegoAIAgentAudioSubtitlesMessage*)msgDict{
    int cmd =msgDict.cmd;
    long long seqId =msgDict.seq_id;
    long long round =msgDict.round;
    long timeStamp =msgDict.timestamp;
    
    NSString* content = msgDict.data.text;
    NSString* message_id = msgDict.data.message_id;
    BOOL end_flag = msgDict.data.end_flag;
    
    if (content && content.length > 0) {
        NSNumber* objSeq = [NSNumber numberWithLongLong:seqId];
        ZegoAIAgentSubtitlesMessageModel* existAsrMsgModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
        existAsrMsgModel.seqId = seqId;
        existAsrMsgModel.isMine = NO;  // 标记为非用户自己的消息（AI回复）
        existAsrMsgModel.content = content;
        existAsrMsgModel.round = round;
        existAsrMsgModel.message_id = message_id;
        existAsrMsgModel.end_flag = end_flag;
        existAsrMsgModel.messageTimeStamp = timeStamp;
        
        NSMutableDictionary<NSNumber*,ZegoAIAgentSubtitlesMessageModel*>* existAsrMsgList = [self.tempLLMMsgList objectForKey:message_id];
        if (existAsrMsgList == nil) {
            // 如果是该消息id的第一条内容，创建新的存储容器
            existAsrMsgList = [[NSMutableDictionary alloc]initWithCapacity:5];
            [existAsrMsgList setObject:existAsrMsgModel forKey:objSeq];
            [self.tempLLMMsgList setObject:existAsrMsgList forKey:message_id];
            
            // 创建一个新的消息模型添加到聊天列表中
            ZegoAIAgentSubtitlesMessageModel* chatTableCellModel =  [[ZegoAIAgentSubtitlesMessageModel alloc]init];
            chatTableCellModel.seqId = seqId;
            chatTableCellModel.isMine = NO;
            chatTableCellModel.content = content;
            chatTableCellModel.round = round;
            chatTableCellModel.message_id = message_id;
            chatTableCellModel.end_flag = end_flag;
            chatTableCellModel.messageTimeStamp = timeStamp;
            [self insertCurMsgModel:cmd withMsgModel:chatTableCellModel];
        } else {
            // 如果已有该消息id的记录，添加新的片段到现有记录中
            // 注意：即使之前收到过end_flag=1的消息，这里也会继续处理同一message_id的新内容
            // 这是为了应对网络延迟导致的消息乱序到达情况
            [existAsrMsgList setObject:existAsrMsgModel forKey:objSeq];
            
            // 获取所有键并按序列号排序
            // 这是第一处排序逻辑：将LLM消息片段按照seqId从小到大排序
            NSArray *keysArray = [existAsrMsgList allKeys];
            NSArray * sortedArray = [keysArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSNumber* obj1N = (NSNumber*)obj1;
                NSNumber* obj2N = (NSNumber*)obj2;
                return [obj1N longLongValue] > [obj2N longLongValue];  // 返回大于表示将obj1放在obj2后面，实现升序排序
            }];
            
            NSString* totalContent = @"";
//            long long lastSeq = 0;
            for (NSNumber* key in sortedArray) {
                // 注释的代码是实现等待逻辑，确保消息片段是连续的，例如2,3,4,6...，只会显示2,3,4
//                long long curItemSeqId = [key longLongValue];
//                if (lastSeq == 0) {
//                    lastSeq = curItemSeqId;
//                }else if(curItemSeqId - lastSeq > 1){
//                    break;
//                }else{
//                    lastSeq = curItemSeqId;
//                }
                
                // 按照排序后的顺序拼接所有消息片段
                ZegoAIAgentSubtitlesMessageModel* temp = [existAsrMsgList objectForKey:key];
                totalContent = [totalContent stringByAppendingString:temp.content];
            }
            
            // 更新现有消息模型的内容和属性
            ZegoAIAgentSubtitlesMessageModel* curUserChatMsgModel = [self queryMsgModelWithMessageId:message_id];
            curUserChatMsgModel.seqId = seqId;
            curUserChatMsgModel.isMine = NO;
            curUserChatMsgModel.end_flag = end_flag;
            curUserChatMsgModel.messageTimeStamp = timeStamp;
            curUserChatMsgModel.content = totalContent;
            [self resortAndReloadMessages]; // 重新排序并刷新
        }
    }
    
    // 处理消息结束标志
    if (end_flag) {
        // 这里不会立即清理当前message_id的缓存，而是将其加入延迟清理列表
        // 这样设计是为了处理网络延迟导致的消息乱序到达情况，即使收到end_flag=1，
        // 仍可能有该message_id的消息片段延迟到达
        
        // 当延迟清理列表中累积了超过2条不同的已完成消息时，才进行批量清理
        if (self.tempDelayRemoveLLMsgList.count > 2) {
            // 遍历所有待清理的message_id（这些都是不同消息，每个都已收到end_flag=1）
            for (NSString* item in  self.tempDelayRemoveLLMsgList) {
                // 记录日志前再次对消息片段进行排序，用于生成完整的seqId序列日志
                // 这是第二处排序逻辑：同样按照seqId从小到大排序
                NSMutableDictionary<NSNumber*,ZegoAIAgentSubtitlesMessageModel*>* tempLLMMsgList = [self.tempLLMMsgList objectForKey:item];
                NSArray *keysArray = [tempLLMMsgList allKeys];
                NSArray * sortedArray = [keysArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    NSNumber* obj1N = (NSNumber*)obj1;
                    NSNumber* obj2N = (NSNumber*)obj2;
                    return [obj1N longLongValue] > [obj2N longLongValue];  // 返回大于表示将obj1放在obj2后面，实现升序排序
                }];
                
                // 生成用于日志记录的seqId序列字符串
                NSString* roundSeqId=@"";
                for (int i=0; i<sortedArray.count; i++) {
                    roundSeqId = [roundSeqId stringByAppendingFormat:@"%lld,", [[sortedArray objectAtIndex:i] longLongValue]];
                }
                
                // 记录日志并从临时存储中移除该message_id的所有消息片段
                 NSLog(@"recvllmtts remove round=%lld, totalSeqStr=%@, message_id=%@", round, roundSeqId, item);
                [self.tempLLMMsgList removeObjectForKey:item];
            }
            // 清空延迟清理列表，开始新一轮的累积
            [self.tempDelayRemoveLLMsgList removeAllObjects];
        }
        // 将当前收到end_flag=1的message_id添加到延迟清理列表中
        // 注意：这不会立即清理其缓存，而是等待累积足够数量后再批量清理
        [self.tempDelayRemoveLLMsgList addObject:message_id];
    }
}

// 向聊天列表中插入新的消息模型
-(void)insertCurMsgModel:(int)cmd
            withMsgModel:(ZegoAIAgentSubtitlesMessageModel*)curMsgModel{
    if (curMsgModel == nil) {
        return;
    }
    NSLog(@"chatMsgList insert:cmd=%d, seqId=%lld, timeStamp=%lld, message=%@, isMine=%d",
          cmd,
          curMsgModel.seqId,
          curMsgModel.messageTimeStamp,
          curMsgModel.content,curMsgModel.isMine);
    
    // 将消息添加到聊天列表中，键为消息计数值，并自增计数器
    // 注意：chatMsgList存储的是最终显示在UI上的消息，而tempLLMMsgList存储的是消息片段
    [self.chatMsgList setObject:curMsgModel forKey:[NSNumber numberWithLong:self.msgTotalCount++]];
    
    // 对消息重新排序并刷新显示
    [self resortAndReloadMessages];
}

// 对消息按seqId进行排序并重新加载表格
-(void)resortAndReloadMessages {
    // 清空排序数组
    [self.sortedChatMsgList removeAllObjects];
    
    // 将所有消息添加到数组中
    NSArray *keys = [self.chatMsgList allKeys];
    for (NSNumber *key in keys) {
        ZegoAIAgentSubtitlesMessageModel *msgModel = [self.chatMsgList objectForKey:key];
        [self.sortedChatMsgList addObject:msgModel];
    }
    
    // 按seqId排序
    [self.sortedChatMsgList sortUsingComparator:^NSComparisonResult(ZegoAIAgentSubtitlesMessageModel *obj1, ZegoAIAgentSubtitlesMessageModel *obj2) {
        if (obj1.seqId < obj2.seqId) {
            return NSOrderedAscending;
        } else if (obj1.seqId > obj2.seqId) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // 刷新表格
    [self reloadData];
    
    // 滚动到底部
    if (self.sortedChatMsgList.count > 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.sortedChatMsgList.count-1 inSection:0];
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

// 根据消息ID查询消息模型
-(ZegoAIAgentSubtitlesMessageModel*)queryMsgModelWithMessageId:(NSString*)msgId{
    // 遍历聊天列表查找匹配的message_id
    NSArray* keysArray = [self.chatMsgList allKeys];
    for (int i=0; i<keysArray.count; i++) {
        NSNumber* itemKey = keysArray[i];
        ZegoAIAgentSubtitlesMessageModel* itemValue = [self.chatMsgList objectForKey:itemKey];
        if ([itemValue.message_id isEqualToString:msgId]) {
            return itemValue;
        }
    }
    return nil;
}

// 重新加载表格视图并滚动到最底部 - 已被resortAndReloadMessages替代
-(void)reloadTableViewInternal{
    [self resortAndReloadMessages];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 返回表中有多少个部分
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    // 使用排序后的数组count
    return self.sortedChatMsgList.count;
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
    
    // 从排序后的数组中获取消息模型
    ZegoAIAgentSubtitlesMessageModel* msgModel = [self.sortedChatMsgList objectAtIndex:indexPath.row];
    
    cell.msgModel = msgModel;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 设置单元格的高度
    ZegoAIAgentSubtitlesMessageModel* msgModel = [self.sortedChatMsgList objectAtIndex:indexPath.row];
    CGRect rect = msgModel.boundingBox;
    return rect.size.height + CELL_TOP_MARGIN;
}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
@end
