//
//  V5ClientAgent.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/10.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5ClientAgent.h"
#import "V5MessageManager.h"
#import "V5AFNetworking.h"
#import "NSDate+V5Utils.h"
#import "V5SRWebSocket.h"
#import "NSAttributedString+V5Emotion.h"
#import "UIButton+V5Color.h"
#import "UITableView+V5Scroll.h"
#import "NSString+V5URL.h"
#import "UIButton+V5AFNetworking.h"
#import "UIImageView+V5AFNetworking.h"
#import "UIViewController+V5BackButtonHandler.h"
#import "V5DBHelper.h"
#import "V5Macros.h"
#import "CRConfigMcros.h"
#import "V5Util.h"

#define V5DatabaseEnable YES
//是否无网络
#define kNetworkNotReachability ([V5AFNetworkReachabilityManager sharedManager].networkReachabilityStatus <= 0)

@interface V5ClientAgent () <V5SRWebSocketDelegate> {
//    bool isConnected;
//    BOOL connInit;
}
@property (nonatomic, strong) NSUserDefaults *userData;
@property (nonatomic, weak) id<V5MessageDelegate> messageDelegate;
@property (nonatomic, strong) V5SRWebSocket *webSocket;
@property (nonatomic, strong) V5DBHelper *dbHelper;
@property (nullable, nonatomic, strong) NSString * wxytUrl;
@property (nullable, nonatomic, strong) NSString * wxytAuth;

@end

static bool initSuccess = false;
//static NSUInteger sessionCount = 0;
@implementation V5ClientAgent

static id _instance = nil;

+ (instancetype)shareClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [V5ClientAgent shareClient] ;
}

+ (id)copyWithZone:(struct _NSZone *)zone {
    return [V5ClientAgent shareClient] ;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userData = [NSUserDefaults standardUserDefaults];
        _config = [[V5Config alloc] initWithUserDefaults:self.userData];
    }
    return self;
}

//- (void)dealloc {
//    self.userData = nil;
//    self.config = nil;
//    self.webSocket = nil;
//    self.messageDelegate = nil;
//    self.wxytAuth = nil;
//    self.wxytUrl = nil;
//}

+ (void)destroyDealloc {
    _instance = nil;
}

+ (NSString *)version {
    return V5_VERSION;
}

#pragma mark ------ SDK Init ------
/**
 *  初始化SDK，验证参数
 *
 *  @param siteId   站点编号
 *  @param account  用户账号
 *  @param delegate 初始化回调
 */
+ (void)initWithSiteId:(NSString *)siteId
               account:(NSString *)account
     exceptionDelegate:(id<V5ExpcetionDelegate>)delegate {
    // 解决Category链接Bug
    V5KW_ENABLE_CATEGORY(NSAttributedString_V5Emotion);
    V5KW_ENABLE_CATEGORY(UIButton_V5Color);
    V5KW_ENABLE_CATEGORY(UITableView_V5Scroll);
    V5KW_ENABLE_CATEGORY(UIButton_V5AFNetworking);
    V5KW_ENABLE_CATEGORY(UIImageView_V5AFNetworking);
    V5KW_ENABLE_CATEGORY(NSDate_V5Utils);
    V5KW_ENABLE_CATEGORY(NSString_V5URL);
    V5KW_ENABLE_CATEGORY(UIViewController_V5BackButtonHandler);
    
    if (siteId && ![siteId isEqual:@""] && account && ![account isEqual:@""]) { //  参数检查
        NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
        BOOL isInitialized = [userData boolForKey:CFG_INITIALIZED];
        NSString *localSiteId = [userData objectForKey:CFG_SITE_ID];
        if (isInitialized && ![localSiteId isEqualToString:siteId]) {
            isInitialized = NO;
            [userData removeObjectForKey:CFG_UID];
            [userData removeObjectForKey:CFG_VISITOR];
            [userData removeObjectForKey:CFG_AUTH];
            V5Log(@"isInitialized = no");
        }
        if (isInitialized) {
            // 保存初始化参数
            [userData setObject:siteId forKey:CFG_SITE_ID];
            [userData setObject:account forKey:CFG_ACCOUNT];
            initSuccess = true;
            if (delegate && [delegate respondsToSelector:@selector(initExpcetionStatus:desc:)]) {
                [delegate initExpcetionStatus:Exception_No_Error desc:@"Init success"];
            }
        } else {
            // 发请求
            [self doInitAUthWithSite:siteId account:account exceptionDelegate:delegate];
        }
    } else {
        if (delegate && [delegate respondsToSelector:@selector(initExpcetionStatus:desc:)]) {
            [delegate initExpcetionStatus:Exception_Init_Param_Invalid desc:@"Invalid param"];
        }
    }
}

+ (void)doInitAUthWithSite:(NSString *)siteId account:(NSString *)account exceptionDelegate:(id<V5ExpcetionDelegate>)delegate {
    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          siteId, @"site_id",
                          account, @"account",
                          @"ios", @"platform", nil];
    V5Log(@"<<<InitRequest>>>:%@", [body description]);
    V5AFSecurityPolicy *securityPolicy = [V5AFSecurityPolicy defaultPolicy];
//    securityPolicy.allowInvalidCertificates = YES;
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [V5AFJSONResponseSerializer serializer];
    manager.requestSerializer = [V5AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager POST:V5_INIT_URL parameters:body success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
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
        V5Log(@"<<<InitResult>>>:%@", [responseObject description]);
        if (!dic) {
            if (delegate &&
                [delegate respondsToSelector:@selector(initExpcetionStatus:desc:)]) {
                [delegate initExpcetionStatus:Exception_Init_Failed desc:@"Response nil"];
            }
            return;
        }
        
        NSInteger o_error = [[dic objectForKey:@"o_error"] integerValue];
        NSString *o_errmsg = [dic objectForKey:@"o_errmsg"];
        if (o_error == 0) {
            // 保存初始化参数
            NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
            [userData setObject:siteId forKey:CFG_SITE_ID];
            [userData setObject:account forKey:CFG_ACCOUNT];
            [userData setObject:@(YES) forKey:CFG_INITIALIZED];
            initSuccess = true;
            
            NSString *version = [dic objectForKey:@"version"];
            NSString *versionInfo = [dic objectForKey:@"version_info"];
            if ([[self version] compare:version] < 0) {
                V5Log(@"[V5 SDK init] found new version(%@):%@", version, versionInfo);
            }
        } else {
            V5Log(@"[V5 SDK init] error:%@", o_errmsg);
            if (delegate &&
                [delegate respondsToSelector:@selector(initExpcetionStatus:desc:)]) {
                [delegate initExpcetionStatus:Exception_Init_Failed desc:o_errmsg];
            }
        }
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"[doInit] error:%@", [error description]);
        if (delegate &&
            [delegate respondsToSelector:@selector(initExpcetionStatus:desc:)]) {
            [delegate initExpcetionStatus:Exception_Init_Failed desc:@"Response nil"];
        }
    }];
}

#pragma mark ------ SDK Start part ------
/**
 *  开启消息服务(账号认证->参数保存->建立连接)
 *
 *  @param delegate 消息代理
 */
- (void)startClientWithDelegate:(id<V5MessageDelegate>)delegate {
    V5Log(@"--- startClientWithDelegate ---");
    //// init or not
    //if (!initSuccess) {
    //    // SDK初始化异常回调
    //    if (delegate && [delegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
    //        [delegate receiveExceptionStatus:Exception_NotInitialized
    //                                    desc:@"Not initialized"];
    //    }
    //    return;
    //}
    if (!self.dbHelper) {
        self.dbHelper = [[V5DBHelper alloc] initWithDBName:V5_DB_NAME
                                                 tableName:[NSString stringWithFormat:V5_TABLE_NAME_FMT, self.config.visitor]];
    }
//    connInit = YES;
    // do account auth, if success then start websocket
    self.messageDelegate = nil;
    self.messageDelegate = delegate;
    
    if (self.config.authorization) {
        [self startWebsocketWithDelegate:self];
    } else {
        [self doAccountAuth];
    }
    
    // 开启网络监听
    __block BOOL initReachability = YES;
    [[V5AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(V5AFNetworkReachabilityStatus status) {
        if (initReachability) {
            initReachability = NO;
            return;
        }
        
        switch (status) {
            case V5AFNetworkReachabilityStatusNotReachable:
                V5Log(@"--networkNotReachable");
//                if (self.messageDelegate &&
//                    [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
//                    if (kNetworkNotReachability) { //无网络
//                        [self.messageDelegate receiveExceptionStatus:Exception_No_Network
//                                                                desc:@"Network not reachable"];
//                    }
//                }
                break;
                
            case V5AFNetworkReachabilityStatusReachableViaWiFi:
                V5Log(@"--networkReachableViaWiFi");
                [self performSelector:@selector(checkConnect) withObject:nil afterDelay:0.95];
                //[self checkConnect]; //等待网络稳定再尝试重连,以免连接失败
                break;
                
            case V5AFNetworkReachabilityStatusReachableViaWWAN:
                V5Log(@"--networkReachableViaWWAN");
                [self performSelector:@selector(checkConnect) withObject:nil afterDelay:0.95];
                //[self checkConnect]; //等待网络稳定再尝试重连,以免连接失败
                break;
                
            default:
                break;
        }
    }];
    [[V5AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 *  停止消息服务
 */
- (void)stopClient {
    V5Log(@"[stopClient]");
    [self shouldClientOffline];
    self.messageDelegate = nil;
    [[V5AFNetworkReachabilityManager sharedManager] stopMonitoring];
    if (self.webSocket) {
        [self.webSocket close];
        self.connected = NO;
        self.webSocket.delegate = nil;
        self.webSocket = nil;
    }
}

/**
 *  读取参数开启websocket
 */
- (void)startWebsocketWithDelegate:(id<V5SRWebSocketDelegate>)delegate {
    V5Log(@"--- startWebsocketWithDelegate ---");
    self.connected = false;
    if (self.webSocket) {
        self.webSocket.delegate = nil;
        [self.webSocket close];
    }
    NSString *auth = self.config.authorization;
    NSString *urlString = [NSString stringWithFormat:WS_URL_FMT, auth];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10.0]; // 超时10s
    self.webSocket = [[V5SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = delegate;
    [self.webSocket open];
    V5Log(@"\n>>> open success! URL:%@", urlString);
}

/**
 *  进行认证
 */
- (void)doAccountAuth {
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:6];
    if (self.config.site) {
        [body setObject:self.config.site forKey:@"site"];
    }
    if (self.config.account) {
        [body setObject:self.config.account forKey:@"account"];
    }
    [body setObject:self.config.visitor forKey:@"visitor"];
    [body setObject:@"ios" forKey:@"device"];
    [body setObject:@(604800) forKey:@"expires"];
    if (self.config.deviceToken) {
        [body setObject:self.config.deviceToken forKey:@"dev_id"];
    }
    if (self.config.nickname) {
        [body setObject:self.config.nickname forKey:@"nickname"];
    }
    if (self.config.avatar) {
        [body setObject:self.config.avatar forKey:@"avatar"];
    }
    if (self.config.gender) {
        [body setObject:@(self.config.gender) forKey:@"gender"];
    }
//    if (self.config.customContent) {
//        [body setObject:self.config.customContent forKey:CFG_CUSTOM_CONTENT];
//    }
    V5Log(@"doAccountAuth body:%@", body);
    
    // 切换数据库表
    [self.dbHelper setTableName:[NSString stringWithFormat:V5_TABLE_NAME_FMT, self.config.visitor]];
    
    V5AFSecurityPolicy *securityPolicy = [V5AFSecurityPolicy defaultPolicy];
    securityPolicy.allowInvalidCertificates = YES;
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [V5AFJSONResponseSerializer serializer];
    manager.requestSerializer = [V5AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager POST:ACCOUNT_AUTH_URL parameters:body success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
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
        V5Log(@"<<<AccountAuthResult>>>:%@", [dic description]);
        NSString *auth = [dic objectForKey:@"authorization"];
        if (auth) {
            self.config.expires = [[dic objectForKey:@"expires"] longValue];
            self.config.timestamp = [[dic objectForKey:@"timestamp"] longValue];
            self.config.authorization = auth;
            [self startWebsocketWithDelegate:self];
        } else {
            // Account认证异常回调
            if (self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
                if (initSuccess) {
                    [self.messageDelegate receiveExceptionStatus:Exception_Account_Failed
                                                            desc:@"account auth failed"];
                } else {
                    [self.messageDelegate receiveExceptionStatus:Exception_NotInitialized
                                                            desc:@"Not initialized"];
                }
            }
        }
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"[doAccountAuth] error:%@", [error description]);
        // Account认证异常回调
        if (self.messageDelegate &&
            [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_Account_Failed
                                                    desc:@"account auth failed"];
        }
    }];
}

- (void)getSiteInfo {
    NSString *url = [NSString stringWithFormat:V5_SITE_INFO_FMT, self.config.site];
    
    V5AFSecurityPolicy *securityPolicy = [V5AFSecurityPolicy defaultPolicy];
    securityPolicy.allowInvalidCertificates = YES;
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [V5AFJSONResponseSerializer serializer];
    manager.requestSerializer = [V5AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [manager GET:url parameters:nil success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
        V5Log(@"[requestSiteInfo] success:%@", [responseObject description]);
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
        if ([state isEqualToString:@"ok"]) {
            NSString *intro = [[dic objectForKey:@"robot"] objectForKey:@"intro"];
            if (intro) {
                [self sendPrologue:intro];
                return;
            }
        } else {
            V5Log(@"[requestSiteInfo] error: state not ok");
        }
        [self sendPrologue:V5LocalStr(@"v5_start_message", @"您好，我是小五，请问有什么能帮到您的吗？")];
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"[requestSiteInfo] error:%@", [error description]);
        [self sendPrologue:V5LocalStr(@"v5_start_message", @"您好，我是小五，请问有什么能帮到您的吗？")];
    }];
}


#pragma mark ------ SRWebsocketDelegate ------
/**
 *  websocket open
 *
 *  @param webSocket websocket连接对象
 */
- (void)webSocketDidOpen:(V5SRWebSocket *)webSocket {
    V5Log(@">>>onOpen");
    self.connected = true;
    
    [self shouldClientOnline];
    [self getCurrentMessagesWithOffset:0 messageSize:0]; //返回当前会话历史
    
    //get_status
    [self getStatus];
    
    // websocket连接建立回调,延迟到收到session消息
    //    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(onConnect)]) {
    //        [self.messageDelegate onConnect];
    //    }
}

/**
 *  websocket receive message
 *
 *  @param webSocket websocket连接对象
 *  @param message   消息内容
 */
- (void)webSocket:(V5SRWebSocket *)webSocket didReceiveMessage:(id)message {
    V5Log(@">>>onMessage:%@", message);
    if ([message isKindOfClass:[NSString class]]) {
        // 文本 NSString
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([[jsonData objectForKey:@"o_type"] isEqualToString:@"message"]) {
            V5Message *v5Message = [V5MessageManager receiveMessageFromJSON:jsonData];
            if (!v5Message) {
                V5Log(@"---webSocket:didReceiveMessage:--- error: nil message");
                return;
            }
            
            // 去掉空消息
            if ([v5Message getDefaultContent] || v5Message.candidate) {
                if (V5DatabaseEnable) {
                    [self.dbHelper insertMessage:v5Message];
                }
                // 接收V5Message消息回调
                if (self.messageDelegate) {
                    [self.messageDelegate receiveV5Message:v5Message];
                }
            }
        } else if ([[jsonData objectForKey:@"o_type"] isEqualToString:@"session"]) {
            if ([jsonData objectForKey:@"o_method"] && [[jsonData objectForKey:@"o_method"] isEqualToString:@"get_status"]) { // get_status
                NSInteger status = [[jsonData objectForKey:@"status"] integerValue];
                if (status == 2) { // 1-机器人 2-人工
                    NSString *nickname = [jsonData objectForKey:@"nickname"];
                    NSString *photo = [jsonData objectForKey:@"photo"];
                    self.config.workerPhoto = photo;
                    self.config.workerName = nickname;
                    if ([jsonData objectForKey:@"w_id"]) {
                        long long wId = [[jsonData objectForKey:@"w_id"] longLongValue];
                        self.config.workerId = wId;
                        
                        // 保存wId->photo到本地
                        NSString *key = [NSString stringWithFormat:@"v5photo_%lld", wId];
                        [V5Util savePreferencesWithValue:photo forKey:key];
                    }
                }
                
                if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(servingStatusChange:)]) {
                    [self.messageDelegate servingStatusChange:status];
                }
            } else if ([jsonData objectForKey:@"o_method"] && [[jsonData objectForKey:@"o_method"] isEqualToString:@"get_messages"]) { // get_messages
                if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(getMessagesResult:offset:size:finish:expcetion:)]) {
//                    NSInteger offset = [[jsonData objectForKey:@"offset"] integerValue];
                    NSInteger size = [[jsonData objectForKey:@"size"] integerValue];
//                    BOOL finish = [[jsonData objectForKey:@"finish"] boolValue];
//                    if (offset == 0 && size == 0) {
//                        finish = YES;
//                    }
                    NSMutableArray<V5Message *> *V5Msgs = [NSMutableArray arrayWithCapacity:0];
                    NSArray *messages = [jsonData objectForKey:@"messages"];
                    if (messages && ![messages isEqual:[NSNull null]] && size > 0) {
                        for (NSDictionary *item in messages) {
                            V5Message *msg = [V5MessageManager receiveMessageFromJSON:item];
                            if (!msg) {
                                V5Log(@"---webSocket:didReceiveMessage:--- error: nil message");
                                continue;
                            }
                            //V5Log(@"---webSocket:sessionMessage:--- :%@", [msg toJSONString]);
                            [V5Msgs addObject:msg];
                            
                            // 机器人回复
                            V5Message *candidate = nil;
                            if (msg.candidate && [msg.candidate count] > 0) {
                                candidate = [msg.candidate objectAtIndex:0];
                                if (candidate.direction == MessageDir_FromRobot) {
                                    [V5Msgs addObject:candidate];
                                }
                                msg.candidate = nil;
                            }
                        }
                    }
                    
                    if (V5Msgs.count > 0 && V5DatabaseEnable) {
                        for (V5Message *msg in V5Msgs) {
                            if ([msg getDefaultContent]) { // 去掉空消息
                                [self.dbHelper insertMessage:msg]; // 排除开场提问
                            }
                        }
                    }
                    
                    // websocket连接建立回调,延迟到收到session消息
                    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(onConnect)]) {
                        [self.messageDelegate onConnect];
                    }
                }
            } else {
                // [修改]支持更多session类消息
                V5Log(@"Warning! not support session method");
            }
        } else if ([jsonData objectForKey:@"o_error"]) {
            NSInteger o_error = [[jsonData objectForKey:@"o_error"] integerValue];
            NSString *o_errmsg = [jsonData objectForKey:@"o_errmsg"];
            if (self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
                [self.messageDelegate receiveExceptionStatus:o_error desc:o_errmsg];
            }
        } else {
            // 接收其他格式JSON字符串消息回调
            if (self.messageDelegate) {
                [self.messageDelegate receiveJSONString:message];
            }
        }
    } else if ([message isKindOfClass:[NSData class]]) {
        // 二进制 NSData
        V5Log(@"!!!!!Binary message from websocket");
    } else {
        V5Log(@"!!!!!Unsupport message from websocket");
    }
    
}

/**
 *  websocket close
 *
 *  @param webSocket websocket连接对象
 *  @param code      断开错误码
 *  @param reason    原因
 *  @param wasClean  clean?
 */
- (void)webSocket:(V5SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    V5Log(@">>>onClose(%ld):%@<%d>", (long)code, reason, wasClean);
    self.connected = false;
    
    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(disconnectWithCode:reason:)]) {
        [self.messageDelegate disconnectWithCode:code reason:reason];
    }
}

/**
 *  websocket error
 *
 *  @param webSocket websocket连接对象
 *  @param error     NSError
 */
- (void)webSocket:(V5SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    // 注："HTTPResponseStatusCode"固定字符串，不可改
    V5Log(@">>>onError(%ld)(status:%@):%@", (long)error.code, error.userInfo[@"HTTPResponseStatusCode"], [error description]);
    V5Log(@"kNetworkNotReachability:%d", kNetworkNotReachability);
    self.connected = false;
    // init or not
    if (!initSuccess) {
        // SDK初始化异常回调
        if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotInitialized
                                                    desc:@"Not initialized"];
        }
        return;
    }
    
    if (self.messageDelegate &&
        [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
        if (kNetworkNotReachability) { //无网络
            [self.messageDelegate receiveExceptionStatus:Exception_No_Network
                                                    desc:@"Network not reachable"];
        } else { //有网络，连接错误
            if ([error.userInfo[@"HTTPResponseStatusCode"] integerValue] == 404 || [error.userInfo[@"HTTPResponseStatusCode"] integerValue] == 406) {
                //参数认证错误
                [self.userData removeObjectForKey:CFG_AUTH];
                [self.config shouldUpdateUserInfo];
                [self.messageDelegate receiveExceptionStatus:Exception_WSAuth_Failed
                                                        desc:@"WSAuthorization error"];
                
            } else {
                if (error.code == 57 || !error.userInfo[@"HTTPResponseStatusCode"]) { // 无网络
                    if ([[error description] containsString:@"Timeout"]) {
                        [self.messageDelegate receiveExceptionStatus:Exception_Connection_Timeout
                                                                desc:@"Connection timeout"];
                    } else {
                        [self.messageDelegate receiveExceptionStatus:Exception_No_Network
                                                                desc:@"Network not reachable"];
                    }
                } else {
                    [self.messageDelegate receiveExceptionStatus:Exception_Connection_Error
                                                            desc:@"Connection error"];
                }
            }
        }
    }
}

/**
 *  websocket receive pong
 *
 *  @param webSocket   websocket连接对象
 *  @param pongPayload pong携带的数据NSData
 */
- (void)webSocket:(V5SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    V5Log(@">>>onPong");
}

#pragma mark ------ SDK UI Methods ------
/**
 *  创建会话界面
 *
 *  @return 会话ViewController
 */
+ (V5ChatViewController *)createChatViewController {
    V5ChatViewController *chatViewController = [[V5ChatViewController alloc] initWithNibName:nil
                                                                                      bundle:nil];
    chatViewController.title = V5LocalStr(@"v5_chat_title", @"V5客服");
    chatViewController.allowSound = NO;
    chatViewController.soundID = 1007;
    chatViewController.view.backgroundColor = ChatTableViewBG;
    return chatViewController;
}

#pragma mark - SDK Message Interface

/**
 *  发送字符串消息
 *
 *  @param message JSON格式字符串(NSString)
 */
- (void)sendMessageString:(NSString *)message {
    [self.webSocket send:message];
    V5Log(@"[sendMessage>>>]:%@", message);
}

/**
 *  连接检查并重连
 */
- (void)checkConnect {
    V5Log(@"checkConnect -> reachable: %d", !kNetworkNotReachability);
    if (!self.isConnected && !kNetworkNotReachability) {// && [AFNetworkReachabilityManager sharedManager].reachable
        V5Log(@"*****");
        if (self.config.authorization) {
            [self startWebsocketWithDelegate:self];
        } else {
            [self doAccountAuth];
        }
    }
}

/**
 *  刷新消息(用于从后台或其他界面回到会话时主动刷新消息)
 */
- (void)refresh {
    V5Log(@"refresh");
    V5Log(@"*****");
    [self startWebsocketWithDelegate:self];
}

#pragma mark -  Send message

/**
 *  发送V5Message消息
 *
 *  @param message V5Message消息对象
 */
- (void)sendMessage:(V5Message *)message {
    [self sendMessage:message withResult:YES];
}

/**
 *  发送V5Message
 *
 *  @param message    V5Message消息对象
 *  @param callResult 是否回调结果
 */
- (void)sendMessage:(V5Message * _Nonnull)message withResult:(BOOL)callResult {
    if (!self.isConnected) {
        if (callResult) {
            if (self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
                message.state = MessageSendStatus_Failure;
                [self.messageDelegate sendMessageResult:message expcetion:Exception_NotConnected];
            }
        } else if (self.messageDelegate &&
            [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotConnected
                                                    desc:@"Not connected"];
        }
        return;
    }
    if (message) {
        message.state = MessageSendStatus_Sending;
        
        // 判断是否发送本地图片
        if (message.messageType == MessageType_Image) {
            if (![(V5ImageMessage *)message picUrl] && [(V5ImageMessage *)message image]) {
                // 发送本地图片消息
                if ([(V5ImageMessage *)message isUpload]) {
                    // 已上传
                    V5Log(@"图片地址为空");
                    return;
                } else {
                    // 未上传，上传图片
                    [self uploadMediaData:[(V5ImageMessage *)message getImageData] forMessage:message];
                    return;
                }
            }
        } else if (message.messageType == MessageType_Voice) {
            if (!((V5VoiceMessage *)message).url && ((V5VoiceMessage *)message).local_url) {
                if (((V5VoiceMessage *)message).isUpload) {
                    // 已上传
                    V5Log(@"语音地址为空");
                    return;
                } else {
                    // 未上传，上传语音
                    [self uploadMediaData:[(V5VoiceMessage *)message getVoiceData] forMessage:message];
                    return;
                }
            }
        }
        
        
        message.msgId = [[NSDate date] timeIntervalSince1970] * 1000; // 发送的消息ID用于排重
        [self sendMessageString:[message toJSONString]];
        
        // 消息发送结果回调
        if (self.webSocket.readyState == V5SR_OPEN) {
            message.state = MessageSendStatus_Arrived;
            if (V5DatabaseEnable) {
                [self.dbHelper insertMessage:message];
            }
            if (callResult && self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
                [self.messageDelegate sendMessageResult:message expcetion:Exception_No_Error];
            }
        } else {
            message.state = MessageSendStatus_Failure;
            if (callResult && self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
                [self.messageDelegate sendMessageResult:message
                                              expcetion:Exception_Message_SendFailed];
            }
        }
    }
}

/**
 *  发送文本消息
 *
 *  @param content 文本消息
 */
- (V5TextMessage *)sendTextMessageWithContent:(NSString *)content {
    V5TextMessage *textMessage = [V5MessageManager obtainTextMessageWithContent:content];
    textMessage.state = MessageSendStatus_Sending;
    [self sendMessage:textMessage];
    return textMessage;
}

/**
 *  发送本地图片
 *
 *  @param image 图片UIImage
 */
- (V5ImageMessage *)sendImageMessageWithImage:(UIImage *)image {
    V5ImageMessage *imageMessage = [V5MessageManager obtainImageMessageWithImage:image];
    imageMessage.state = MessageSendStatus_Sending;
    [self uploadMediaData:[imageMessage getImageData] forMessage:imageMessage];
    return imageMessage;
}

#pragma mark - upload media

/**
 *  上传图片,先获取URL和auth然后上传图片
 *
 *  @param image   上传的UIImage
 *  @param message V5ImageMessage消息对象
 */
- (void)uploadMediaData:(NSData *)data forMessage:(V5Message *)message {
    //V5Log(@"uploadMediaData...:%@", [data description]);
    if (!data) {
        [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:@"Media upload service error:nil data"];
        return;
    }
    if (!self.config.authorization) { // 检查auth是否有效
        [self sendMessage:message exceptionOfStatus:Exception_WSAuth_Failed desc:@"Media upload service error:nil auth"];
        //[self doAccountAuth];
        return;
    }
    
    // 获取万象优图URL和Authorization
    NSString *serviceUrl = [[NSString alloc] initWithFormat:PIC_AUTH_URL, self.config.authorization];
    if (message.messageType == MessageType_Image) {
        serviceUrl = [[NSString alloc] initWithFormat:PIC_AUTH_URL, self.config.authorization];
    } else { // 其他媒体消息
        NSString *suffix = @"amr";
        NSString *type = @"voice";
        if (message.messageType == MessageType_Voice) { // 语音消息amr格式
            suffix = @"amr";
            type = @"voice";
        }
        serviceUrl = [[NSString alloc] initWithFormat:MEDIA_AUTH_URL, self.config.authorization, type, suffix];
    }
    V5Log(@"get_upload_URL:%@", serviceUrl);
    
    V5AFSecurityPolicy *securityPolicy = [V5AFSecurityPolicy defaultPolicy];
    securityPolicy.allowInvalidCertificates = YES;
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [V5AFJSONResponseSerializer serializer];
    manager.requestSerializer = [V5AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:self.config.authorization forHTTPHeaderField:@"Authorization"];
    [manager GET:serviceUrl parameters:nil success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
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
        V5Log(@"<<<WXYT-GetAuth>>>:%@", [dic description]);
        NSString *auth = [dic objectForKey:@"authorization"];
        NSString *url = [dic objectForKey:@"url"];
        id magicContext = [dic objectForKey:@"magic_content"];
        NSString *magic_content = [dic objectForKey:@"magic_content"];
        if (magicContext && [magicContext isKindOfClass:[NSDictionary class]]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:magicContext
                                                               options:JSON_OPTION
                                                                 error:nil];
            magic_content = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        NSString *fileid = [dic objectForKey:@"fileid"];
        if (auth && url) {
            self.wxytAuth = auth;
            self.wxytUrl = url;
            if (message.messageType == MessageType_Image) {
                [self postMultipartFormDataOfImageData:data
                                                  auth:auth
                                                   url:url
                                          magicContent:magic_content
                                       forImageMessage:(V5ImageMessage *)message];
            } else if (message.messageType == MessageType_Voice) {
                [self postMultipartFormData:data
                                       auth:auth
                                        url:url
                               magicContent:magic_content
                                     fileId:fileid
                                 forMessage:message];
            } else {
                [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:@"Media upload service error:unsupport type"];
            }
        } else {
            [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:@"Media upload service error:nil auth"];
        }
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"[WXYT-GetAuth] error:%@", [error description]);
        [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:@"Media upload service error:nil auth"];
    }];
    
    
    
//    NSDictionary *header = [NSDictionary dictionaryWithObjectsAndKeys:self.config.authorization, @"Authorization", nil];
//    [V5HttpExecutor getDataWithUrl:picServiceUrl httpHeader:header callbackBlock:^(NSString *result) {
//        if (result) {
//            V5Log(@"<<<PicServiceResult>>>:%@", result);
//            NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
//            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
//                                                                options:0
//                                                                  error:nil];
//            NSString *auth = [dic objectForKey:@"authorization"];
//            NSString *url = [dic objectForKey:@"url"];
//            if (auth && url) {
//                self.wxytAuth = auth;
//                self.wxytUrl = url;
//                [self postMultipartFormDataOfImage:image forImageMessage:message];
//            } else {
//                if (self.messageDelegate &&
//                    [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
//                    message.state = MessageSendStatus_Failure;
//                    [self.messageDelegate sendMessageResult:message expcetion:Exception_Image_UploadFailed];
//                } else if (self.messageDelegate &&
//                    [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
//                    [self.messageDelegate receiveExceptionStatus:Exception_Image_UploadFailed
//                                                            desc:@"Image upload service error:nil auth"];
//                }
//            }
//        } else {
//            if (self.messageDelegate &&
//                [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
//                message.state = MessageSendStatus_Failure;
//                [self.messageDelegate sendMessageResult:message expcetion:Exception_Image_UploadFailed];
//            } else if (self.messageDelegate &&
//                [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
//                [self.messageDelegate receiveExceptionStatus:Exception_Image_UploadFailed
//                                                        desc:@"Image upload service error:nil result"];
//            }
//        }
//    }];
}

/**
 *  上传到万象优图
 *
 *  @param image   上传到图片
 *  @param message 消息对象
 */
- (void)postMultipartFormDataOfImageData:(NSData *)data
                                    auth:auth
                                     url:url
                            magicContent:magic_content
                         forImageMessage:(V5ImageMessage *)message {
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // AFHTTPRequestOperation *operation = 
    [manager POST:url parameters:nil constructingBodyWithBlock:^(id<V5AFMultipartFormData> formData) {
        // 添加formData-magiccontext
        if (![V5Util isEmptyString:magic_content]) {
            [formData appendPartWithFormData:[magic_content dataUsingEncoding:NSUTF8StringEncoding]
                                        name:@"magiccontext"];
        }
        
        // 添加formData-filecontent
        NSDate *date = [NSDate date];
        NSString *filename = [NSString stringWithFormat:@"v5kf_ios%lf.png",[date timeIntervalSince1970]];
        [formData appendPartWithFileData:data name:@"filecontent" fileName:filename mimeType:@"image/jpeg"];
    } success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
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
        
        NSInteger code = [[dic objectForKey:@"code"] integerValue];
        NSDictionary *data = [dic objectForKey:@"data"];
        if (data && code == 0) {
            message.picUrl = [data objectForKey:@"download_url"];
            message.isUpload = YES;
            [self sendMessage:message];
        } else {
            [self sendMessage:message exceptionOfStatus:Exception_Image_UploadFailed desc:[NSString stringWithFormat:@"Image upload service error:%@", [dic objectForKey:@"message"]]];
        }
        
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"post image failed:%@", [error description]);
        [self sendMessage:message exceptionOfStatus:Exception_Image_UploadFailed desc:[NSString stringWithFormat:@"Image upload service error:%@", [error description]]];
    }];
}

/**
 *  上传到万象优图
 *
 *  @param image   上传到图片(一次只能传一张)
 *  @param message 消息对象
 */
- (void)postMultipartFormData:(NSData *)mediaData
                         auth:(NSString *)auth
                          url:(NSString *)url
                 magicContent:(NSString *)magic_content
                       fileId:(NSString *)fileid
                   forMessage:(V5Message *)message {
    V5AFHTTPRequestOperationManager *manager = [V5AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"web.file.myqcloud.com" forHTTPHeaderField:@"Host"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];
    
    V5Log(@"<<<WXYT-postMultipartFormData>>>:%@ auth:%@", url, auth);
    [manager POST:url parameters:nil constructingBodyWithBlock:^(id<V5AFMultipartFormData> formData) {
        // 添加formData
        [formData appendPartWithFormData:[@"upload" dataUsingEncoding:NSUTF8StringEncoding] name:@"op"];
        
        NSDate *date = [NSDate date];
        if (message.messageType == MessageType_Image) {
            NSString *filename = [NSString stringWithFormat:@"v5kf_ios%lf.jpg", [date timeIntervalSince1970]];
            [formData appendPartWithFileData:mediaData name:@"filecontent" fileName:filename mimeType:@"image/jpeg"];
        } else if (message.messageType == MessageType_Voice) {
            NSString *filename = [NSString stringWithFormat:@"v5kf_ios%lf.amr", [date timeIntervalSince1970]];
            [formData appendPartWithFileData:mediaData name:@"filecontent" fileName:filename mimeType:@"audio/amr"];
        }
        
        V5Log(@"Data content length>>>%lu", (unsigned long)mediaData.length);
        //        NSString *sha = [V5Util shaOfData:data]; // [修改]sha校验
        //        [formData appendPartWithFormData:[sha dataUsingEncoding:NSUTF8StringEncoding] name:@"sha"];
    } success:^(V5AFHTTPRequestOperation *operation, id responseObject) {
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
        V5Log(@"<<<WXYT-postMultipartFormData>>>success:%@", [dic description]);
        NSInteger code = [[dic objectForKey:@"code"] integerValue];
        NSDictionary *data = [dic objectForKey:@"data"];
        NSString *accessUrl = [data objectForKey:@"access_url"];
        if (data && code == 0) {
            if (message.messageType == MessageType_Image) {
                ((V5ImageMessage *)message).picUrl = accessUrl;
                ((V5ImageMessage *)message).isUpload = YES;
            } else if (message.messageType == MessageType_Voice) {
                ((V5VoiceMessage *)message).url = accessUrl;
                ((V5VoiceMessage *)message).isUpload = YES;
                
                // 删除临时语音文件
                [V5Util deleteFileWithPath:[((V5VoiceMessage *)message).local_url stringByReplacingOccurrencesOfString:@".wav" withString:@".amr"]];
                // 替换语音文件名
                NSString *newPath = [V5Util getVoicePathByFileName:[V5Util md5:accessUrl] ofType:@"wav"];
                BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:((V5VoiceMessage *)message).local_url
                                                                         toPath:newPath
                                                                          error:nil];
                if (isSuccess) {
                    ((V5VoiceMessage *)message).local_url = newPath;
                }
            }
            // 直接发送
            [self sendMessage:message];
            
        } else {
            [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:[NSString stringWithFormat:@"Media upload service error:%@", [dic objectForKey:@"message"]]];
            
        }
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        V5Log(@"post MultipartFormData failed:%@ reason:%@", [error description], [operation.responseObject description]);
        [self sendMessage:message exceptionOfStatus:Exception_Message_SendFailed desc:[NSString stringWithFormat:@"Media upload service error:%@", [error description]]];
    }];
}

#pragma mark -

/**
 *  获取当前回话的V5Message消息，获取结果通过getMessagesResult:offset:size:finish:expcetion:
 *  回调返回，参数offset和size均为0时为查询会话全部消息
 *
 *  @param offset 请求消息的起始位置
 *  @param size   最多返回消息数
 */
- (void)getStatus {
    if (!self.isConnected) {
        if (self.messageDelegate &&
            [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotConnected
                                                    desc:@"Not connected"];
        }
        return;
    }
    
    NSDictionary *requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"session", @"o_type",
                                 @"get_status", @"o_method", nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestData
                                                       options:JSON_OPTION
                                                         error:nil];
    if ([jsonData length] > 0) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        [self sendMessageString:jsonString];
    }
}

/**
 *  获取当前回话的V5Message消息，获取结果通过getMessagesResult:offset:size:finish:expcetion:
 *  回调返回，参数offset和size均为0时为查询会话全部消息
 *
 *  @param offset 请求消息的起始位置
 *  @param size   最多返回消息数
 */
- (void)getCurrentMessagesWithOffset:(NSInteger)offset messageSize:(NSInteger)size {
    if (!self.isConnected) {
        if (self.messageDelegate &&
            [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotConnected
                                                    desc:@"Not connected"];
        }
        return;
    }
    
    NSDictionary *requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"session", @"o_type",
                                 @"get_messages", @"o_method",
                                 @(size), @"size",
                                 @(offset), @"offset", nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestData
                                                       options:JSON_OPTION
                                                         error:nil];
    if ([jsonData length] > 0) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        [self sendMessageString:jsonString];
    }
}

/**
 *  获取会话消息,获取结果通过代理getMessagesResult:offset:size:finish:expcetion:返回
 *  参数offset和size均为0时为查询会话全部消息
 *
 *  @param offset 请求消息的起始位置
 *  @param size   最多返回消息数
 */
- (void)getMessagesWithOffset:(NSInteger)offset messageSize:(NSInteger)size {
    // block + GCD 异步执行
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSMutableArray *messagesArray = [NSMutableArray array];
        BOOL finish = [self.dbHelper queryMessages:messagesArray offset:offset size:size]; // 按照ID从大到小排队
        
        // 操作完成回调到UI主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.messageDelegate &&
                [self.messageDelegate respondsToSelector:@selector(getMessagesResult:offset:size:finish:expcetion:)]) {
                [self.messageDelegate getMessagesResult:messagesArray offset:offset size:[messagesArray count] finish:finish expcetion:Exception_No_Error];
            }
//            if (offset == 0 && [msgs count] == 0) { // 没有消息记录显示开场白
//                if (self.openMode == ClientOpenModeDefault) {
//                    NSString *startMessage = V5LocalStr(@"start_message", @"您好，我是智能客服机器人小五，请问有什么能帮到您的吗？");
//                    V5TextMessage *textMsg = [V5MessageManager obtainTextMessageWithContent:startMessage];
//                    textMsg.direction = MessageDir_FromRobot;
//                    textMsg.msgId = [[NSDate date] timeIntervalSince1970] * 1000;
//                    if (V5DatabaseEnable) {
//                        [self.dbHelper insertMessage:textMsg force:YES];
//                    }
//                    // 接收V5Message消息回调
//                    if (self.messageDelegate) {
//                        [self.messageDelegate receiveV5Message:textMsg];
//                    }
//                }
//            }
        });
    });
}

/**
 *  清空当前登录账号的所有消息缓存
 */
- (void)clearMessagesCache {
    // block + GCD 异步执行
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self.dbHelper clear];
    });
}

/**
 *  清空语音图片等媒体缓存
 */
+ (void)clearMediaCache {
    // 清空语音缓存
    [V5Util deleteFileWithPath:VOICE_CACHE_PATH];
    // 清空图片缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)sendMessage:(V5Message *)message exceptionOfStatus:(KV5ExceptionStatus)status desc:(NSString *)description {
    message.state = MessageSendStatus_Failure;
    if (self.messageDelegate &&
        [self.messageDelegate respondsToSelector:@selector(sendMessageResult:expcetion:)]) {
        [self.messageDelegate sendMessageResult:message expcetion:status];
    }
    if (status != Exception_Message_SendFailed && self.messageDelegate &&
               [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
        [self.messageDelegate receiveExceptionStatus:status
                                                desc:description];
    }
}

#pragma mark -

/**
 *  找指定客服
 *
 *  @param gid 客服组ID，无分组则为0
 *  @param wid 客服ID
 */
- (void)humanServiceOfGroupId:(NSInteger)gid workerId:(NSInteger)wid {
    NSString *argv = [NSString stringWithFormat:@"%ld %ld", (long)gid, (long)wid];
    V5ControlMessage *cmsg = [V5MessageManager obtainControlMessageWithCode:1 argc:2 argv:argv];
    [[V5ClientAgent shareClient] sendMessage:cmsg];
}

/**
 *  转人工客服
 */
- (V5ControlMessage *)switchToArtificialService {
    if (!self.isConnected) {
        if (self.messageDelegate &&
            [self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotConnected
                                                    desc:@"Not connected"];
        }
        return nil;
    }
    
    V5ControlMessage *controlMessage = [V5MessageManager obtainControlMessageWithCode:1 argc:0 argv:nil];
    [self sendMessage:controlMessage];
    return controlMessage;
}

/**
 *  发上线消息
 */
- (void)shouldClientOnline {
    // 上线
    V5ControlMessage *controlMessage = [V5MessageManager obtainControlMessageWithCode:100 argc:0 argv:nil];
    [self sendMessage:controlMessage withResult:NO];
}

/**
 *  发下线消息
 */
- (void)shouldClientOffline {
    // 下线
    V5ControlMessage *controlMessage = [V5MessageManager obtainControlMessageWithCode:101 argc:0 argv:nil];
    [self sendMessage:controlMessage withResult:NO];
}

/**
 *  应用进入后台
 */
- (void)onApplicationDidEnterBackground {
    if (!self.messageDelegate) {
        return;
    }
    V5Log(@"[onApplicationDidEnterBackground]");
    if (!self.isConnected) {
        if ([self.messageDelegate respondsToSelector:@selector(receiveExceptionStatus:desc:)]) {
            [self.messageDelegate receiveExceptionStatus:Exception_NotConnected
                                                    desc:@"Not connected"];
        }
        return;
    }
    
    //进入后台，关闭websocket(系统将强制关闭socket)
    [[V5AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [self shouldClientOffline];
    if (self.webSocket) {
        [self.webSocket close];
        self.connected = NO;
        self.webSocket.delegate = nil;
        self.webSocket = nil;
    }
}

- (void)onApplicationWillEnterForeground {
    if (!self.messageDelegate) {
        return;
    }
    V5Log(@"[onApplicationWillEnterForeground]");
    [self refresh];
    //[self shouldClientOnline];
}

//- (void)onViewDidDisappear {
//	V5Log(@"[onViewDidDisappear]");
//    [self shouldClientOffline];
//}
//
//- (void)onViewWillAppear {
//    V5Log(@"[onViewWillAppear]");
//    [self shouldClientOnline];
//}

- (void)sendPrologue:(NSString *)prologue {
    V5TextMessage *textMsg = [V5MessageManager obtainTextMessageWithContent:prologue];
    textMsg.direction = MessageDir_FromRobot;
    textMsg.msgId = [[NSDate date] timeIntervalSince1970];
    //        if (V5DatabaseEnable) {
    //            [self.dbHelper insertMessage:textMsg force:YES];
    //        }
    // 接收V5Message消息回调
    if (self.messageDelegate) {
        [self.messageDelegate receiveV5Message:textMsg];
    }
}

/**
 *  获得开场消息
 *
 *  @param mode  KV5ClientOpenMode 开场白模式
 *  @param patam 参数可为nil,当mode为ClientOpenModeCommand时不为nil
 */
- (void)getOpeningMessageOfMode:(KV5ClientOpenMode)mode withParam:(nullable NSString *)param {
    if (mode == ClientOpenModeDefault) {
        if (param) {
            [self sendPrologue:param];
        } else {
            [self getSiteInfo];
        }
        
    } else if (mode == ClientOpenModeQuestion && param) {
        V5TextMessage *openQuestion = [V5MessageManager obtainTextMessageWithContent:param];
        openQuestion.msgId = [[NSDate date] timeIntervalSince1970];
        [self sendMessageString:[openQuestion toJSONString]];
    } else if (mode == ClientOpenModeAutoHuman) {
        // 自动转人工客服
        [self switchToArtificialService];
    }
}


@end
