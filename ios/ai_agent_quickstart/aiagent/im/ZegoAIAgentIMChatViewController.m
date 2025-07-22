#import "ZegoAIAgentIMChatViewController.h"

#import <objc/runtime.h>

#import "ZIM/ZIM.h"
#import "ZegoKey.h"
#import "ZegoAIAgentServiceAPI.h"
#import "ZegoAIAgentAudioViewController.h"

@interface ZegoAIAgentIMChatViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ZIMEventHandler, UIGestureRecognizerDelegate>

// ZIM实例
@property (nonatomic, strong) ZIM *zim;

// UI组件
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputTextField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UILabel *titleLabel;

// 消息数据
@property (nonatomic, strong) NSMutableArray<ZIMMessage *> *messages;

// ZIM 登录状态
@property (nonatomic, assign) BOOL isZIMLoggedIn;

// 添加键盘处理相关属性
@property (nonatomic, strong) UIView *toolBar;  // 保存工具栏引用
@property (nonatomic, assign) CGFloat keyboardHeight;  // 保存键盘高度

// Loading 相关属性
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ZegoAIAgentIMChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    // 初始化消息数组
    self.messages = [NSMutableArray array];
    // 设置UI
    [self setupUI];
    
    // 显示 loading
    [self showLoading];

    // 先初始化Agent Info，完成后再初始化ZIM
    [self initializeAgentInfo];

    // 添加键盘通知监听
    [self setupKeyboardNotifications];

    // 添加应用程序状态变化通知监听
    [self setupAppStateNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchHistoryMessagesIfNeeded];
}

#pragma mark - UI设置

- (void)setupUI {
    // 设置整体背景色为白色
    self.view.backgroundColor = [UIColor whiteColor];

    // 设置顶部导航栏样式
    UIView *navBar = [[UIView alloc] init];
    navBar.backgroundColor = [UIColor systemBlueColor];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:navBar];

    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = [[ZegoAIAgentServiceAPI sharedInstance] getAgentName];
    [navBar addSubview:self.titleLabel];

    // 语音聊天按钮
    UIButton *audioChatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [audioChatButton setTitle:@"Voice" forState:UIControlStateNormal];
    [audioChatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [audioChatButton addTarget:self action:@selector(audioChatButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    audioChatButton.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:audioChatButton];

    // 创建底部工具栏
    UIView *toolBar = [[UIView alloc] init];
    self.toolBar = toolBar;  // 保存工具栏引用
    toolBar.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:toolBar];

    // 输入框样式优化
    self.inputTextField = [[UITextField alloc] init];
    self.inputTextField.placeholder = @"Ask anything...";
    self.inputTextField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"Ask anything...."
        attributes:@{
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]  // 灰色占位符
        }];
    self.inputTextField.backgroundColor = [UIColor whiteColor];
    self.inputTextField.textColor = [UIColor blackColor];  // 设置输入文字颜色
    self.inputTextField.font = [UIFont systemFontOfSize:15];  // 设置字体大小
    self.inputTextField.layer.cornerRadius = 18;
    self.inputTextField.layer.masksToBounds = YES;
    self.inputTextField.layer.borderWidth = 0.5;  // 添加边框
    self.inputTextField.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;  // 浅灰色边框
    self.inputTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
    self.inputTextField.leftViewMode = UITextFieldViewModeAlways;
    self.inputTextField.returnKeyType = UIReturnKeySend;
    self.inputTextField.delegate = self;
    self.inputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [toolBar addSubview:self.inputTextField];

    // 发送按钮样式优化
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[[UIColor systemBlueColor] colorWithAlphaComponent:0.6] forState:UIControlStateHighlighted];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [toolBar addSubview:self.sendButton];

    // 聊天消息列表
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];  // 设置为透明
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MessageCell"];
    [self.view addSubview:self.tableView];

    // 保存底部约束以便后续更新
    NSLayoutConstraint *toolBarBottomConstraint = [toolBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        // 导航栏约束
        [navBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [navBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [navBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [navBar.heightAnchor constraintEqualToConstant:44],

        // 标题标签约束
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:navBar.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],

        // 语音聊天按钮约束
        [audioChatButton.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor constant:-16],
        [audioChatButton.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],

        // 底部工具栏约束
        [toolBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [toolBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        toolBarBottomConstraint, // 使用变量而不是直接创建约束
        [toolBar.heightAnchor constraintEqualToConstant:60],

        // 输入框约束
        [self.inputTextField.leadingAnchor constraintEqualToAnchor:toolBar.leadingAnchor constant:16],
        [self.inputTextField.centerYAnchor constraintEqualToAnchor:toolBar.centerYAnchor],
        [self.inputTextField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8],
        [self.inputTextField.heightAnchor constraintEqualToConstant:36],

        // 发送按钮约束
        [self.sendButton.trailingAnchor constraintEqualToAnchor:toolBar.trailingAnchor constant:-16],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:toolBar.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:60],

        // 表格视图约束
        [self.tableView.topAnchor constraintEqualToAnchor:navBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:toolBar.topAnchor]
    ]];

    // 保存底部约束以便键盘处理
    objc_setAssociatedObject(self.toolBar, "bottomConstraint", toolBarBottomConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // 添加点击手势来关闭键盘
    [self setupTapGesture];
}

- (void) initializeAgentInfo{
    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] getAgentInfoWithCompletion:^(ZegoAIGetAgentInfoResponse * _Nonnull response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if (response.code == 0) {
            NSLog(@"get agent info successful");

            // Agent Info 初始化成功后，开始初始化 ZIM
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf initializeZIM];
            });
        } else {
            NSLog(@"get agent info failed: %@", response.message);

            // Agent Info 初始化失败，隐藏 loading 并显示错误
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf hideLoading];
                [strongSelf showToast:[NSString stringWithFormat:@"初始化失败: %@", response.message]];
            });
        }
    }];
}

#pragma mark - ZIM初始化和聊天

- (void)initializeZIM {
    // 创建ZIM实例
    ZIMAppConfig *appConfig = [[ZIMAppConfig alloc] init];
    appConfig.appID = kZegoAppId;
    self.zim = [ZIM createWithAppConfig:appConfig];

    // 设置事件处理器
    [self.zim setEventHandler:self];

    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] getTokenWithCompletion:^(ZegoAIGetTokenResponse * _Nonnull response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        // 检查 token 获取是否成功
        if (!response.token || response.token.length == 0) {
            NSLog(@"Failed to get token");
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf hideLoading];
                [strongSelf showToast:@"获取Token失败"];
            });
            return;
        }

        // 登录ZIM
        ZIMLoginConfig *config = [[ZIMLoginConfig alloc] init];
        config.userName = [[ZegoAIAgentServiceAPI sharedInstance] getUserId];
        config.token = response.token;

        // 使用用户ID登录
        [strongSelf.zim loginWithUserID:[[ZegoAIAgentServiceAPI sharedInstance] getUserId] config:config callback:^(ZIMError * _Nonnull errorInfo) {
            // 隐藏 loading（无论登录成功还是失败）
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf hideLoading];
            });

            if (errorInfo.code == 0) {
                NSLog(@"ZIM login successful, userID: %@", [[ZegoAIAgentServiceAPI sharedInstance] getUserId]);

                // 设置登录状态
                strongSelf.isZIMLoggedIn = YES;

                // 登录成功后获取历史消息
                [strongSelf fetchHistoryMessagesIfNeeded];
            } else {
                NSLog(@"ZIM login failed: %@", errorInfo.message);
                strongSelf.isZIMLoggedIn = NO;
                [strongSelf showToast:[NSString stringWithFormat:@"ZIM login failed: %@", errorInfo.message]];
            }
        }];
    }];
}

#pragma mark - 消息发送和接收

- (void)sendMessage {
    NSString *messageText = self.inputTextField.text;
    if (messageText.length == 0) {
        return;
    }

    // 先收起键盘
    self.inputTextField.text = @"";
    [self.inputTextField resignFirstResponder];

    // 创建文本消息
    ZIMTextMessage *zimMessage = [[ZIMTextMessage alloc] init];
    zimMessage.message = messageText;

    // 消息发送配置
    ZIMMessageSendConfig *config = [[ZIMMessageSendConfig alloc] init];
    config.priority = ZIMMessagePriorityMedium;

    // 消息发送通知
    ZIMMessageSendNotification *notification = [[ZIMMessageSendNotification alloc] init];
    notification.onMessageAttached = ^(ZIMMessage * _Nonnull message) {
        // 发送前的回调，可以在这里提前展示UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messages addObject:message];
            [self.tableView reloadData];
            [self scrollToBottom];
        });
    };

    // 发送消息
    [self.zim sendMessage:zimMessage
        toConversationID:[[ZegoAIAgentServiceAPI sharedInstance] getAgentRotbotId]
        conversationType:ZIMConversationTypePeer
                  config:config
            notification:notification
               callback:^(ZIMMessage * _Nonnull message, ZIMError * _Nonnull errorInfo) {
        if (errorInfo.code == 0) {
            NSLog(@"Message sent successfully");
        } else {
            NSLog(@"Failed to send message: %@", errorInfo.message);
            [self showToast:[NSString stringWithFormat:@"Failed to send message: %@", errorInfo.message]];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZIMMessage *message = self.messages[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];

    // 设置单元格背景为透明
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    // 清除现有子视图
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    // 创建气泡视图
    UIView *bubbleView = [[UIView alloc] init];
    bubbleView.layer.cornerRadius = 12;
    bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:bubbleView];

    // 创建消息标签
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.numberOfLines = 0;
    messageLabel.font = [UIFont systemFontOfSize:15];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [bubbleView addSubview:messageLabel];

    // 设置消息内容
    if ([message isKindOfClass:[ZIMTextMessage class]]) {
        ZIMTextMessage *textMessage = (ZIMTextMessage *)message;
        messageLabel.text = textMessage.message;
    }

    // 判断是发送还是接收的消息
    BOOL isSentMessage = [message.senderUserID isEqualToString:[[ZegoAIAgentServiceAPI sharedInstance] getUserId]];

    if (isSentMessage) {
        // 发送的消息 - 蓝色气泡，白色文字
        bubbleView.backgroundColor = [UIColor systemBlueColor];
        messageLabel.textColor = [UIColor whiteColor];

        // 设置约束 - 右侧对齐
        [NSLayoutConstraint activateConstraints:@[
            [bubbleView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
            [bubbleView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [bubbleView.widthAnchor constraintLessThanOrEqualToConstant:250],
            [bubbleView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],

            [messageLabel.topAnchor constraintEqualToAnchor:bubbleView.topAnchor constant:8],
            [messageLabel.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:12],
            [messageLabel.trailingAnchor constraintEqualToAnchor:bubbleView.trailingAnchor constant:-12],
            [messageLabel.bottomAnchor constraintEqualToAnchor:bubbleView.bottomAnchor constant:-8]
        ]];
    } else {
        // 接收的消息 - 浅灰色气泡，深色文字
        bubbleView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        messageLabel.textColor = [UIColor blackColor];

        // 设置约束 - 左侧对齐
        [NSLayoutConstraint activateConstraints:@[
            [bubbleView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
            [bubbleView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [bubbleView.widthAnchor constraintLessThanOrEqualToConstant:250],
            [bubbleView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],

            [messageLabel.topAnchor constraintEqualToAnchor:bubbleView.topAnchor constant:8],
            [messageLabel.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:12],
            [messageLabel.trailingAnchor constraintEqualToAnchor:bubbleView.trailingAnchor constant:-12],
            [messageLabel.bottomAnchor constraintEqualToAnchor:bubbleView.bottomAnchor constant:-8]
        ]];
    }

    // 禁用单元格的选中状态
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage];
    return YES;
}

#pragma mark - ZIMEventHandler

- (void)zim:(ZIM *)zim errorInfo:(ZIMError *)errorInfo {
    NSLog(@"ZIM错误: %@", errorInfo.message);
}

- (void)zim:(ZIM *)zim connectionStateChanged:(ZIMConnectionState)state event:(ZIMConnectionEvent)event extendedData:(NSDictionary *)extendedData {
    NSLog(@"ZIM连接状态变化: %ld", (long)state);
}

- (void)zim:(ZIM *)zim peerMessageReceived:(NSArray<ZIMMessage *> *)messageList info:(ZIMMessageReceivedInfo *)info fromUserID:(NSString *)fromUserID {
    NSLog(@"Received peer message - Sender ID: %@, Message count: %lu, Message details:", fromUserID, (unsigned long)messageList.count);
    for (ZIMMessage *message in messageList) {
        if ([message isKindOfClass:[ZIMTextMessage class]]) {
            ZIMTextMessage *textMessage = (ZIMTextMessage *)message;
            NSLog(@"Message ID: %lld, Send time: %llu, Message content: %@", textMessage.messageID, textMessage.timestamp, textMessage.message);
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // 将新消息添加到现有消息数组中
        [self.messages addObjectsFromArray:messageList];

        // 根据orderKey对所有消息进行排序
        [self.messages sortUsingComparator:^NSComparisonResult(ZIMMessage *msg1, ZIMMessage *msg2) {
            if (msg1.orderKey < msg2.orderKey) {
                return NSOrderedAscending;
            } else if (msg1.orderKey > msg2.orderKey) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];

        [self.tableView reloadData];
        [self scrollToBottom];
    });
}

#pragma mark - 辅助方法

- (void)scrollToBottom {
    NSInteger lastRow = [self.tableView numberOfRowsInSection:0] - 1;
    if (lastRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                            atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // 如果是模态跳转，不需要退出登录和销毁ZIM实例
    if (self.isBeingDismissed || self.isMovingFromParentViewController) {
        // 退出登录
        [self.zim logout];

        // 重置登录状态
        self.isZIMLoggedIn = NO;

        // 销毁ZIM实例
        [self.zim destroy];
    }
}

#pragma mark - 键盘处理

- (void)setupKeyboardNotifications {
    // 监听键盘显示通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];

    // 监听键盘隐藏通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

#pragma mark - 应用程序状态通知

- (void)setupAppStateNotifications {
    // 监听应用程序将进入前台的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationWillEnterForeground:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];

    // 监听应用程序已经进入前台的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // 应用程序即将进入前台时调用
    [self fetchHistoryMessagesIfNeeded];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // 应用程序已经变为活跃状态时调用
    [self fetchHistoryMessagesIfNeeded];
}


- (void)keyboardWillShow:(NSNotification *)notification {
    // 获取键盘高度
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardHeight = keyboardFrame.size.height;

    // 获取动画时间和曲线
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    // 获取保存的底部约束
    NSLayoutConstraint *toolBarBottomConstraint = objc_getAssociatedObject(self.toolBar, "bottomConstraint");

    // 更新约束
    toolBarBottomConstraint.constant = -self.keyboardHeight;

    // 使用与键盘相同的动画参数
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];

    [self.view layoutIfNeeded];
    [self scrollToBottom];

    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // 获取动画时间和曲线
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    // 获取保存的底部约束
    NSLayoutConstraint *toolBarBottomConstraint = objc_getAssociatedObject(self.toolBar, "bottomConstraint");

    // 重置约束
    toolBarBottomConstraint.constant = 0;

    // 使用与键盘相同的动画参数
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];

    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

// 修改点击手势的设置方法
- (void)setupTapGesture {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;

    // 添加手势代理
    tapGesture.delegate = self;

    // 将手势添加到tableView而不是整个view
    [self.tableView addGestureRecognizer:tapGesture];
}

// 实现手势代理方法
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 如果点击的是发送按钮，不触发手势
    if ([touch.view isDescendantOfView:self.sendButton]) {
        return NO;
    }
    // 如果点击的是输入框，不触发手势
    if ([touch.view isDescendantOfView:self.inputTextField]) {
        return NO;
    }
    return YES;
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.view endEditing:YES];
    }
}

- (void)dealloc {
    // 移除键盘通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];

        [self presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    });
}

- (void)audioChatButtonClicked {
    ZegoAIAgentAudioViewController *audioVC = [[ZegoAIAgentAudioViewController alloc] init];
    audioVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:audioVC animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 视图已经显示完成，可以在这里执行额外的刷新操作
    [self fetchHistoryMessagesIfNeeded];
}

- (void)fetchHistoryMessagesIfNeeded {
    // 检查 ZIM 实例是否存在
    if (!self.zim) {
        NSLog(@"ZIM instance not available, skipping history message fetch");
        return;
    }

    // 检查是否已经登录成功
    if (!self.isZIMLoggedIn) {
        NSLog(@"ZIM not logged in yet, skipping history message fetch");
        return;
    }

    ZIMMessageQueryConfig *config = [[ZIMMessageQueryConfig alloc] init];
    config.count = 50; // 拉取50条
    config.nextMessage = nil; // 从最新消息开始
    config.reverse = YES; // 从最后一页开始拉取

    [self.zim queryHistoryMessageByConversationID:[[ZegoAIAgentServiceAPI sharedInstance] getAgentRotbotId]
                                 conversationType:ZIMConversationTypePeer
                                           config:config
                                         callback:^(NSString * _Nonnull conversationID, ZIMConversationType conversationType, NSArray<ZIMMessage *> * _Nonnull messageList, ZIMError * _Nonnull errorInfo) {
        if (errorInfo.code == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.messages removeAllObjects];
                [self.messages addObjectsFromArray:messageList];
                [self.tableView reloadData];
                [self scrollToBottom];
            });
        } else {
            NSLog(@"Failed to fetch history messages: %@", errorInfo.message);
        }
    }];
}

#pragma mark - Loading Methods

- (void)showLoading {
    if (self.loadingView) {
        return; // 已经在显示 loading
    }

    // 创建 loading 背景视图
    self.loadingView = [[UIView alloc] init];
    self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingView];

    // 创建活动指示器
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.color = [UIColor whiteColor];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView addSubview:self.activityIndicator];

    // 创建加载文本
    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"正在初始化...";
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.font = [UIFont systemFontOfSize:16];
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView addSubview:loadingLabel];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        // loading 视图约束
        [self.loadingView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.loadingView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.loadingView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.loadingView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        // 活动指示器约束
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.loadingView.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.loadingView.centerYAnchor constant:-20],

        // 加载文本约束
        [loadingLabel.centerXAnchor constraintEqualToAnchor:self.loadingView.centerXAnchor],
        [loadingLabel.topAnchor constraintEqualToAnchor:self.activityIndicator.bottomAnchor constant:16]
    ]];

    // 开始动画
    [self.activityIndicator startAnimating];
}

- (void)hideLoading {
    if (!self.loadingView) {
        return; // 没有 loading 视图
    }

    // 停止动画
    [self.activityIndicator stopAnimating];

    // 移除视图
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
    self.activityIndicator = nil;
}

@end
