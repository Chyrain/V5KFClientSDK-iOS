//
//  V5TextMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/2.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5TextMessage.h"

@implementation V5TextMessage


- (instancetype)initWithContent:(NSString *)content {
    self = [self init];
    if (self) {
        self.content = content;
        self.messageType = MessageType_Text;
    }
    
    return self;
}

/**
 *  使用JSON字符串初始化消息对象
 *
 *  @param data JSON字典对象
 *
 *  @return 文本消息对象实例
 */
- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        id content = [data objectForKey:@"content"];
        if (content && ![content isEqual:[NSNull null]]) {
            _content = content;
        }
    }
    return self;
}


/**
 *  转JSON格式字符串
 *
 *  @return JSON字符串
 */
- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    if (self.content) {
        [mutableDic setObject:self.content forKey:@"content"]; // 加入本类属性
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableDic
                                                       options:JSON_OPTION
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
