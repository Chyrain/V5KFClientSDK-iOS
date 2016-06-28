//
//  V5Message.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/2.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5Message.h"
#import "V5MessageManager.h"
#import "V5TextMessage.h"
#import "V5ImageMessage.h"
#import "V5LocationMessage.h"
#import "V5UndefinedMessage.h"
#import "V5Macros.h"

@interface V5Message() {
    // 类内部私有全局变量
}
@end


@implementation V5Message

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionStart = 0;
        _state = MessageSendStatus_Unknown;
        _direction = MessageDir_ToWorker;
        _createTime = time(NULL);
    }
    return self;
}

/**
 *  使用JSON字符串初始化消息对象
 *
 *  @param jsonString JSON格式字符串
 *
 *  @return 消息对象实例
 */
- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [self init];
    if (self) {
        id msgId = [data objectForKey:@"message_id"];
        if (msgId && ![msgId isEqual:[NSNull null]]) {
            _messageId = [msgId longLongValue];
        }
        msgId = [data objectForKey:@"msg_id"];
        if (msgId && ![msgId isEqual:[NSNull null]]) {
            _msgId = [msgId longLongValue];
        }
        msgId = [data objectForKey:@"w_id"];
        if (msgId && ![msgId isEqual:[NSNull null]]) {
            _wId = [msgId longLongValue];
        }
        id msgType = [data objectForKey:@"message_type"];
        if (msgType && ![msgType isEqual:[NSNull null]]) {
            _messageType = [msgType integerValue];
        }
        id dir = [data objectForKey:@"direction"];
        if (dir && ![dir isEqual:[NSNull null]]) {
            _direction = [dir integerValue];
        }
        id cTime = [data objectForKey:@"create_time"];
        if (cTime && ![cTime isEqual:[NSNull null]]) {
            _createTime = [cTime integerValue];
        }
        id hit = [data objectForKey:@"hit"];
        if (hit && ![hit isEqual:[NSNull null]]) {
            _hit = [hit integerValue];
        }
        id candidate = [data objectForKey:@"candidate"];
        if (candidate && ![candidate isEqual:[NSNull null]]) {
            if (!_candidate) {
                _candidate = [NSMutableArray new];
            }
            for (NSDictionary *item in candidate) {
                V5Message *message = [V5MessageManager receiveMessageFromJSON:item];
                [_candidate addObject:message];
            }
        }
    }
    return self;
}


/**
 *  获得默认消息内容字符串
 *
 *  @return 消息内容字符串
 */
- (NSString *)getDefaultContent {
    switch (self.messageType) {
        case MessageType_Text:
            return [(V5TextMessage *)self content];
        case MessageType_Location:
            return V5LocalStr(@"v5_defmsg_location", @"[位置]");
        case MessageType_Image:
            return V5LocalStr(@"v5_defmsg_image", @"[图片]");
        case MessageType_Link:
            return V5LocalStr(@"v5_defmsg_link", @"[链接]");
        case MessageType_Event:
            return V5LocalStr(@"v5_defmsg_event", @"[事件]");
        case MessageType_Voice:
            return V5LocalStr(@"v5_defmsg_voice", @"[语音]");
        case MessageType_Video:
            return V5LocalStr(@"v5_defmsg_video", @"[视频]");
        case MessageType_ShortVideo:
            return V5LocalStr(@"v5_defmsg_shortVideo", @"[短视频]");
        case MessageType_Articles:
            return V5LocalStr(@"v5_defmsg_articles", @"[图文]");
        case MessageType_Music:
            return V5LocalStr(@"v5_defmsg_music", @"[音乐]");
        case MessageType_Note:
            return V5LocalStr(@"v5_defmsg_note", @"[留言]");
        case MessageType_Comment:
            return V5LocalStr(@"v5_defmsg_comment", @"[评价]");
        case MessageType_Control: {
            if ([(V5ControlMessage *)self code] == 1 || [(V5ControlMessage *)self code] == 3) {
                return V5LocalStr(@"v5_defmsg_worker", @"[转人工客服]");
            }
            return V5LocalStr(@"v5_defmsg_control", @"[控制消息]");
        }
        case MessageType_WXCS: {
            return V5LocalStr(@"v5_defmsg_worker", @"[转人工客服]");
        }
        default:
            break;
    }
    return [NSString stringWithFormat:V5LocalStr(@"v5_defmsg_unknown", @"[不支持类型消息(%d)]"), self.messageType];
}


/**
 *  添加V5Message属性到字典对象
 *
 *  @param JSONObj NSMutableDictionary字典对象
 */
- (void)addPropertyToJSONObject:(NSMutableDictionary *)JSONObj {
    if (nil != JSONObj) {
        [JSONObj setObject:@"message" forKey:@"o_type"];
        [JSONObj setObject:@(self.messageType) forKey:@"message_type"];
        [JSONObj setObject:@(self.direction) forKey:@"direction"];
        if (self.msgId != 0) {
            [JSONObj setObject:@(self.msgId) forKey:@"msg_id"];
        }
        if (self.wId != 0) {
            [JSONObj setObject:@(self.wId) forKey:@"w_id"];
        }
//        if (self.createTime != 0) {
//            [JSONObj setObject:@(self.createTime) forKey:@"create_time"];
//        }
        if (self.customContent) {
            NSMutableArray *cstmContentArray = [NSMutableArray arrayWithCapacity:self.customContent.count];
            for (NSString *key in self.customContent.allKeys) {
                [cstmContentArray addObject:@{@"key" : key, @"val" : self.customContent[key]}];
            }
            
            [JSONObj setObject:cstmContentArray forKey:@"custom_content"];
        }
        if (self.candidate) {
            NSMutableArray *candidateArray = [NSMutableArray arrayWithCapacity:1];
            for (V5Message *msg in self.candidate) {
                NSData *data = [[msg toJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                [candidateArray addObject:dic];
            }
            [JSONObj setObject:candidateArray forKey:@"candidate"];
        }
    }
}


/**
 *  转JSON格式字符串
 *
 *  @return JSON字符串
 */
- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:4];
    [self addPropertyToJSONObject:mutableDic];
    [mutableDic setObject:@(self.messageId) forKey:@"message_id"];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableDic
                                    options:NSJSONWritingPrettyPrinted
                                      error:&error];
    if ([jsonData length] > 0 && error == nil) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        return jsonString;
    } else {
        return nil;
    }
}



@end
