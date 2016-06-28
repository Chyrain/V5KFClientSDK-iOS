//
//  V5ChatViewController.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/18.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5ChatViewController.h"
#import "V5Util.h"
#import "V5ClientAgent.h"
#import "V5Message.h"
#import "V5TextMessage.h"
#import "V5LocationMessage.h"
#import "V5ImageMessage.h"
#import "CRInputFunctionView.h"
#import "V5MJRefresh.h"
#import "CRMessageCell.h"
#import "CRMessageFrame.h"
#import "V5MBProgressHUD.h"
#import "NSDate+V5Utils.h"
#import "V5AFNetworking.h"
#import "UITableView+V5Scroll.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CRConfigMcros.h"
#import "V5DBHelper.h"
#import "CRAVAudioPlayer.h"
#import "CRProgressHUD.h"
#import "UIViewController+V5BackButtonHandler.h"
@import AVFoundation;

#define TAG_AS_LINK 1
#define TAG_ALERT_RETRY 2
#define TAG_ALERT_QUIT 3
#define NUM_PER_PAGE 10
#define HUD_BG_COLOR RGBACOLOR(98, 98, 98, 0.9)
//是否无网络
#define kNetworkNotReachability ([V5AFNetworkReachabilityManager sharedManager].networkReachabilityStatus <= 0)

@interface V5ChatViewController ()<CRInputFunctionViewDelegate, CRMessageCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate> {
    BOOL isInit; //界面初始状态
    BOOL hasConnected; //是否建立过连接
    unsigned long previousTime;
    V5Message *openingAnswer;
    
    NSUInteger retryCount; //连接异常断开后自动重试次数计数器
}

@property (strong, nonatomic) V5MJRefreshHeaderView *head;
@property (nonatomic, strong) NSMutableArray<CRMessageFrame *> *dataSource;
@property (nonatomic, strong) NSDictionary *actionSheetDic;
@property (nonatomic, assign) NSInteger messageOffset;
@property (nonatomic, assign) BOOL isMessageFinish;
@property (nonatomic, strong) V5MBProgressHUD *progressHud;
//开场白模式
@property (nonatomic, assign) KV5ClientOpenMode openingMode;
//开场白参数
@property (nonatomic, strong) NSString *openingParam;

@end

@implementation V5ChatViewController {
    NSString *cacheTitle;
    CGFloat chatContentHeight;
    
    NSMutableArray *relativeQuesArray; // 相关问题
    NSArray *hotQuesArray; // 常见问题
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isMessageFinish = NO;
        _messageOffset = 0;
        _soundID = 1007;
        _numOfMessagesOnOpen = 0;
        _numOfMessagesOnRefresh = NUM_PER_PAGE;
        _openingMode = ClientOpenModeDefault;
        _showAvatar = YES;
//        _enableVoiceRecord = YES;
        retryCount = 0;
//        [self initChatTableView];
//        [self addRefreshViews];
//        [self addKeyBoardView];
    }
    return self;
}

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    V5Log(@"[viewDidLoad]");
    
    [self initChatTableView];
    [self addRefreshViews];
    //[self addKeyBoardView]; //移到viewWillAppear
    
    // 变量初始化
    isInit = YES;
    
    self.dataSource = [NSMutableArray array];
    relativeQuesArray = [NSMutableArray array];
    
    cacheTitle = self.title;
    
//    if (![V5ClientAgent shareClient].isConnected) {
//        [self startProgressHud];
//        cacheTitle = self.title;
//        self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
//    }
    [self startChatClient];
    //[self loadBaseViewsAndData];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)navigationShouldPopOnBackButton {
    // 不使用客服功能时退出消息客户端
    if ([V5ClientAgent shareClient].isConnected) {
        [[V5ClientAgent shareClient] stopClient];
    }
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.delegate respondsToSelector:@selector(clientViewWillAppear)]) {
        [self.delegate clientViewWillAppear];
    }
    [self addKeyBoardView]; // [修改]viewDidLoad之后添加，参数可传进VC
    [self loadBaseViewsAndData];
    
    if (![V5ClientAgent shareClient].isConnected) {
        [self startProgressHud];
        cacheTitle = self.title;
        self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(clientViewDidAppear)]) {
        [self.delegate clientViewDidAppear];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.delegate respondsToSelector:@selector(clientViewWillDisappear)]) {
        [self.delegate clientViewWillDisappear];
    }
    [[CRAVAudioPlayer sharedInstance] stopSound];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([self.delegate respondsToSelector:@selector(clientViewDidDisappear)]) {
        [self.delegate clientViewDidDisappear];
    }
}

/**
 *  当前ViewController是否正在显示
 *
 *  @return 是否正在显示，YES表示显示，NO表示未显示
 */
- (BOOL)isVisible {
    return (self.isViewLoaded && self.view.window);
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    V5Log(@"[viewDidUnload]");
    [[V5ClientAgent shareClient] stopClient];
    //[V5ClientAgent destroyDealloc];
}

- (void)dealloc {
    V5Log(@"[--- dealloc ---]");
    [[V5ClientAgent shareClient] stopClient];
}

#pragma mark ------ Do when viewDidLoad ------
- (void)startChatClient {
    V5Log(@"[startChatClient]");
    if (self.deviceToken) {
        [V5ClientAgent shareClient].config.deviceToken = self.deviceToken;
    }
    
    //开启服务
    [[V5ClientAgent shareClient] startClientWithDelegate:self];
}

- (void)startProgressHud {
    if (!self.progressHud) {
        self.progressHud = [[V5MBProgressHUD alloc] initWithView:self.view];
        self.progressHud.mode = V5MBProgressHUDModeIndeterminate;
        self.progressHud.opacity = 0.8;
        self.progressHud.dimBackground = NO;
        self.progressHud.color = HUD_BG_COLOR;
        //self.progressHud.labelText = V5LocalStr(@"v5_connecting", @"正在连接...");
        [self.view addSubview:self.progressHud];
    }
    [self.progressHud show:YES];
}

- (void)stopProgressHud {
    if (self.progressHud) {
        [self.progressHud hide:YES];
        [self.progressHud removeFromSuperview];
        self.progressHud = nil;
    }
}

- (void)initChatTableView {
    self.chatTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.chatTableView.delegate = self;
    self.chatTableView.dataSource = self;
    self.chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.chatTableView.backgroundColor = ChatTableViewBG;
    [self.view addSubview:self.chatTableView];
}

- (void)addRefreshViews {
    __weak typeof(self) weakSelf = self;
    
    _head = [V5MJRefreshHeaderView header];
    _head.lastUpdateTimeLabel.hidden = YES;
    _head.scrollView = self.chatTableView;
    _head.beginRefreshingBlock = ^(V5MJRefreshBaseView *refreshView) {
        if (weakSelf.isMessageFinish) {
            [weakSelf showToast:V5LocalStr(@"v5_no_more_message", @"没有更多消息")];
            [weakSelf.head endRefreshing];
        } else {
            //执行刷新请求
            [[V5ClientAgent shareClient] getMessagesWithOffset:weakSelf.messageOffset
                                                   messageSize:weakSelf.numOfMessagesOnRefresh];
        }
    };
}

- (void)addKeyBoardView {
    if (!self.footerView) {
        CGRect frame = CGRectMake(0,
                                  self.chatTableView.frame.origin.y + self.chatTableView.frame.size.height,
                                  self.view.bounds.size.width,
                                  INPUT_BAR_H);
        self.footerView = [[CRInputFunctionView alloc] initWithSuperVC:self delegate:self frame:frame];
        [self.view addSubview:self.footerView];
    }
}

- (void)loadBaseViewsAndData {
    previousTime = 0;
    [self.chatTableView reloadData];
    [self tableViewScrollToBottom:NO delay:YES];
}

#pragma mark ------ 横竖屏控制 ------

- (void)viewWillLayoutSubviews {
    //V5Log(@"viewWillLayoutSubviews");
    if (isInit) {
        isInit = NO;
        // 更新frame
        if (((CRInputFunctionView *)self.footerView).bottomShowType == BottomTypeNone) {
            [self updateFrame];
        }
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [(CRInputFunctionView *)self.footerView hideBottomView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // [修改]翻转屏需要[messageFrame updateFrame];
    for (CRMessageFrame *messageFrame in self.dataSource) {
        [messageFrame updateFrame];
    }
    
    [UIView animateWithDuration:duration animations:^{
        [(CRInputFunctionView *)self.footerView hideBottomView];
        [self updateFrame];
        [CRImageAvatarBrowser hideImage];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //V5Log(@"didRotateFromInterfaceOrientation");
}

- (void)updateFrame {
//    V5Log(@"[updateFrame]");
    self.chatTableView.frame = CGRectMake(self.view.bounds.origin.x,
                                          self.view.bounds.origin.y,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - INPUT_BAR_H);
    self.footerView.frame = CGRectMake(0,
                                       self.chatTableView.frame.size.height,
                                       self.view.bounds.size.width,
                                       INPUT_BAR_H);
//    V5Log(@"self.view.frame:%@ chatTableView.frame:%@",
//          NSStringFromCGRect(self.view.frame),
//          NSStringFromCGRect(self.chatTableView.frame));
    [self.chatTableView reloadData];
    [self tableViewScrollToBottom:NO];
}

#pragma mark -
/**
 *  转人工客服(控制消息)
 */
- (void)actionToSwitchWorker {
    //这是一个控制消息
    [[V5ClientAgent shareClient] switchToArtificialService];
//    V5ControlMessage *controlMessage = [[V5ClientAgent shareClient] switchToArtificialService];
//    [self dealTheMessage:controlMessage]; // [修改]不显示到消息列表
}

/**
 *  tableview滑到最底部
 *
 *  @param animation 是否允许动画
 */
- (void)tableViewScrollToBottom:(BOOL)animation {
    [self.chatTableView scrollToBottom:animation];
}

/**
 *  tableview滑到最底部，支持延迟滑动
 *
 *  @param animation 是否允许动画
 *  @param delay     是否延迟
 */
- (void)tableViewScrollToBottom:(BOOL)animation delay:(BOOL)delay {
    [self.chatTableView scrollToBottom:animation];
    // 图片加载中，等全部加载完成再滑动到底部
    BOOL hasImage = NO;
    if (delay) {
        for (CRMessageFrame *msgFrame in self.dataSource) {
            if (msgFrame.message.messageType == MessageType_Image || msgFrame.message.messageType == MessageType_Articles) {
                hasImage = YES;
            }
        }
    } else {
        if (self.dataSource.lastObject && (self.dataSource.lastObject.message.messageType == MessageType_Image
                || self.dataSource.lastObject.message.messageType == MessageType_Articles)) {
            hasImage = YES;
        }
    }
    if (hasImage) {
        // 加载含图片消息需要延时滑动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(150 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            V5Log(@"－－－ 延迟滚动到底部");
            [self.chatTableView scrollToBottom:animation];
        });
    }
}

/**
 *  显示提示信息
 *
 *  @param str 提示内容
 */
- (void)showToast:(NSString *)str {
    __block V5MBProgressHUD *hud = [[V5MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText = str;
    hud.mode = V5MBProgressHUDModeText;
    hud.opacity = 0.8;
    hud.dimBackground = NO;
    hud.color = HUD_BG_COLOR;
    hud.yOffset = -(self.view.frame.size.height - 200)/2; //-140; //
    [hud showAnimated:YES whileExecutingBlock:^{
        sleep(1);
    } completionBlock:^{
        [hud removeFromSuperview];
        hud = nil;
    }];
}


#pragma mark ------ V5MessageDelegate ------
/**
 *  Receive message
 *
 *  @param message V5Message
 */
- (void)receiveV5Message:(V5Message *)message {
    if ([self.delegate respondsToSelector:@selector(clientDidReceiveMessage:)]
        && message.direction != MessageDir_RelativeQuestion) {
        [self.delegate clientDidReceiveMessage:message];
    }
    [self alertMessage:message];
    [self dealTheMessage:message];
    
    if (message.msgId > 0 && message.msgId < OPEN_QUES_MAX_ID) { // 开场消息
        openingAnswer = message;
    }
}

/**
 *  Receive JSON string
 *
 *  @param json NSString
 */
- (void)receiveJSONString:(NSString *)json {
    V5Log(@"[receiveJSONString] %@", json);
}

- (void)onConnect {
    V5Log(@"[onConnect]");
    retryCount = 0;
    //[self stopProgressHud];
    if (cacheTitle && ![cacheTitle isEqualToString:@""]) {
        self.title = cacheTitle;
    }
    //查询会话消息,分两种状态：首次连接和连接后的重连
    if (hasConnected) {
        NSInteger size = self.messageOffset;
        self.messageOffset = 0;
        [[V5ClientAgent shareClient] getMessagesWithOffset:0 messageSize:size];
    } else { // 首次打开
        if (self.delegate && [self.delegate respondsToSelector:@selector(onClientViewConnect)]) {
            [self.delegate onClientViewConnect];
        }
        
        hasConnected = YES;
        self.messageOffset = 0;
        [[V5ClientAgent shareClient] getMessagesWithOffset:0 messageSize:self.numOfMessagesOnOpen];
    }
}

- (void)disconnectWithCode:(NSInteger)code reason:(NSString *)reason {
    V5Log(@"[onDisconnect]");
    self.title = V5LocalStr(@"v5_connect_broke", @"连接断开");
    if (code == 1001) { // Stream end encountered
        //提示
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_connection_error", @"连接异常断开，是否重试？") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
        alertView.tag = TAG_ALERT_RETRY;
        alertView.delegate = self;
        [alertView show];
    }
}

- (void)receiveExceptionStatus:(KV5ExceptionStatus)status desc:(NSString *)description {
    V5Log(@"[receiveExceptionStatus](%ld):%@", (long)status, description);
    if (status == Exception_NotConnected) {
        //[[V5ClientAgent shareClient] checkConnect];
        if (retryCount < 3) {
            if (![V5ClientAgent shareClient].isConnected) {
                self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
                [self startChatClient];
                retryCount++;
            }
        } else {
            [self stopProgressHud];
            self.title = V5LocalStr(@"v5_connect_broke", @"连接断开");
            //提示
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_connection_error", @"连接异常断开，是否重试？") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
            alertView.tag = TAG_ALERT_RETRY;
            alertView.delegate = self;
            [alertView show];
        }
    } else if (status == Exception_Connection_Timeout) {
        self.title = V5LocalStr(@"v5_connection_timeout", @"连接超时");
        [self stopProgressHud];
        //[self showToast:V5LocalStr(@"v5_network_not_reachable", @"无网络连接")];
        //提示
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_connection_timeout", @"连接超时") message:V5LocalStr(@"v5_check_network_retry", @"请检查网络连接后重试!") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
        alertView.tag = TAG_ALERT_RETRY;
        alertView.delegate = self;
        [alertView show];
    } else if (status == Exception_No_Network) {
        self.title = V5LocalStr(@"v5_network_not_reachable", @"无网络连接");
        [self stopProgressHud];
        //[self showToast:V5LocalStr(@"v5_network_not_reachable", @"无网络连接")];
        //提示
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_network_not_reachable", @"无网络连接") message:V5LocalStr(@"v5_check_network_retry", @"请检查网络连接后重试!") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
        alertView.tag = TAG_ALERT_RETRY;
        alertView.delegate = self;
        [alertView show];
    } else if (status == Exception_WSAuth_Failed) {
        if (retryCount < 3) {
            if (![V5ClientAgent shareClient].isConnected) {
                self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
                [self startChatClient];
                retryCount++;
            }
        } else {
            [self stopProgressHud];
            self.title = V5LocalStr(@"v5_connect_failed", @"连接失败");
            //提示
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_connection_error", @"连接异常断开，是否重试？") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
            alertView.tag = TAG_ALERT_RETRY;
            alertView.delegate = self;
            [alertView show];
        }
    } else if (status == Exception_NotInitialized) {
        [self stopProgressHud];
        self.title = V5LocalStr(@"v5_initialized_failed", @"初始化失败");
        
        //提示
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_initialized_failed", @"初始化失败") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_confirm", @"确定") otherButtonTitles:nil, nil];
        alertView.tag = TAG_ALERT_QUIT;
        alertView.delegate = self;
        [alertView show];
    } else if (status == Exception_Account_Failed) {
        [self stopProgressHud];
        self.title = V5LocalStr(@"v5_account_authfailed", @"帐号验证失败");
        
        //提示
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_account_authfailed", @"帐号验证失败") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_confirm", @"确定") otherButtonTitles:nil, nil];
        alertView.tag = TAG_ALERT_RETRY;
        alertView.delegate = self;
        [alertView show];
    } else if (status == Exception_Connection_Error) {
        if (retryCount < 3) {
            if (![V5ClientAgent shareClient].isConnected) {
                self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
                [self startChatClient];
                retryCount++;
            }
        } else {
            [self stopProgressHud];
            self.title = V5LocalStr(@"v5_connect_failed", @"连接失败");
            //提示
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_connection_error", @"连接失败，是否重试？") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消") otherButtonTitles:V5LocalStr(@"v5_retry", @"重试"), nil];
            alertView.tag = TAG_ALERT_RETRY;
            alertView.delegate = self;
            [alertView show];
        }
    }
}

- (void)getMessagesResult:(NSArray<V5Message *> *)messages
                   offset:(NSInteger)offset
                     size:(NSInteger)size
                   finish:(bool)finish
                expcetion:(KV5ExceptionStatus)expcetion {
    V5Log(@"[getMessagesResult] offset:%ld size:%ld historical:%d", (long)offset, (long)size, [self.head isRefreshing]);
    self.isMessageFinish = finish;
    if ([self.head isRefreshing]) { // 主动下拉刷新
        if (messages && size > 0) {
            for (V5Message *msg in messages) {
                [self addSpecifiedMessage:msg atTop:YES]; // 历史消息插入顶部
            }
//            [self dataSourceSort]; // 消息排序
            [self.chatTableView reloadData];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.messageOffset > 0) ? size : (size - 1)
                                                        inSection:0];
            [self.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            self.messageOffset += size;
        } else {
            [self showToast:V5LocalStr(@"v5_no_more_message", @"没有更多消息")];
        }
        [self.head endRefreshing];
    } else { // 启动页面查询消息（下拉刷新历史消息）
        if (offset == 0) { // 从头获取数据
            self.messageOffset = 0;
            // 清空dataSource
            [self.dataSource removeAllObjects];
            [self.chatTableView reloadData];
        }
        if (messages && size > 0) {
            // 倒序翻转
            NSArray <V5Message *> *messagesArray = [[messages reverseObjectEnumerator] allObjects];
            for (V5Message *msg in messagesArray) {
                [self addSpecifiedMessage:msg atTop:NO];
            }
            
//            [self dataSourceSort]; // 消息排序
            [self.chatTableView reloadData];
            [self tableViewScrollToBottom:NO delay:YES];
            self.messageOffset += size;
        }
        if ([self.dataSource count] == 0) { // 没有消息则获取开场消息
            [[V5ClientAgent shareClient] getOpeningMessageOfMode:self.openingMode
                                                       withParam:self.openingParam];
        }
        [self stopProgressHud];
    }
}

/**
 *  发送消息结果回调
 *
 *  @param message   消息对象
 *  @param expcetion 异常状态
 */
- (void)sendMessageResult:(V5Message *)message expcetion:(KV5ExceptionStatus)expcetion {
    V5Log(@"[sendMessageResult] %ld state:%ld", (long)expcetion, (long)message.state);
    if (expcetion == Exception_No_Error) {
        if (message.messageType < 20) {
            //[self showToast:V5LocalStr(@"v5_toast_send_success", @"发送成功")];
        }
    } else {
        [self showToast:V5LocalStr(@"v5_toast_send_failure", @"发送失败")];
    }
    //更新列表某一项
    [self.chatTableView reloadData];
}

- (void)servingStatusChange:(KV5ClientServingStatus)status {
    if (self.delegate && [self.delegate respondsToSelector:@selector(clientViewController:ServingStatusChange:)]) {
        [self.delegate clientViewController:self ServingStatusChange:status];
    }
}

#pragma mark ------ InputFunctionViewDelegate ------

- (BOOL)isCRInputFunctionViewEnableVoiceRecord:(CRInputFunctionView *)funcView {
//    V5Log(@"isCRInputFunctionViewEnableVoiceRecord:%d", self.enableVoiceRecord);
    return self.enableVoiceRecord;
}

/**
 *  输入框frame改变时调用，也可能高度不变
 *
 *  @param height 变化的高度
 *  @param y      变化后的y位置
 */
- (void)CRInputFunctionView:(CRInputFunctionView *)funcView willChangeOriginY:(CGFloat)y {
//    V5Log(@"willChangeOriginY:%f", y);
    // adjust ChatTableView's height
    CGRect tableViewFrame = self.view.bounds;
    tableViewFrame.size.height = y - tableViewFrame.origin.y;
    self.chatTableView.frame = tableViewFrame;
    [self.chatTableView reloadData]; // [修复]增加reloadData，修复收起键盘卡顿
    
//    V5Log(@"self.view.bounds:%@ chatTableView.frame:%@",
//          NSStringFromCGRect(self.view.bounds),
//          NSStringFromCGRect(self.chatTableView.frame));
    
    [self tableViewScrollToBottom:NO];
}

/**
 *  选择指定序号的功能
 *
 *  @param index 选中的序号
 */
- (void)CRInputFunctionView:(CRInputFunctionView *)funcView
  selectMoreFunctionOfIndex:(NSInteger)index {
    //V5Log(@"选择了第%ld张图", (long)index);
    switch (index) {
        case 0: { // 常见问题
            if (hotQuesArray) {
                [((CRInputFunctionView *)self.footerView) showBottomViewType:BottomTypeHotQuestion withParams:hotQuesArray];
            } else {
                [self requestHotQuestion];
            }
            break;
        }
        case 1: { // 相关问题
            [((CRInputFunctionView *)self.footerView) showBottomViewType:BottomTypeRelativeQuestion withParams:relativeQuesArray];
            break;
        }
        case 2: // 图片
            if (![V5ClientAgent shareClient].isConnected) {
                [self showToast:V5LocalStr(@"v5_waiting_for_connection", @"等待连接建立...")];
                break;
            }
            [self openPicLibrary];
            break;
        case 3: // 拍照
            if (![V5ClientAgent shareClient].isConnected) {
                [self showToast:V5LocalStr(@"v5_waiting_for_connection", @"等待连接建立...")];
                break;
            }
            [self addCarema];
            break;
        case 4: // 人工客服
            if (![V5ClientAgent shareClient].isConnected) {
                [self showToast:V5LocalStr(@"v5_waiting_for_connection", @"等待连接建立...")];
                break;
            }
            [self actionToSwitchWorker];
            break;
        case 5: // 测试
            
            break;
        default:
            break;
    }
}

- (BOOL)CRInputFunctionView:(CRInputFunctionView *)funcView sendMessage:(NSString *)message {
    if (![V5ClientAgent shareClient].isConnected) {
        [self showToast:V5LocalStr(@"v5_waiting_for_connection", @"等待连接建立...")];
        return NO;
    }
    if (!message || [message isEqualToString:@""] ||
        [[message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        [self showToast:V5LocalStr(@"v5_toast_no_empty", @"输入不能为空")];
        return YES;
    }
    V5Message *textMessage = [V5MessageManager obtainTextMessageWithContent:message];
    [self sendMessage:textMessage];
    return YES;
}

- (BOOL)CRInputFunctionView:(CRInputFunctionView *)funcView sendVoiceMessage:(V5VoiceMessage *)voiceMessage {
    // 发送语音
    if (![V5ClientAgent shareClient].isConnected) {
        [self showToast:V5LocalStr(@"v5_waiting_for_connection", @"等待连接建立...")];
        return NO;
    }
    
    [self sendMessage:voiceMessage];
    return YES;
}

#pragma mark -

- (void)sendMessage:(V5Message *)message {
    if (openingAnswer) { // 保存开场消息
        // 保存数据库
        V5DBHelper *dbHelper = [[V5DBHelper alloc] initWithDBName:V5_DB_NAME
                                                        tableName:[NSString stringWithFormat:V5_TABLE_NAME_FMT, [V5ClientAgent shareClient].config.visitor]];
        [dbHelper insertMessage:openingAnswer force:YES];
        self.messageOffset++;
        openingAnswer = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(userWillSendMessage:)]) {
        message = [self.delegate userWillSendMessage:message];
    }
    [[V5ClientAgent shareClient] sendMessage:message];
    
    [self dealTheMessage:message];
}

- (void)sendPicture:(UIImage *)image {
    V5Message *imageMessage = [V5MessageManager obtainImageMessageWithImage:image];
    [self sendMessage:imageMessage];
}

/**
 *  处理接收到的数据更新显示到UITableView
 *
 *  @param dic NSDictionary
 */
- (void)dealTheMessage:(V5Message *)v5message {
    switch (v5message.direction) {
        case MessageDir_ToWorker:
        case MessageDir_ToCustomer: // 常规消息
        case MessageDir_FromRobot:
        case MessageDir_Comment: // 评价消息
            //V5Log(@"dealTheMessage");
            if (v5message.msgId > 0 && v5message.msgId < OPEN_QUES_MAX_ID) {
                // 保存数据库时++
            } else {
                self.messageOffset++;
            }
            [self addSpecifiedMessage:v5message];
            [self.chatTableView reloadData];
            [self tableViewScrollToBottom:YES delay:NO];
            break;
            
        case MessageDir_RelativeQuestion: // 相关问题
            if (v5message.candidate) {
                if(relativeQuesArray) {
                    [relativeQuesArray removeAllObjects];
                }
                for (V5Message *msg in v5message.candidate) {
                    if (msg.messageType == MessageType_Text) {
                        NSString *content = ((V5TextMessage *)msg).content;
                        [relativeQuesArray addObject:content];
                    }
                }
                [((CRInputFunctionView *)self.footerView) showBottomViewType:BottomTypeRelativeQuestion
                                         withParams:relativeQuesArray
                                           animated:NO];
            }
            break;
            
        default:
            break;
    }
}

- (void)alertMessage:(V5Message *)msg {
    if (msg.direction == MessageDir_RelativeQuestion) {
        return;
    }
    if (self.allowSound) {
        AudioServicesPlaySystemSound(self.soundID);
    }}

#pragma mark ------ 常见问题／相关问题 ------
- (void)requestHotQuestion {
    NSString *url = [NSString stringWithFormat:HOTQUES_URL_FMT, [V5ClientAgent shareClient].config.site];
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [manager GET:url parameters:nil success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
        //        V5Log(@"[showHotQuestion] success:%@", [responseObject description]);
        NSDictionary *dic = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            dic = responseObject;
        } else if ([responseObject isKindOfClass:[NSString class]]) {
            NSData *jsonData = [(NSString *)responseObject dataUsingEncoding:NSUTF8StringEncoding];
            dic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        } else {
            NSData *jsonData = [[responseObject description] dataUsingEncoding:NSUTF8StringEncoding];
            dic = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        }
        NSString *state = [dic objectForKey:@"state"];
        NSInteger total = [[dic objectForKey:@"total"] integerValue];
        if ([state isEqualToString:@"ok"] && total > 0) {
            hotQuesArray = [dic objectForKey:@"items"];
            [((CRInputFunctionView *)self.footerView) showBottomViewType:BottomTypeHotQuestion withParams:hotQuesArray];
        } else {
            [self showToast:V5LocalStr(@"v5_hot_question_empty", @"未获取到常见问题")];
        }
        
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"[showHotQuestion] error:%@", [error description]);
        [self showToast:V5LocalStr(@"v5_hot_question_fail", @"获取常见问题失败")];
    }];
}

#pragma mark ------ tableView delegate & datasource ------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    V5Log(@"加载cell row:%ld", (long)indexPath.row);
    CRMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"V5ChatCellID"];
    if (cell == nil) {
        cell = [[CRMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"V5ChatCellID"];
        cell.delegate = self;
    }
    CRMessageFrame *messageFrame = self.dataSource[indexPath.row];
    if (indexPath.row == 0) {
        messageFrame.showTime = YES;
        [messageFrame updateFrame];
    }
    
    [cell setMessageFrame:messageFrame];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CRMessageFrame *messageFrame = self.dataSource[indexPath.row];
    return messageFrame.cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.footerView.frame.origin.y < Main_Screen_Height - 100) {
        [self.view endEditing:YES]; // 收起软键盘
        if (((CRInputFunctionView *)self.footerView).bottomShowType != BottomTypeNone) {
            [((CRInputFunctionView *)self.footerView) hideBottomView];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.footerView.frame.origin.y < Main_Screen_Height - 100) {
        [self.view endEditing:YES]; // 收起软键盘
        if (((CRInputFunctionView *)self.footerView).bottomShowType != BottomTypeNone) {
            [((CRInputFunctionView *)self.footerView) hideBottomView];
        }
    }
}

#pragma mark ------ cell delegate ------
/**
 *  单击消息
 *
 *  @param cell CRMessageCell对象
 *  @param type 消息类型
 *  @param dir  消息方向
 */
- (void)cellDidClick:(CRMessageCell *)cell messageType:(KV5MessageType)type direction:(KV5MessageDir)dir {
    [self.view endEditing:YES];
    switch (type) {
        case MessageType_Image: {
            V5ImageMessage *message = (V5ImageMessage *)cell.messageFrame.message;
            BOOL used = NO;
            if ([self.delegate respondsToSelector:@selector(userClickImageWithImage:picUrl:)]) {
                if (cell.btnContent.backImageView) {
                    used = [self.delegate userClickImageWithImage:cell.btnContent.backImageView.image picUrl:message.picUrl];
                }
            }
            if (!used) {
                if (cell.btnContent.backImageView) {
                    [CRImageAvatarBrowser showImage:cell.btnContent.backImageView withURL:message.picUrl];
                }
            }
            break;
        }
            
        case MessageType_Location: {
            V5LocationMessage *message = (V5LocationMessage *)cell.messageFrame.message;
            BOOL used = NO;
            if ([self.delegate respondsToSelector:@selector(userClickLocationWithLatitude:longitude:)]) {
                used = [self.delegate userClickLocationWithLatitude:message.x longitude:message.y];
            }
            if (!used) {
                if (cell.btnContent.backImageView) {
                    [CRImageAvatarBrowser showImage:cell.btnContent.backImageView withURL:nil];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

/**
 *  长按消息
 *
 *  @param cell CRMessageCell对象
 *  @param type 消息类型
 *  @param dir  消息方向
 */
- (void)cellDidLongClick:(CRMessageCell *)cell messageType:(KV5MessageType)type direction:(KV5MessageDir)dir {
    [self.view endEditing:YES];
    //    switch (type) {
    //        case MessageType_Image: {
    //            // show text and gonna copy that
    //            [cell becomeFirstResponder];
    //            UIMenuController *menu = [UIMenuController sharedMenuController];
    //            UIMenuItem *saveItem = [[UIMenuItem alloc] initWithTitle:@"保存" action:@selector(menuSave:)];
    //            [menu setMenuItems:[NSArray arrayWithObjects:saveItem, nil]];
    //            [menu setTargetRect:cell.btnContent.frame inView:cell];
    //            [menu setMenuVisible:YES animated:YES];
    //            break;
    //        }
    //
    //        case MessageType_Text: {
    //            // show text and gonna copy that
    //            [cell becomeFirstResponder];
    //            UIMenuController *menu = [UIMenuController sharedMenuController];
    //            UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(menuCopy:)];
    //            [menu setMenuItems:[NSArray arrayWithObjects:copyItem, nil]];
    //            [menu setTargetRect:cell.btnContent.frame inView:cell];
    //            [menu setMenuVisible:YES animated:YES];
    //            break;
    //        }
    //        default:
    //            break;
    //    }
}

/**
 *  链接点击
 *
 *  @param cell     CRMessageCell对象
 *  @param linkType 链接类型
 *  @param link     链接内容
 */
- (void)cellLinkDidClick:(CRMessageCell *)cell linkType:(V5KZLinkType)linkType link:(NSString *)link {
    [self.view endEditing:YES];
    
    NSString *openTypeString;
    NSString *titleString = V5LocalStr(@"v5_copy", @"拷贝");
    if (linkType == V5KZLinkTypeURL || linkType == V5KZLinkTypeArticleURL
        || linkType == V5KZLinkTypeHTMLHref) {
        openTypeString = V5LocalStr(@"v5_open_in_safari", @"在Safari中打开");
        titleString = V5LocalStr(@"v5_copy_link", @"拷贝链接");
    } else if (linkType == V5KZLinkTypePhoneNumber) {
        openTypeString = V5LocalStr(@"v5_dail_number", @"直接拨打");
        titleString = V5LocalStr(@"v5_copy", @"拷贝");
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:titleString, openTypeString, nil];
    sheet.tag = TAG_AS_LINK;
    
    switch (linkType) {
        case V5KZLinkTypeArticleURL: {
            //V5Log(@"点击图文:%@", link);
            BOOL used = NO;
            if ([self.delegate respondsToSelector:@selector(userClickLink:linkType:)]) {
                used = [self.delegate userClickLink:link linkType:LinkTypeArticle];
            }
            if (!used) {
                NSMutableDictionary *linkDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
                [linkDictionary setObject:@(linkType) forKey:@"linkType"];
                [linkDictionary setObject:link forKey:@"link"];
                self.actionSheetDic = linkDictionary;
                [sheet showInView:self.view];
            }
            break;
        }
        case V5KZLinkTypeHTMLHref:
        case V5KZLinkTypeURL: {
            //V5Log(@"点击链接:%@", link);
            BOOL used = NO;
            if ([self.delegate respondsToSelector:@selector(userClickLink:linkType:)]) {
                used = [self.delegate userClickLink:link linkType:LinkTypeURL];
            }
            if (!used) {
                NSMutableDictionary *linkDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
                [linkDictionary setObject:@(linkType) forKey:@"linkType"];
                [linkDictionary setObject:link forKey:@"link"];
                self.actionSheetDic = linkDictionary;
                [sheet showInView:self.view];
            }
            break;
        }
        case V5KZLinkTypePhoneNumber: { // tell
            //V5Log(@"点击号码:%@", link);
            BOOL used = NO;
            if ([self.delegate respondsToSelector:@selector(userClickLink:linkType:)]) {
                used = [self.delegate userClickLink:link linkType:LinkTypePhoneNumber];
            }
            if (!used) {
                NSMutableDictionary *linkDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
                [linkDictionary setObject:@(linkType) forKey:@"linkType"];
                [linkDictionary setObject:link forKey:@"link"];
                self.actionSheetDic = linkDictionary;
                [sheet showInView:self.view];
            }
            break;
        }
        case V5KZLinkTypeHashTag:     // #tag
        case V5KZLinkTypeUserHandle:  // @name
            V5Log(@"点击标签:%@", link);
            break;
        default:
            V5Log(@"点击文本:%@", link);
            break;
    }
}

/**
 *  链接长按
 *
 *  @param cell     CRMessageCell对象
 *  @param linkType 链接类型
 *  @param link     链接内容
 */
- (void)cellLinkDidLongClick:(CRMessageCell *)cell linkType:(V5KZLinkType)linkType link:(NSString *)link {
    [self.view endEditing:YES];
    switch (linkType) {
        case V5KZLinkTypeArticleURL:
        case V5KZLinkTypeHTMLHref:    // url
        case V5KZLinkTypeURL:
            //V5Log(@"长按链接:%@", link);
            break;
        case V5KZLinkTypePhoneNumber: // tell
            //V5Log(@"长按号码:%@", link);
            break;
        case V5KZLinkTypeHashTag:     // #tag
        case V5KZLinkTypeUserHandle:  // @name
            //V5Log(@"长按标签:%@", link);
            break;
        default:
            //V5Log(@"长按文本:%@", link);
            break;
    }
    
    NSString *openTypeString;
    NSString *titleString = V5LocalStr(@"v5_copy", @"拷贝");
    if (linkType == V5KZLinkTypeURL || linkType == V5KZLinkTypeArticleURL
        || linkType == V5KZLinkTypeHTMLHref) {
        openTypeString = V5LocalStr(@"v5_open_in_safari", @"在Safari中打开");
        titleString = V5LocalStr(@"v5_copy_link", @"拷贝链接");
    } else if (linkType == V5KZLinkTypePhoneNumber) {
        openTypeString = V5LocalStr(@"v5_dail_number", @"直接拨打");
        titleString = V5LocalStr(@"v5_copy", @"拷贝");
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:V5LocalStr(@"v5_cancel", @"取消")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:titleString,openTypeString, nil];
    sheet.tag = TAG_AS_LINK;
    NSMutableDictionary *linkDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [linkDictionary setObject:@(linkType) forKey:@"linkType"];
    [linkDictionary setObject:link forKey:@"link"];
    self.actionSheetDic = linkDictionary;
    [sheet showInView:self.view];
}

/**
 *  重发失败消息
 *
 *  @param cell CRMessageCell对象
 */
- (void)resendDidClick:(CRMessageCell *)cell {
    if (cell.messageFrame.message.state == MessageSendStatus_Failure) {
        if (kNetworkNotReachability) {
            [self showToast:V5LocalStr(@"v5_network_not_reachable", @"无网络连接")];
            return;
        }
//        V5Log(@"重发消息:%@", [cell.messageFrame.message getDefaultContent]);
        [[V5ClientAgent shareClient] checkConnect];
        [[V5ClientAgent shareClient] sendMessage:cell.messageFrame.message];
        [self.chatTableView reloadData];
    }
}

#pragma mark ------ Data generator for test ------
// 添加自己的item
//static NSString *previousTime = nil;
- (void)addSpecifiedMessage:(V5Message *)v5message atTop:(BOOL)top {
    if (v5message.direction == 4) { //过滤掉转人工客服后的消息
        v5message.direction = 1;
    }
    
    CRMessageFrame *messageFrame = [[CRMessageFrame alloc] init];
    /* 时间戳显示条件：第一个消息，活着前后相差2min的两个消息间需要显示时间戳 */
    if (self.dataSource.count == 0) {
        previousTime = 0;
    } else if (top) {
        previousTime = [self.dataSource objectAtIndex:0].message.createTime;
    } else {
        previousTime = [self.dataSource lastObject].message.createTime;
    }
    messageFrame.showTime = [NSDate shouldShowDateOfStartInterval:previousTime endInterval:v5message.createTime];
    if ([self.dataSource count] == 0) {
        messageFrame.showTime = YES;
    }
    
//    if (messageFrame.showTime) {
//        V5Log(@"显示时间戳 previousTime(%lu): (%ld)%@ ", previousTime, v5message.createTime, [v5message getDefaultContent]);
//        previousTime = v5message.createTime;
//    }
    messageFrame.showAvatar = self.showAvatar;
    messageFrame.avatarRadius = self.avatarRadius;
    messageFrame.message = v5message;
    
    if (top) {
        [self.dataSource insertObject:messageFrame atIndex:0];
    } else {
        [self.dataSource addObject:messageFrame];
    }
}
                 
- (void)addSpecifiedMessage:(V5Message *)v5message {
    [self addSpecifiedMessage:v5message atTop:NO];
}

- (void)dataSourceSort {
    //排序
    NSArray *sortedArray = [self.dataSource sortedArrayUsingComparator:^NSComparisonResult(CRMessageFrame *obj1, CRMessageFrame *obj2) {
        V5Message *message1 = obj1.message;
        V5Message *message2 = obj2.message;
        if (message1.createTime == message2.createTime) {
            if (message1.direction == MessageDir_FromRobot) {
                return NSOrderedDescending;
            } else if (message2.direction == MessageDir_FromRobot) {
                return NSOrderedAscending;
            }
            return NSOrderedSame;
        } else if (message1.createTime > message2.createTime) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    self.dataSource = [NSMutableArray arrayWithArray:sortedArray];
}

#pragma mark ------ 打开链接 ------
- (BOOL)openURL:(NSURL *)url {
    BOOL safariCompatible = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
    if (safariCompatible && [[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)openTel:(NSString *)tel {
    NSString *telString = [NSString stringWithFormat:@"tel://%@",tel];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:telString]]) {
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
    } else {
        return NO;
    }
}

#pragma mark - Action Sheet Delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == TAG_AS_LINK && self.actionSheetDic) {
        switch (buttonIndex) {
            case 0: {
                [UIPasteboard generalPasteboard].string = self.actionSheetDic[@"link"];
                break;
            }
            case 1: {
                V5KZLinkType linkType = [self.actionSheetDic[@"linkType"] integerValue];
                if (linkType == V5KZLinkTypeURL || linkType == V5KZLinkTypeArticleURL
                    || linkType == V5KZLinkTypeHTMLHref) {
                    NSURL *url = [NSURL URLWithString:self.actionSheetDic[@"link"]];
                    if (![self openURL:url]) {
                        // 打开URL失败
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_alert_no_browser", @"打开浏览器失败") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_confirm", @"确定") otherButtonTitles:nil];
                        [alert show];
                    }
                } else if (linkType == V5KZLinkTypePhoneNumber) {
                    if (![self openTel:self.actionSheetDic[@"link"]]) {
                        // 打开电话失败
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒") message:V5LocalStr(@"v5_alert_no_phone", @"拨号失败") delegate:nil cancelButtonTitle:V5LocalStr(@"v5_confirm", @"确定") otherButtonTitles:nil];
                        [alert show];
                    }
                }
                break;
            }
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == TAG_ALERT_RETRY) {
        //V5Log(@"alertView click index:%ld", (long)buttonIndex);
        if (buttonIndex == 0) { //取消
            
        } else if (buttonIndex == 1) { //重试
            if (![V5ClientAgent shareClient].isConnected) {
                self.title = V5LocalStr(@"v5_connecting", @"正在连接...");
                [self startProgressHud];
                [self startChatClient];
            }
        }
    } else if (alertView.tag == TAG_ALERT_QUIT) {
        if (buttonIndex == 0) { //确定
            //self.title = V5LocalStr(@"v5_not_initialized", @"初始化失败");
        }
    }
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark ------ Add Picture/Open Camera ------
-(void)addCarema {
    BOOL noCamera = NO;
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        noCamera = YES;
        V5Log(@"Camera not permit");
    }
    
    if (!noCamera && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        //picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:picker animated:YES completion:^{}];
    } else {
        // 如果没有提示用户
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:V5LocalStr(@"v5_alert_title", @"提醒")
                                                        message:V5LocalStr(@"v5_alert_no_camera", @"相机权限受限")
                                                       delegate:nil
                                              cancelButtonTitle:V5LocalStr(@"v5_confirm", @"确定")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)openPicLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        //picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:^{
        }];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *editImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!editImage) {
        editImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    editImage = [V5Util imageCompressForWidth:editImage targetWidth:MAX_UPLOADIMG_WIDTH];
    [self dismissViewControllerAnimated:YES completion:^{
        [self sendPicture:editImage];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setClientOpenMode:(KV5ClientOpenMode)mode withParam:(nullable NSString *)param {
    self.openingMode = mode;
    self.openingParam = param;
}

@end
